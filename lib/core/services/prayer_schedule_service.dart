import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:home_widget/home_widget.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../storage/local_storage_service.dart';
import '../../features/prayer_times/data/services/prayer_service.dart';
import '../../features/prayer_times/data/services/prayer_settings_provider.dart';
import '../../features/prayer_times/domain/entities/prayer_settings.dart';
import '../../features/prayer_times/domain/entities/prayer_time_model.dart';

/// Service that manages Android/iOS home widget updates for prayer times.
///
/// Handles:
/// - Dynamic next prayer recalculation
/// - Isha → Fajr day transition
/// - Prevents negative countdown values
/// - Optimized periodic updates (every 60 seconds)
class PrayerScheduleService {
  PrayerScheduleService(
    this._storage,
    this._prayerService,
    this._settingsProvider,
  );

  final LocalStorageService _storage;
  final PrayerService _prayerService;
  final PrayerSettingsProvider _settingsProvider;

  Timer? _widgetTimer;

  static const androidProvider = 'PrayerWidgetProvider';
  static const iOSWidgetName = 'PrayerWidget';

  // Widget data keys
  static const keyNextPrayer = 'widget_next_prayer';
  static const keyNextLabel = 'widget_next_label';
  static const keyNextPrayerTime = 'widget_next_time';
  static const keyNextPrayerEpoch = 'widget_next_epoch';
  static const keyRemaining = 'widget_remaining';
  static const keyDateLine = 'widget_date';
  static const keyHijriLine = 'widget_hijri';
  static const keyLocation = 'widget_location';

