import 'package:azkar/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrayerTickerPolicy.isSameDay', () {
    test('treats times on the same calendar day as equal', () {
      expect(
        PrayerTickerPolicy.isSameDay(
          DateTime(2026, 3, 14, 1),
          DateTime(2026, 3, 14, 23, 59),
        ),
        isTrue,
      );
    });

    test('detects day transitions', () {
      expect(
        PrayerTickerPolicy.isSameDay(
          DateTime(2026, 3, 14, 23, 59),
          DateTime(2026, 3, 15, 0, 1),
        ),
        isFalse,
      );
    });

    test('detects month and year transitions', () {
      expect(
        PrayerTickerPolicy.isSameDay(
          DateTime(2026, 3, 31, 23, 59),
          DateTime(2026, 4, 1),
        ),
        isFalse,
      );
      expect(
        PrayerTickerPolicy.isSameDay(
          DateTime(2026, 12, 31, 23, 59),
          DateTime(2027, 1, 1),
        ),
        isFalse,
      );
    });
  });

  group('PrayerTickerPolicy.shouldReload', () {
    final loadedDay = DateTime(2026, 3, 14);

    test('does not reload for an ordinary upcoming prayer', () {
      final now = DateTime(2026, 3, 14, 12);
      final nextPrayer = DateTime(2026, 3, 14, 15);

      expect(
        PrayerTickerPolicy.shouldReload(
          now: now,
          nextPrayerTime: nextPrayer,
          loadedDay: loadedDay,
        ),
        isFalse,
      );
    });

    test('does not reload every second between Isha and midnight', () {
      // Next prayer is tomorrow's Fajr, so the day numbers differ.
      final isha = DateTime(2026, 3, 14, 21);
      final midnight = DateTime(2026, 3, 15);

      for (
        var now = isha;
        now.isBefore(midnight);
        now = now.add(const Duration(minutes: 1))
      ) {
        expect(
          PrayerTickerPolicy.shouldReload(
            now: now,
            nextPrayerTime: DateTime(2026, 3, 15, 5),
            loadedDay: loadedDay,
          ),
          isFalse,
          reason: 'unexpected reload at $now',
        );
      }
    });

    test('does not reload across a full second-resolution post-Isha window', () {
      final isha = DateTime(2026, 3, 14, 21, 30, 15);
      final midnight = DateTime(2026, 3, 15);

      for (
        var now = isha;
        now.isBefore(midnight);
        now = now.add(const Duration(seconds: 1))
      ) {
        expect(
          PrayerTickerPolicy.shouldReload(
            now: now,
            nextPrayerTime: DateTime(2026, 3, 15, 5),
            loadedDay: loadedDay,
          ),
          isFalse,
          reason: 'unexpected reload at $now',
        );
      }
    });

    test('reloads when the next prayer time has been reached', () {
      expect(
        PrayerTickerPolicy.shouldReload(
          now: DateTime(2026, 3, 14, 15),
          nextPrayerTime: DateTime(2026, 3, 14, 15),
          loadedDay: loadedDay,
        ),
        isTrue,
      );
    });

    test('reloads when the next prayer time is in the past', () {
      expect(
        PrayerTickerPolicy.shouldReload(
          now: DateTime(2026, 3, 14, 18),
          nextPrayerTime: DateTime(2026, 3, 14, 15),
          loadedDay: loadedDay,
        ),
        isTrue,
      );
    });

    test('reloads exactly once after the date changes', () {
      final nextPrayer = DateTime(2026, 3, 15, 5);

      expect(
        PrayerTickerPolicy.shouldReload(
          now: DateTime(2026, 3, 15, 0),
          nextPrayerTime: nextPrayer,
          loadedDay: loadedDay,
        ),
        isTrue,
      );

      // Once the new day's data is loaded, no further reload is needed.
      final newLoadedDay = DateTime(2026, 3, 15);
      expect(
        PrayerTickerPolicy.shouldReload(
          now: DateTime(2026, 3, 15, 2),
          nextPrayerTime: nextPrayer,
          loadedDay: newLoadedDay,
        ),
        isFalse,
      );
    });

    test('reloads when next prayer time is unknown', () {
      expect(
        PrayerTickerPolicy.shouldReload(
          now: DateTime(2026, 3, 14, 12),
          nextPrayerTime: null,
          loadedDay: loadedDay,
        ),
        isTrue,
      );
    });

    test('reloads when no day has been recorded yet', () {
      expect(
        PrayerTickerPolicy.shouldReload(
          now: DateTime(2026, 3, 14, 12),
          nextPrayerTime: DateTime(2026, 3, 14, 15),
          loadedDay: null,
        ),
        isTrue,
      );
    });
  });
}
