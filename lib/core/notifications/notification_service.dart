import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_constants.dart';

/// Resolves the next concrete occurrence of every prayer.
///
/// Prayer times drift by minutes each day, so a repeating wall-clock schedule
/// is inaccurate. This plan maps each prayer to its next real occurrence,
/// falling back to the following day's time once today's has passed.
class PrayerNotificationPlan {
  const PrayerNotificationPlan._();

  static const notifications = <Prayer, int>{
    Prayer.fajr: AppConstants.fajrNotificationId,
    Prayer.dhuhr: AppConstants.dhuhrNotificationId,
    Prayer.asr: AppConstants.asrNotificationId,
    Prayer.maghrib: AppConstants.maghribNotificationId,
    Prayer.isha: AppConstants.ishaNotificationId,
  };

  static List<PrayerNotificationEntry> build({
    required PrayerTimes prayerTimes,
    PrayerTimes? nextDayPrayerTimes,
    required DateTime now,
  }) {
    final entries = <PrayerNotificationEntry>[];
    final nowWallClock = _wallClock(now);

    for (final prayer in notifications.keys) {
      final today = prayerTimes.timeForPrayer(prayer);
      if (today == null) {
        continue;
      }

      final DateTime scheduledAt;
      if (_wallClock(today).isAfter(nowWallClock)) {
        scheduledAt = today;
      } else {
        final tomorrow = nextDayPrayerTimes?.timeForPrayer(prayer);
        if (tomorrow == null) {
          // Without tomorrow's schedule a date-accurate time cannot be derived,
          // so fall back to the same wall-clock time one day out.
          scheduledAt = today.add(const Duration(days: 1));
        } else {
          scheduledAt = tomorrow;
        }
      }

      entries.add(
        PrayerNotificationEntry(
          prayer: prayer,
          notificationId: notifications[prayer]!,
          scheduledAt: _wallClock(scheduledAt),
        ),
      );
    }

    entries.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return entries;
  }

  /// Maps a local [DateTime] onto the same wall-clock time in [tz.local].
  ///
  /// Prayer times are wall-clock times in the user's own time zone. Converting
  /// the underlying instant instead would shift the scheduled time whenever the
  /// device zone differs from the zone the times were calculated in.
  static tz.TZDateTime _wallClock(DateTime time) {
    return tz.TZDateTime(
      tz.local,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
    );
  }
}

class PrayerNotificationEntry {
  const PrayerNotificationEntry({
    required this.prayer,
    required this.notificationId,
    required this.scheduledAt,
  });

