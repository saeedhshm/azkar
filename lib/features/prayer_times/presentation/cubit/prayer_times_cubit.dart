import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../data/models/city_entry.dart';
import '../../data/services/city_database_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/network_service.dart';
import '../../data/services/prayer_service.dart';
import '../../data/services/prayer_settings_provider.dart';
import '../../../../core/services/prayer_schedule_service.dart';
import '../../../../core/utils/coordinate_validator.dart';
import '../../data/services/widget_update_service.dart';
import '../../domain/entities/prayer_settings.dart';
import 'prayer_times_state.dart';

/// Pure decision logic for the in-app prayer ticker.
///
/// Extracted so the reload policy can be verified without a wall clock.
class PrayerTickerPolicy {
  const PrayerTickerPolicy._();

  /// Whether prayer data must be recalculated at [now].
  ///
  /// Reloads are required only when the next prayer has been reached or when
  /// the calendar date actually changed since the loaded schedule. Comparing
  /// `now.day` with `nextPrayerTime.day` is intentionally avoided: after Isha
  /// the next prayer is tomorrow's Fajr, so that comparison would stay true
  /// for the entire post-Isha window and reload once per second.
  static bool shouldReload({
    required DateTime now,
    required DateTime? nextPrayerTime,
    required DateTime? loadedDay,
  }) {
    if (nextPrayerTime == null || !nextPrayerTime.isAfter(now)) {
      return true;
    }
    if (loadedDay == null) {
      return true;
    }
    return !isSameDay(now, loadedDay);
  }

