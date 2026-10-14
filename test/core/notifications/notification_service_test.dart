import 'package:adhan/adhan.dart';
import 'package:azkar/core/constants/app_constants.dart';
import 'package:azkar/core/notifications/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });
  final coordinates = Coordinates(21.4225, 39.8262); // Mecca

  PrayerTimes timesFor(DateTime date, {int fajrAdjustmentMinutes = 0}) {
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    params.adjustments.fajr = fajrAdjustmentMinutes;
    return PrayerTimes(coordinates, DateComponents.from(date), params);
  }

  group('PrayerNotificationPlan', () {
    test('schedules upcoming prayers on today with their real time', () {
      final now = DateTime(2026, 3, 14, 3); // before Fajr
      final today = timesFor(now);

      final plan = PrayerNotificationPlan.build(
        prayerTimes: today,
        nextDayPrayerTimes: timesFor(DateTime(2026, 3, 15, 3)),
        now: now,
      );

      expect(plan, hasLength(5));

      final fajr = plan.firstWhere((e) => e.prayer == Prayer.fajr);
      expect(fajr.notificationId, AppConstants.fajrNotificationId);
      expect(fajr.scheduledAt.hour, today.fajr.hour);
      expect(fajr.scheduledAt.minute, today.fajr.minute);
      expect(fajr.scheduledAt.day, 14);
    });

    test('moves passed prayers to tomorrow using next day times', () {
      // 22:00 local: every prayer including Isha has already passed.
      final now = DateTime(2026, 3, 14, 22);
      final today = timesFor(now);
      final tomorrow = timesFor(DateTime(2026, 3, 15, 22));

      final plan = PrayerNotificationPlan.build(
        prayerTimes: today,
        nextDayPrayerTimes: tomorrow,
        now: now,
      );

      expect(plan, hasLength(5));

      final isha = plan.firstWhere((e) => e.prayer == Prayer.isha);
      expect(isha.scheduledAt.day, 15);
      expect(isha.scheduledAt.hour, tomorrow.isha.hour);
      expect(isha.scheduledAt.minute, tomorrow.isha.minute);

      for (final entry in plan) {
        expect(
          entry.scheduledAt.isAfter(tz.TZDateTime(tz.local, 2026, 3, 14, 22)),
          isTrue,
          reason: '${entry.prayer} must be scheduled in the future',
        );
      }
    });

    test('does not repeat today clock time for passed prayers', () {
      final now = DateTime(2026, 3, 14, 22);
      final today = timesFor(now);
      // Tomorrow's schedule shifts Fajr by 7 minutes, mirroring the daily drift
      // that makes a repeating wall-clock alarm inaccurate.
      final tomorrow = timesFor(DateTime(2026, 3, 15, 22), fajrAdjustmentMinutes: 7);

      final plan = PrayerNotificationPlan.build(
        prayerTimes: today,
        nextDayPrayerTimes: tomorrow,
        now: now,
      );

      final fajr = plan.firstWhere((e) => e.prayer == Prayer.fajr);
      expect(fajr.scheduledAt.day, 15);
      expect(fajr.scheduledAt.hour, tomorrow.fajr.hour);
      expect(fajr.scheduledAt.minute, tomorrow.fajr.minute);

      final tomorrowFajr = tomorrow.timeForPrayer(Prayer.fajr)!;
      final todayFajr = today.timeForPrayer(Prayer.fajr)!;
      expect(tomorrowFajr, isNot(equals(todayFajr)));
    });

    test('falls back to same clock time next day without tomorrow schedule', () {
      final now = DateTime(2026, 3, 14, 22);
      final today = timesFor(now);

      final plan = PrayerNotificationPlan.build(
        prayerTimes: today,
        now: now,
      );

      expect(plan, hasLength(5));

      final isha = plan.firstWhere((e) => e.prayer == Prayer.isha);
      expect(isha.scheduledAt.day, 15);
      expect(isha.scheduledAt.hour, today.isha.hour);
      expect(isha.scheduledAt.minute, today.isha.minute);
    });

    test('schedules entries in chronological order', () {
      final now = DateTime(2026, 3, 14, 22);
      final plan = PrayerNotificationPlan.build(
        prayerTimes: timesFor(now),
        nextDayPrayerTimes: timesFor(DateTime(2026, 3, 15, 22)),
        now: now,
      );

      for (var i = 1; i < plan.length; i++) {
        expect(
          plan[i].scheduledAt.isBefore(plan[i - 1].scheduledAt),
          isFalse,
        );
      }
    });

    test('uses the expected notification ids', () {
      final now = DateTime(2026, 3, 14, 3);
      final plan = PrayerNotificationPlan.build(
        prayerTimes: timesFor(now),
        nextDayPrayerTimes: timesFor(DateTime(2026, 3, 15, 3)),
        now: now,
      );

      final ids = plan.map((e) => e.notificationId).toSet();
      expect(ids, {
        AppConstants.fajrNotificationId,
        AppConstants.dhuhrNotificationId,
        AppConstants.asrNotificationId,
        AppConstants.maghribNotificationId,
        AppConstants.ishaNotificationId,
      });
    });
  });

  group('NotificationService.isSchedulable', () {
    tz.TZDateTime at(int hour, [int minute = 0, int second = 0]) {
      return tz.TZDateTime(tz.local, 2026, 3, 14, hour, minute, second);
    }

    test('accepts a future date', () {
      expect(
        NotificationService.isSchedulable(
          scheduledAt: at(10, 30),
          now: at(10, 25),
        ),
        isTrue,
      );
    });

    test('rejects a past date', () {
      expect(
        NotificationService.isSchedulable(
          scheduledAt: at(10, 25),
          now: at(10, 30),
        ),
        isFalse,
      );
    });

    test('rejects a date equal to now: the plugin requires strictly future', () {
      expect(
        NotificationService.isSchedulable(
          scheduledAt: at(10, 30),
          now: at(10, 30),
        ),
        isFalse,
      );
    });

    test('accepts a date one second in the future', () {
      expect(
        NotificationService.isSchedulable(
          scheduledAt: at(10, 30, 1),
          now: at(10, 30, 0),
        ),
        isTrue,
      );
    });
  });

  group('NotificationService.schedulePrayerNotifications', () {
    const channel = MethodChannel(
      'dexterous.com/flutter/local_notifications',
    );

    final scheduledIds = <int>[];
    final scheduledDates = <int, DateTime>{};
    final cancelledIds = <int>[];

    setUp(() {
      // Registers the method-channel platform implementation so the plugin
      // under test can resolve it; the channel itself is mocked below.
      AndroidFlutterLocalNotificationsPlugin.registerWith();

      scheduledIds.clear();
      scheduledDates.clear();
      cancelledIds.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'cancel':
                final args = call.arguments;
                cancelledIds.add(
                  args is Map ? args['id'] as int : args as int,
                );
                return null;
              case 'zonedSchedule':
                final args = call.arguments as Map;
                scheduledIds.add(args['id'] as int);
                scheduledDates[args['id'] as int] = DateTime.parse(
                  args['scheduledDateTimeISO8601'] as String,
                );
                return null;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'skips entries that went stale instead of throwing '
      '"Must be a date in the future"',
      () async {
        // Regression: starting the app seconds before a prayer meant the plan
        // was valid at build time but stale by schedule time, crashing startup
        // with an unhandled ArgumentError from zonedSchedule.
        //
        // A plan built for two days ago is stale in every entry no matter when
        // or in which time zone this test runs.
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final staleDay = DateTime(
          twoDaysAgo.year,
          twoDaysAgo.month,
          twoDaysAgo.day,
        );
        final service = NotificationService(
          plugin: FlutterLocalNotificationsPlugin(),
        );

        await service.schedulePrayerNotifications(
          prayerTimes: timesFor(staleDay),
          nextDayPrayerTimes: timesFor(staleDay.add(const Duration(days: 1))),
          now: DateTime(
            staleDay.year,
            staleDay.month,
            staleDay.day,
            23,
            59,
          ),
        );

        expect(scheduledIds, isEmpty);
        expect(
          cancelledIds,
          unorderedEquals([
            AppConstants.fajrNotificationId,
            AppConstants.dhuhrNotificationId,
            AppConstants.asrNotificationId,
            AppConstants.maghribNotificationId,
            AppConstants.ishaNotificationId,
          ]),
        );
      },
    );

    test('schedules future entries with strictly future dates', () async {
      final service = NotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
      );

      await service.schedulePrayerNotifications(
        prayerTimes: timesFor(DateTime.now()),
        nextDayPrayerTimes: timesFor(
          DateTime.now().add(const Duration(days: 1)),
        ),
      );

      expect(scheduledIds, isNotEmpty);
      final checkTime = DateTime.now();
      for (final entry in scheduledDates.entries) {
        expect(
          entry.value.isAfter(checkTime),
          isTrue,
          reason: 'notification ${entry.key} must be strictly in the future',
        );
      }
    });
  });
}
