import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

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
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

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
      title: 'Morning Adhkar Reminder',
      body: 'Start your day with remembrance.',
      hour: morning.hour,
      minute: morning.minute,
    );

    await _scheduleNotification(
      id: AppConstants.eveningReminderNotificationId,
      title: 'Evening Adhkar Reminder',
      body: 'Close your day with remembrance.',
      hour: evening.hour,
      minute: evening.minute,
    );

    await _scheduleNotification(
      id: AppConstants.sleepReminderNotificationId,
      title: 'Sleep Adhkar Reminder',
      body: 'End your day with remembrance.',
      hour: sleep.hour,
      minute: sleep.minute,
    );

    await _scheduleNotification(
      id: AppConstants.wakingReminderNotificationId,
      title: 'Waking Adhkar Reminder',
      body: 'Start your morning with remembrance.',
      hour: waking.hour,
      minute: waking.minute,
    );

    await _scheduleWeeklyNotification(
      id: AppConstants.fridayReminderNotificationId,
      title: 'Friday Adhkar Reminder',
      body: 'Remember Allah on this blessed day.',
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
    final currentDay =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'adhkar_reminder',
    );
  }
}