  final Prayer prayer;
  final int notificationId;
  final tz.TZDateTime scheduledAt;
}

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Whether [scheduledAt] may be handed to `zonedSchedule`.
  ///
  /// The plugin rejects any date that is not strictly in the future, so this
  /// must be re-checked at schedule time: a date that was valid when the plan
  /// was built can go stale while earlier platform calls are still in flight
  /// (e.g. the app starts seconds before a prayer time).
  static bool isSchedulable({
    required tz.TZDateTime scheduledAt,
    required tz.TZDateTime now,
  }) {
    return scheduledAt.isAfter(now);
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleReminders({
    required bool enabled,
    required TimeOfDay morning,
    required TimeOfDay evening,
    required TimeOfDay sleep,
    required TimeOfDay waking,
    required TimeOfDay friday,
  }) async {
    await _plugin.cancel(AppConstants.morningReminderNotificationId);
    await _plugin.cancel(AppConstants.eveningReminderNotificationId);
    await _plugin.cancel(AppConstants.sleepReminderNotificationId);
    await _plugin.cancel(AppConstants.wakingReminderNotificationId);
    await _plugin.cancel(AppConstants.fridayReminderNotificationId);

    if (!enabled) {
      return;
    }

    await _scheduleNotification(
      id: AppConstants.morningReminderNotificationId,
      title: 'notifications.adhkar.morning_title'.tr(),
      body: 'notifications.adhkar.morning_body'.tr(),
      hour: morning.hour,
      minute: morning.minute,
    );

    await _scheduleNotification(
      id: AppConstants.eveningReminderNotificationId,
      title: 'notifications.adhkar.evening_title'.tr(),
      body: 'notifications.adhkar.evening_body'.tr(),
      hour: evening.hour,
      minute: evening.minute,
    );

    await _scheduleNotification(
      id: AppConstants.sleepReminderNotificationId,
      title: 'notifications.adhkar.sleep_title'.tr(),
      body: 'notifications.adhkar.sleep_body'.tr(),
      hour: sleep.hour,
      minute: sleep.minute,
    );

    await _scheduleNotification(
      id: AppConstants.wakingReminderNotificationId,
      title: 'notifications.adhkar.waking_title'.tr(),
      body: 'notifications.adhkar.waking_body'.tr(),
      hour: waking.hour,
      minute: waking.minute,
    );

    await _scheduleWeeklyNotification(
      id: AppConstants.fridayReminderNotificationId,
      title: 'notifications.adhkar.friday_title'.tr(),
      body: 'notifications.adhkar.friday_body'.tr(),
      hour: friday.hour,
      minute: friday.minute,
      weekday: DateTime.friday,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    if (!isSchedulable(scheduledAt: schedule, now: tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      schedule,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhkar_channel',
          'Adhkar reminders',
          channelDescription: 'Adhkar reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'adhkar_reminder',
    );
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final currentDay = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var daysUntil = (weekday - now.weekday) % 7;
    var schedule = currentDay.add(Duration(days: daysUntil));

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 7));
    }

    if (!isSchedulable(scheduledAt: schedule, now: tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      schedule,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhkar_channel',
          'Adhkar reminders',
          channelDescription: 'Adhkar reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'adhkar_reminder',
    );
  }

  /// Schedules the next concrete occurrence of each prayer.
  ///
  /// Prayer times shift by minutes every day, so each notification is
  /// scheduled for a single specific date instead of repeating a fixed
  /// wall-clock time via [DateTimeComponents.time]. [now] is injectable for
  /// testing.
  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes,
    PrayerTimes? nextDayPrayerTimes,
    String? soundName,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();

    final plan = PrayerNotificationPlan.build(
      prayerTimes: prayerTimes,
      nextDayPrayerTimes: nextDayPrayerTimes,
      now: reference,
    );

    // Cancel first so a stale pending alarm is always removed. zonedSchedule
    // overwrites the same ids, but cancelling guarantees no leftover alarm
    // fires after a settings or location change.
    await _cancelPrayerNotifications();

    for (final entry in plan) {
      try {
        await _schedulePrayerNotification(
          id: entry.notificationId,
          prayer: entry.prayer,
          scheduledAt: entry.scheduledAt,
          soundName: soundName,
        );
      } catch (e) {
        // One stale or rejected entry must never abort the whole batch or
        // crash startup; the remaining prayers are still scheduled.
        debugPrint('Skipping prayer notification for ${entry.prayer}: $e');
      }
    }
  }

  Future<void> _cancelPrayerNotifications() async {
    for (final id in const [
      AppConstants.fajrNotificationId,
      AppConstants.dhuhrNotificationId,
      AppConstants.asrNotificationId,
      AppConstants.maghribNotificationId,
      AppConstants.ishaNotificationId,
    ]) {
      await _plugin.cancel(id);
    }
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required Prayer prayer,
    required tz.TZDateTime scheduledAt,
    String? soundName,
  }) async {
    if (!isSchedulable(
      scheduledAt: scheduledAt,
      now: tz.TZDateTime.now(tz.local),
    )) {
      // The prayer time passed while earlier notifications were being
      // scheduled (or the app started right at the boundary). Scheduling it
      // now would throw "Must be a date in the future" and, worse, show a
      // stale alert for a prayer that already occurred.
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer times',
      channelDescription: 'Prayer time notifications',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      sound: soundName != null && soundName.isNotEmpty
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      sound: soundName != null && soundName.isNotEmpty ? soundName : null,
    );

    await _plugin.zonedSchedule(
      id,
      _prayerTitle(prayer),
      _prayerBody(prayer),
      scheduledAt,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'prayer_time',
    );
  }

  String _prayerTitle(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 'notifications.prayer.fajr_title'.tr(),
      Prayer.dhuhr => 'notifications.prayer.dhuhr_title'.tr(),
      Prayer.asr => 'notifications.prayer.asr_title'.tr(),
      Prayer.maghrib => 'notifications.prayer.maghrib_title'.tr(),
      Prayer.isha => 'notifications.prayer.isha_title'.tr(),
      _ => 'notifications.prayer.default_title'.tr(),
    };
  }

  String _prayerBody(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 'notifications.prayer.fajr_body'.tr(),
      Prayer.dhuhr => 'notifications.prayer.dhuhr_body'.tr(),
      Prayer.asr => 'notifications.prayer.asr_body'.tr(),
      Prayer.maghrib => 'notifications.prayer.maghrib_body'.tr(),
      Prayer.isha => 'notifications.prayer.isha_body'.tr(),
      _ => 'notifications.prayer.default_body'.tr(),
    };
  }
}
