import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_constants.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes,
    String? soundName,
  }) async {
    await _plugin.cancel(AppConstants.fajrNotificationId);
    await _plugin.cancel(AppConstants.dhuhrNotificationId);
    await _plugin.cancel(AppConstants.asrNotificationId);
    await _plugin.cancel(AppConstants.maghribNotificationId);
    await _plugin.cancel(AppConstants.ishaNotificationId);

    await _schedulePrayerNotification(
      id: AppConstants.fajrNotificationId,
      prayer: Prayer.fajr,
      time: prayerTimes.fajr,
      soundName: soundName,
    );
    await _schedulePrayerNotification(
      id: AppConstants.dhuhrNotificationId,
      prayer: Prayer.dhuhr,
      time: prayerTimes.dhuhr,
      soundName: soundName,
    );
    await _schedulePrayerNotification(
      id: AppConstants.asrNotificationId,
      prayer: Prayer.asr,
      time: prayerTimes.asr,
      soundName: soundName,
    );
    await _schedulePrayerNotification(
      id: AppConstants.maghribNotificationId,
      prayer: Prayer.maghrib,
      time: prayerTimes.maghrib,
      soundName: soundName,
    );
    await _schedulePrayerNotification(
      id: AppConstants.ishaNotificationId,
      prayer: Prayer.isha,
      time: prayerTimes.isha,
      soundName: soundName,
    );
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required Prayer prayer,
    required DateTime time,
    String? soundName,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer times',
      channelDescription: 'Prayer time notifications',
      importance: Importance.high,
      priority: Priority.high,
      sound: soundName != null && soundName.isNotEmpty
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: soundName != null && soundName.isNotEmpty ? soundName : null,
    );

    await _plugin.zonedSchedule(
      id,
      _prayerTitle(prayer),
      _prayerBody(prayer),
      schedule,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
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
