import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../storage/local_storage_service.dart';

class PrayerWidgetService {
  PrayerWidgetService(this._storage);

  final LocalStorageService _storage;

  static const androidProvider = 'PrayerWidgetProvider';
  static const iOSWidgetName = 'PrayerWidget';

  static const keyNextPrayer = 'widget_next_prayer';
  static const keyNextLabel = 'widget_next_label';
  static const keyNextPrayerTime = 'widget_next_time';
  static const keyNextPrayerEpoch = 'widget_next_epoch';
  static const keyRemaining = 'widget_remaining';
  static const keyDateLine = 'widget_date';
  static const keyHijriLine = 'widget_hijri';
  static const keyLocation = 'widget_location';

  Future<void> update({
    required Prayer nextPrayer,
    required DateTime nextPrayerTime,
    required Duration remaining,
    required String dateLine,
    required String hijriLine,
    required String locationLabel,
  }) async {
    final use24h = _storage.getUse24HourFormat();
    final timeFormat = DateFormat(use24h ? 'HH:mm' : 'h:mm a');
    final timeText = timeFormat.format(nextPrayerTime);

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
      nextPrayerTime.millisecondsSinceEpoch.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      keyRemaining,
      _formatCountdown(remaining),
    );
    await HomeWidget.saveWidgetData<String>(keyDateLine, dateLine);
    await HomeWidget.saveWidgetData<String>(keyHijriLine, hijriLine);
    await HomeWidget.saveWidgetData<String>(keyLocation, locationLabel);

    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iOSWidgetName,
    );
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

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
