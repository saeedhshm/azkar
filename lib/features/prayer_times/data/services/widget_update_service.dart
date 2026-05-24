import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:home_widget/home_widget.dart';

import '../../domain/entities/prayer_time_model.dart';

/// Service responsible for updating the Android/iOS home widget with
/// prayer time data.
///
/// Responsibilities:
/// - Save widget data via HomeWidget.saveWidgetData()
/// - Trigger widget refresh via HomeWidget.updateWidget()
/// - Format countdown strings safely
/// - Localize prayer names
///
/// This service handles the presentation layer of widget updates,
/// separating formatting and localization from business logic.
class WidgetUpdateService {
  WidgetUpdateService();

  // Widget provider identifiers
  static const androidProvider = 'PrayerWidgetProvider';
  static const iOSWidgetName = 'PrayerWidget';

  // Widget data keys (must match Android native code and iOS widget)
  static const keyNextPrayer = 'widget_next_prayer';
  static const keyNextLabel = 'widget_next_label';
  static const keyNextPrayerTime = 'widget_next_time';
  static const keyNextPrayerEpoch = 'widget_next_epoch';
  static const keyRemaining = 'widget_remaining';
  static const keyDateLine = 'widget_date';
  static const keyHijriLine = 'widget_hijri';
  static const keyLocation = 'widget_location';

  /// Updates the home widget with the provided prayer schedule data.
  ///
  /// This method:
  /// 1. Localizes prayer names and labels
  /// 2. Formats the countdown string
  /// 3. Saves all data to shared preferences (accessible by native widget)
  /// 4. Triggers widget UI refresh
  Future<void> updateWidget(PrayerTimeModel model) async {
    // Localize prayer name
    final localizedPrayerName = _localizePrayerName(model.nextPrayerName);
    final localizedNextLabel = 'prayer_times.next_prayer'.tr();

    // Format countdown safely
    final countdownText = _formatCountdown(model.remainingDuration);

    // Save all widget data
    await HomeWidget.saveWidgetData<String>(
      keyNextPrayer,
      localizedPrayerName,
    );
    await HomeWidget.saveWidgetData<String>(
      keyNextLabel,
      localizedNextLabel,
    );
    await HomeWidget.saveWidgetData<String>(
      keyNextPrayerTime,
      model.prayerTimeFormatted,
    );
    await HomeWidget.saveWidgetData<String>(
      keyNextPrayerEpoch,
      model.prayerTimeEpoch.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      keyRemaining,
      countdownText,
    );
    await HomeWidget.saveWidgetData<String>(
      keyDateLine,
      model.gregorianDate,
    );
    await HomeWidget.saveWidgetData<String>(
      keyHijriLine,
      model.hijriDate,
    );
    await HomeWidget.saveWidgetData<String>(
      keyLocation,
      model.locationLabel,
    );

    // Trigger widget refresh on both platforms
    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iOSWidgetName,
    );
  }

  /// Formats a duration as HH:MM:SS countdown string.
  ///
  /// Handles negative durations by showing "00:00:00".
  String _formatCountdown(Duration duration) {
    // Prevent negative display
    if (duration.isNegative) {
      return '00:00:00';
    }

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Localizes a prayer name from English to the current app locale.
  ///
  /// Uses easy_localization keys for translation.
  String _localizePrayerName(String prayerName) {
    return switch (prayerName) {
      'Fajr' => 'prayer_times.prayers.fajr'.tr(),
      'Sunrise' => 'prayer_times.prayers.sunrise'.tr(),
      'Dhuhr' => 'prayer_times.prayers.dhuhr'.tr(),
      'Asr' => 'prayer_times.prayers.asr'.tr(),
      'Maghrib' => 'prayer_times.prayers.maghrib'.tr(),
      'Isha' => 'prayer_times.prayers.isha'.tr(),
      _ => 'prayer_times.prayers.fajr'.tr(),
    };
  }
}