  /// Starts the periodic widget update scheduler.
  ///
  /// Updates every 60 seconds to balance freshness with battery usage.
  /// Automatically recalculates next prayer when current prayer time passes.
  void startScheduler({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) {
    stopScheduler();
    updateWidget(
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
    );
    _widgetTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      updateWidget(
        latitude: latitude,
        longitude: longitude,
        locationLabel: locationLabel,
      );
    });
  }

  /// Stops the periodic widget update scheduler.
  void stopScheduler() {
    _widgetTimer?.cancel();
    _widgetTimer = null;
  }

  /// Calculates widget data for the given coordinates and settings.
  ///
  /// Returns a [PrayerTimeModel] with all data needed for widget display,
  /// or null if no next prayer can be determined.
  PrayerTimeModel? calculateWidgetData({
    required double latitude,
    required double longitude,
    required PrayerSettings settings,
    required bool use24HourFormat,
    required String locationLabel,
  }) {
    final now = DateTime.now();
    final coordinates = Coordinates(latitude, longitude);

    // Calculate today's prayer times
    final todayTimes = _prayerService.calculatePrayerTimes(
      coordinates: coordinates,
      date: now,
      settings: settings,
    );

    // Find next prayer dynamically
    final nextPrayer = _findNextPrayer(todayTimes, now, coordinates, settings);
    final nextTime = _getNextPrayerTime(todayTimes, nextPrayer, coordinates, settings);

    if (nextTime == null) return null;

    // Calculate remaining time (prevent negative values)
    final remaining = nextTime.isAfter(now)
        ? nextTime.difference(now)
        : Duration.zero;

    // Format data for widget
    final timeFormat = DateFormat(use24HourFormat ? 'HH:mm' : 'h:mm a');
    final timeText = timeFormat.format(nextTime);

    final gregorianDate = DateFormat.yMMMMEEEEd().format(now);
    final hijri = HijriCalendar.fromDate(now);
    final hijriLine = hijri.toFormat('dd MMMM yyyy');

    return PrayerTimeModel(
      nextPrayerName: _prayerName(nextPrayer),
      nextPrayerLabel: 'prayer_times.next_prayer'.tr(),
      remainingDuration: remaining,
      prayerTimeFormatted: timeText,
      prayerTimeEpoch: nextTime.millisecondsSinceEpoch,
      gregorianDate: gregorianDate,
      hijriDate: hijriLine,
      locationLabel: locationLabel,
    );
  }

  /// Performs a single widget update with dynamic prayer recalculation.
  Future<void> updateWidget({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final settings = _settingsProvider.load();
    final now = DateTime.now();
    final coordinates = Coordinates(latitude, longitude);

    // Calculate today's prayer times
    final todayTimes = _prayerService.calculatePrayerTimes(
      coordinates: coordinates,
      date: now,
      settings: settings,
    );

    // Find next prayer dynamically
    final nextPrayer = _findNextPrayer(todayTimes, now, coordinates, settings);
    final nextTime = _getNextPrayerTime(todayTimes, nextPrayer, coordinates, settings);

    if (nextTime == null) return;

    // Calculate remaining time (prevent negative values)
    final remaining = nextTime.isAfter(now)
        ? nextTime.difference(now)
        : Duration.zero;

    // Format data for widget
    final use24h = _storage.getUse24HourFormat();
    final timeFormat = DateFormat(use24h ? 'HH:mm' : 'h:mm a');
    final timeText = timeFormat.format(nextTime);

    final gregorianDate = DateFormat.yMMMMEEEEd().format(now);
    final hijri = HijriCalendar.fromDate(now);
    final hijriLine = hijri.toFormat('dd MMMM yyyy');

    // Save widget data
    await HomeWidget.saveWidgetData<String>(
      keyNextPrayer,
      _prayerLabel(nextPrayer),
    );
    await HomeWidget.saveWidgetData<String>(
      keyNextLabel,
      'prayer_times.next_prayer'.tr(),
    );
    await HomeWidget.saveWidgetData<String>(keyNextPrayerTime, timeText);
    await HomeWidget.saveWidgetData<String>(
      keyNextPrayerEpoch,
      nextTime.millisecondsSinceEpoch.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      keyRemaining,
      _formatCountdown(remaining),
    );
    await HomeWidget.saveWidgetData<String>(keyDateLine, gregorianDate);
    await HomeWidget.saveWidgetData<String>(keyHijriLine, hijriLine);
    await HomeWidget.saveWidgetData<String>(keyLocation, locationLabel);

    // Trigger widget update
    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iOSWidgetName,
    );
  }

  /// Finds the next prayer dynamically based on current time.
  ///
  /// Handles the Isha → Fajr transition by checking tomorrow's Fajr
  /// when all today's prayers have passed.
  Prayer _findNextPrayer(
    PrayerTimes todayTimes,
    DateTime now,
    Coordinates coordinates,
    PrayerSettings settings,
  ) {
    final prayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in prayers) {
      final time = todayTimes.timeForPrayer(prayer);
      if (time != null && time.isAfter(now)) {
        return prayer;
      }
    }

    // All today's prayers passed → next is tomorrow's Fajr
    return Prayer.fajr;
  }

  /// Gets the actual DateTime for the next prayer.
  ///
  /// If next prayer is tomorrow's Fajr, calculates tomorrow's prayer times.
  DateTime? _getNextPrayerTime(
    PrayerTimes todayTimes,
    Prayer nextPrayer,
    Coordinates coordinates,
    PrayerSettings settings,
  ) {
    final now = DateTime.now();
    var time = todayTimes.timeForPrayer(nextPrayer);

    // If time is in the past or null, it means we need tomorrow's Fajr
    if (time == null || time.isBefore(now)) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = _prayerService.calculatePrayerTimes(
        coordinates: coordinates,
        date: tomorrow,
        settings: settings,
      );
      time = tomorrowTimes.fajr;
    }

    return time;
  }

  /// Formats countdown duration as HH:MM:SS.
  String _formatCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Returns English prayer name for localization.
  String _prayerName(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 'Fajr',
      Prayer.sunrise => 'Sunrise',
      Prayer.dhuhr => 'Dhuhr',
      Prayer.asr => 'Asr',
      Prayer.maghrib => 'Maghrib',
      Prayer.isha => 'Isha',
      _ => 'Fajr',
    };
  }

  /// Returns localized prayer label.
  String _prayerLabel(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 'prayer_times.prayers.fajr'.tr(),
      Prayer.sunrise => 'prayer_times.prayers.sunrise'.tr(),
      Prayer.dhuhr => 'prayer_times.prayers.dhuhr'.tr(),
      Prayer.asr => 'prayer_times.prayers.asr'.tr(),
      Prayer.maghrib => 'prayer_times.prayers.maghrib'.tr(),
      Prayer.isha => 'prayer_times.prayers.isha'.tr(),
      _ => 'prayer_times.prayers.fajr'.tr(),
    };
  }
}