  /// Whether two instants fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Outcome of a manual location submission.
enum ManualLocationResult { success, invalidLatitude, invalidLongitude }

/// Cubit managing prayer times state and widget updates.
///
/// Responsibilities:
/// - Load and calculate prayer times
/// - Manage location (GPS or manual)
/// - Update home widget via WidgetUpdateService
/// - Schedule notifications
/// - Maintain 1-second ticker for UI countdown
///
/// Widget updates are handled separately by Android's AlarmManager
/// via WidgetUpdateReceiver for background reliability.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({
    required PrayerService prayerService,
    required LocationService locationService,
    required PrayerSettingsProvider settingsProvider,
    required NetworkService networkService,
    required CityDatabaseService cityDatabaseService,
    required NotificationService notificationService,
    required PrayerScheduleService prayerScheduleService,
    required WidgetUpdateService widgetUpdateService,
  }) : _prayerService = prayerService,
       _locationService = locationService,
       _settingsProvider = settingsProvider,
       _networkService = networkService,
       _cityDatabaseService = cityDatabaseService,
       _notificationService = notificationService,
       _prayerScheduleService = prayerScheduleService,
       _widgetUpdateService = widgetUpdateService,
       super(PrayerTimesState(settings: PrayerSettings.defaults()));

  final PrayerService _prayerService;
  final LocationService _locationService;
  final PrayerSettingsProvider _settingsProvider;
  final NetworkService _networkService;
  final CityDatabaseService _cityDatabaseService;
  final NotificationService _notificationService;
  final PrayerScheduleService _prayerScheduleService;
  final WidgetUpdateService _widgetUpdateService;

  Timer? _ticker;
  bool _isReloading = false;
  bool _hasLoadedOnce = false;

  /// Tracks the calendar day the currently loaded schedule belongs to.
  ///
  /// Used to detect real date rollovers instead of comparing `now.day` with
  /// the next prayer's day, which stays false for the whole post-Isha window
  /// because the next prayer is tomorrow's Fajr.
  DateTime? _loadedDay;

  /// Method channel for communicating with Android native code
  static const _platform = MethodChannel('com.example.azkar/widget');

  /// Loads prayer times and initializes all services.
  ///
  /// This is the main entry point called when the app starts or
  /// when the user refreshes prayer times.
  Future<void> load() async {
    _hasLoadedOnce = true;
    emit(state.copyWith(status: PrayerTimesStatus.loading));

    final settings = _settingsProvider.load();
    final cachedLocation = _settingsProvider.loadCachedLocation();
    final isOnline = await _networkService.isOnline();
    if (isOnline) {
      unawaited(_cityDatabaseService.ensureDownloaded());
    }

    if (settings.useDeviceLocation) {
      final result = await _locationService.getCurrentLocation();

      if (result.status == LocationStatus.permissionDenied) {
        if (settings.manualLatitude != null &&
            settings.manualLongitude != null) {
          await _loadForCoordinates(
            settings: settings.copyWith(useDeviceLocation: false),
            latitude: settings.manualLatitude!,
            longitude: settings.manualLongitude!,
            locationLabel: settings.manualLabel,
          );
          return;
        }
        if (cachedLocation != null) {
          await _loadForCoordinates(
            settings: settings,
            latitude: cachedLocation.latitude,
            longitude: cachedLocation.longitude,
            locationLabel: cachedLocation.label,
          );
          return;
        }
        emit(
          state.copyWith(
            status: PrayerTimesStatus.permissionDenied,
            settings: settings,
          ),
        );
        return;
      }

      if (result.status == LocationStatus.permissionDeniedForever) {
        if (settings.manualLatitude != null &&
            settings.manualLongitude != null) {
          await _loadForCoordinates(
            settings: settings.copyWith(useDeviceLocation: false),
            latitude: settings.manualLatitude!,
            longitude: settings.manualLongitude!,
            locationLabel: settings.manualLabel,
          );
          return;
        }
        if (cachedLocation != null) {
          await _loadForCoordinates(
            settings: settings,
            latitude: cachedLocation.latitude,
            longitude: cachedLocation.longitude,
            locationLabel: cachedLocation.label,
          );
          return;
        }
        emit(
          state.copyWith(
            status: PrayerTimesStatus.permissionDeniedForever,
            settings: settings,
          ),
        );
        return;
      }

      if (result.status == LocationStatus.serviceDisabled) {
        if (settings.manualLatitude != null &&
            settings.manualLongitude != null) {
          await _loadForCoordinates(
            settings: settings.copyWith(useDeviceLocation: false),
            latitude: settings.manualLatitude!,
            longitude: settings.manualLongitude!,
            locationLabel: settings.manualLabel,
          );
          return;
        }
        if (cachedLocation != null) {
          await _loadForCoordinates(
            settings: settings,
            latitude: cachedLocation.latitude,
            longitude: cachedLocation.longitude,
            locationLabel: cachedLocation.label,
          );
          return;
        }
        emit(
          state.copyWith(
            status: PrayerTimesStatus.serviceDisabled,
            settings: settings,
          ),
        );
        return;
      }

      final latitude = result.latitude;
      final longitude = result.longitude;

      if (latitude == null || longitude == null) {
        emit(
          state.copyWith(
            status: PrayerTimesStatus.failure,
            settings: settings,
            errorMessage: 'Missing coordinates',
          ),
        );
        return;
      }

      String? label;
      if (isOnline) {
        label = await _locationService.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        );
        if (label != null && label.trim().isNotEmpty) {
          await _settingsProvider.saveCachedLocation(
            latitude: latitude,
            longitude: longitude,
            label: label,
          );
        }
      }

      label ??= cachedLocation?.label;

      await _loadForCoordinates(
        settings: settings,
        latitude: latitude,
        longitude: longitude,
        locationLabel: label ?? settings.manualLabel ?? 'GPS',
      );
    } else if (settings.manualLatitude != null &&
        settings.manualLongitude != null) {
      await _loadForCoordinates(
        settings: settings,
        latitude: settings.manualLatitude!,
        longitude: settings.manualLongitude!,
        locationLabel: settings.manualLabel,
      );
    } else if (cachedLocation != null) {
      await _loadForCoordinates(
        settings: settings,
        latitude: cachedLocation.latitude,
        longitude: cachedLocation.longitude,
        locationLabel: cachedLocation.label,
      );
    } else {
      emit(
        state.copyWith(
          status: PrayerTimesStatus.permissionDenied,
          settings: settings,
        ),
      );
    }
  }

  /// Applies a manually entered location.
  ///
  /// Coordinates outside the valid geographic range are rejected so they are
  /// never persisted nor used for prayer calculations.
  Future<ManualLocationResult> setManualLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    if (!CoordinateValidator.isValidLatitude(latitude)) {
      return ManualLocationResult.invalidLatitude;
    }
    if (!CoordinateValidator.isValidLongitude(longitude)) {
      return ManualLocationResult.invalidLongitude;
    }

    await _settingsProvider.saveManualLocation(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );

    final settings = _settingsProvider.load().copyWith(
      useDeviceLocation: false,
      manualLatitude: latitude,
      manualLongitude: longitude,
      manualLabel: label,
    );

    await _settingsProvider.save(settings);

    await _loadForCoordinates(
      settings: settings,
      latitude: latitude,
      longitude: longitude,
      locationLabel: label,
    );

    return ManualLocationResult.success;
  }

  Future<bool> ensureCityDatabaseAvailable() async {
    if (await _cityDatabaseService.isDownloaded()) {
      return true;
    }
    final downloaded = await _cityDatabaseService.ensureDownloaded();
    return downloaded;
  }

  String? getCityDownloadError() => _cityDatabaseService.lastError;

  Future<List<CityEntry>> searchCities(String query) {
    return _cityDatabaseService.search(query);
  }

  Future<bool> isOnline() => _networkService.isOnline();

  Future<void> useDeviceLocation() async {
    await _settingsProvider.setUseDeviceLocation(true);
    await load();
  }

  /// Persists prayer calculation settings and immediately recalculates every
  /// dependent output: displayed times, home widget and scheduled
  /// notifications.
  Future<void> updateSettings({
    CalculationMethod? method,
    Madhab? madhab,
    Map<Prayer, int>? offsets,
    String? customSound,
    bool setCustomSound = false,
  }) async {
    // Settings can change before the first load completes, so fall back to the
    // persisted values while preserving any location resolved so far.
    final base = _hasLoadedOnce ? state.settings : _settingsProvider.load();

    final updated = base.copyWith(
      method: method,
      madhab: madhab,
      offsets: offsets,
      customAdhanSound: setCustomSound
          ? customSound
          : base.customAdhanSound,
    );

    await _settingsProvider.save(updated);

    final latitude = state.latitude ?? updated.manualLatitude;
    final longitude = state.longitude ?? updated.manualLongitude;

    if (latitude == null || longitude == null) {
      // No coordinates are known yet; a full load resolves location and
      // schedules notifications with the updated settings.
      _hasLoadedOnce = false;
      await load();
      return;
    }

    await _loadForCoordinates(
      settings: updated,
      latitude: latitude,
      longitude: longitude,
      locationLabel: state.locationLabel ?? updated.manualLabel,
    );
  }

  Future<void> refresh() async => load();

  /// Loads prayer times only on the first call.
  ///
  /// The cubit is a shared singleton, so several screens can request it
  /// without triggering duplicate location lookups and rescheduling.
  Future<void> ensureLoaded() async {
    if (_hasLoadedOnce) {
      return;
    }
    await load();
  }

  /// Starts Android native background widget updates.
  ///
  /// This triggers the WidgetUpdateReceiver to begin scheduling
  /// 60-second widget updates via AlarmManager.
  ///
  /// Called when the app successfully loads prayer times.
  Future<void> _startAndroidWidgetUpdates() async {
    try {
      await _platform.invokeMethod('startWidgetUpdates');
    } catch (e) {
      // Platform channel not available or error - widget updates
      // will still work when the app is in foreground via the ticker
    }
  }

  /// Loads prayer times for specific coordinates and updates all services.
  Future<void> _loadForCoordinates({
    required PrayerSettings settings,
    required double? latitude,
    required double? longitude,
    required String? locationLabel,
  }) async {
    if (latitude == null || longitude == null) {
      emit(
        state.copyWith(
          status: PrayerTimesStatus.failure,
          settings: settings,
          errorMessage: 'Missing coordinates',
        ),
      );
      return;
    }

    final coordinates = Coordinates(latitude, longitude);
    final now = DateTime.now();

    final PrayerTimeSummary summary;
    try {
      summary = _prayerService.buildSummary(
        coordinates: coordinates,
        date: now,
        settings: settings,
      );
    } catch (error) {
      // Solar calculations are undefined for some extreme coordinates, for
      // example above the polar circles where the sun may not set at all.
      emit(
        state.copyWith(
          status: PrayerTimesStatus.failure,
          settings: settings,
          errorMessage: 'prayer_times.calculation_failed'.tr(),
        ),
      );
      return;
    }

    _loadedDay = DateTime(now.year, now.month, now.day);

    final gregorianDate = DateFormat.yMMMMEEEEd().format(now);
    final hijri = HijriCalendar.fromDate(now);
    final hijriLine = hijri.toFormat('dd MMMM yyyy');

    emit(
      state.copyWith(
        status: PrayerTimesStatus.ready,
        settings: settings,
        latitude: latitude,
        longitude: longitude,
        locationLabel: locationLabel,
        prayerTimes: summary.prayerTimes,
        currentPrayer: summary.currentPrayer,
        nextPrayer: summary.nextPrayer,
        nextPrayerTime: summary.nextPrayerTime,
        countdown: summary.countdown,
        gregorianDate: gregorianDate,
        hijriDate: hijriLine,
      ),
    );

    // Schedule prayer notifications for each prayer's next real occurrence.
    // Tomorrow's times are provided so past prayers are scheduled with the
    // correct date instead of repeating today's wall-clock time.
    PrayerTimes? tomorrowTimes;
    try {
      tomorrowTimes = _prayerService.calculatePrayerTimes(
        coordinates: coordinates,
        date: now.add(const Duration(days: 1)),
        settings: settings,
      );
    } catch (_) {
      // Fall back to scheduling with today's times only.
    }

    try {
      await _notificationService.schedulePrayerNotifications(
        prayerTimes: summary.prayerTimes,
        nextDayPrayerTimes: tomorrowTimes,
        soundName: settings.customAdhanSound,
      );
    } catch (e) {
      // Notification scheduling must never break the prayer tab: the times are
      // already shown, and the ticker below keeps them fresh. The next load
      // retries the schedule.
      debugPrint('Prayer notification scheduling failed: $e');
    }

    try {
      // Update widget with recalculated data
      await _updateWidget(
        latitude: latitude,
        longitude: longitude,
        settings: settings,
        locationLabel: locationLabel ?? settings.manualLabel ?? 'GPS',
      );
    } catch (e) {
      // A widget failure (e.g. missing platform plugin) must not prevent the
      // in-app countdown from starting.
      debugPrint('Prayer widget update failed: $e');
    }

    // Start Android background widget updates
    await _startAndroidWidgetUpdates();

    // Start UI ticker for in-app countdown display
    _startTicker();
  }

  /// Updates the home widget using the new service architecture.
  ///
  /// This method:
  /// 1. Uses PrayerScheduleService to calculate next prayer dynamically
  /// 2. Handles Isha → Fajr transition correctly
  /// 3. Prevents negative countdown values
  /// 4. Uses WidgetUpdateService to save and trigger widget update
  Future<void> _updateWidget({
    required double latitude,
    required double longitude,
    required PrayerSettings settings,
    required String locationLabel,
  }) async {
    final use24h = _settingsProvider.getUse24HourFormat();

    final model = _prayerScheduleService.calculateWidgetData(
      latitude: latitude,
      longitude: longitude,
      settings: settings,
      use24HourFormat: use24h,
      locationLabel: locationLabel,
    );

    if (model != null) {
      await _widgetUpdateService.updateWidget(model);
    }
  }

  /// Starts a 1-second ticker for updating the in-app UI countdown.
  ///
  /// The ticker only reloads prayer data when the next prayer has been
  /// reached or when the calendar date has actually changed. It never relies
  /// on comparing the day of the next prayer, which would trigger a reload on
  /// every tick between Isha and midnight.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      onTick(DateTime.now());
    });
  }

  /// Processes a single ticker tick.
  ///
  /// Public so the reload policy can be verified deterministically in tests
  /// without depending on the wall clock.
  @visibleForTesting
  void onTick(DateTime now) {
    if (state.prayerTimes == null ||
        state.latitude == null ||
        state.longitude == null) {
      return;
    }

    if (_isReloading) {
      return;
    }

    final nextTime = state.nextPrayerTime;

    if (PrayerTickerPolicy.shouldReload(
      now: now,
      nextPrayerTime: nextTime,
      loadedDay: _loadedDay,
    )) {
      _reloadPrayerTimes();
      return;
    }

    final remaining = nextTime!.difference(now);
    if (!remaining.isNegative) {
      emit(state.copyWith(countdown: remaining));
    }
  }

  /// Recalculates prayer times for the currently active coordinates.
  ///
  /// Guards against overlapping reloads triggered by consecutive ticks while
  /// a previous reload is still in flight.
  void _reloadPrayerTimes() {
    final latitude = state.latitude;
    final longitude = state.longitude;
    if (latitude == null || longitude == null || _isReloading) {
      return;
    }

    _isReloading = true;
    unawaited(
      _loadForCoordinates(
        settings: state.settings,
        latitude: latitude,
        longitude: longitude,
        locationLabel: state.locationLabel,
      ).whenComplete(() {
        _isReloading = false;
      }),
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _ticker = null;
    return super.close();
  }
}
