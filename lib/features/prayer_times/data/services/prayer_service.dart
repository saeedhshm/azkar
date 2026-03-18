import 'package:adhan/adhan.dart';

import '../../domain/entities/prayer_settings.dart';

class PrayerService {
  PrayerTimes calculatePrayerTimes({
    required Coordinates coordinates,
    required DateTime date,
    required PrayerSettings settings,
  }) {
    final params = settings.method.getParameters();
    params.madhab = settings.madhab;

    final adjustments = params.adjustments;
    adjustments.fajr = settings.offsets[Prayer.fajr] ?? 0;
    adjustments.dhuhr = settings.offsets[Prayer.dhuhr] ?? 0;
    adjustments.asr = settings.offsets[Prayer.asr] ?? 0;
    adjustments.maghrib = settings.offsets[Prayer.maghrib] ?? 0;
    adjustments.isha = settings.offsets[Prayer.isha] ?? 0;

    return PrayerTimes(
      coordinates,
      DateComponents.from(date),
      params,
    );
  }

  PrayerTimeSummary buildSummary({
    required Coordinates coordinates,
    required DateTime date,
    required PrayerSettings settings,
  }) {
    final times = calculatePrayerTimes(
      coordinates: coordinates,
      date: date,
      settings: settings,
    );

    final now = DateTime.now();
    var nextPrayer = times.nextPrayer();
    var nextTime = times.timeForPrayer(nextPrayer);

    if (nextPrayer == Prayer.none || nextTime == null) {
      final tomorrow = date.add(const Duration(days: 1));
      final tomorrowTimes = calculatePrayerTimes(
        coordinates: coordinates,
        date: tomorrow,
        settings: settings,
      );
      nextPrayer = Prayer.fajr;
      nextTime = tomorrowTimes.fajr;
    }

    final currentPrayer = times.currentPrayer();
    final countdown = nextTime != null ? nextTime.difference(now) : null;

    return PrayerTimeSummary(
      prayerTimes: times,
      currentPrayer: currentPrayer == Prayer.none ? null : currentPrayer,
      nextPrayer: nextPrayer == Prayer.none ? Prayer.fajr : nextPrayer,
      nextPrayerTime: nextTime,
      countdown: countdown,
    );
  }
}

class PrayerTimeSummary {
  const PrayerTimeSummary({
    required this.prayerTimes,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.countdown,
  });

  final PrayerTimes prayerTimes;
  final Prayer? currentPrayer;
  final Prayer nextPrayer;
  final DateTime? nextPrayerTime;
  final Duration? countdown;
}
