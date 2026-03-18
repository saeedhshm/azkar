import 'package:adhan/adhan.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/prayer_settings.dart';

enum PrayerTimesStatus {
  initial,
  loading,
  ready,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  failure,
}

class PrayerTimesState extends Equatable {
  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.settings = const PrayerSettings(
      method: CalculationMethod.egyptian,
      madhab: Madhab.shafi,
      offsets: {
        Prayer.fajr: 0,
        Prayer.dhuhr: 0,
        Prayer.asr: 0,
        Prayer.maghrib: 0,
        Prayer.isha: 0,
      },
      useDeviceLocation: true,
    ),
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.prayerTimes,
    this.currentPrayer,
    this.nextPrayer,
    this.nextPrayerTime,
    this.countdown,
    this.gregorianDate,
    this.hijriDate,
    this.errorMessage,
  });

  final PrayerTimesStatus status;
  final PrayerSettings settings;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final PrayerTimes? prayerTimes;
  final Prayer? currentPrayer;
  final Prayer? nextPrayer;
  final DateTime? nextPrayerTime;
  final Duration? countdown;
  final String? gregorianDate;
  final String? hijriDate;
  final String? errorMessage;

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    PrayerSettings? settings,
    double? latitude,
    double? longitude,
    String? locationLabel,
    PrayerTimes? prayerTimes,
    Prayer? currentPrayer,
    Prayer? nextPrayer,
    DateTime? nextPrayerTime,
    Duration? countdown,
    String? gregorianDate,
    String? hijriDate,
    String? errorMessage,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      currentPrayer: currentPrayer ?? this.currentPrayer,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      countdown: countdown ?? this.countdown,
      gregorianDate: gregorianDate ?? this.gregorianDate,
      hijriDate: hijriDate ?? this.hijriDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    latitude,
    longitude,
    locationLabel,
    prayerTimes,
    currentPrayer,
    nextPrayer,
    nextPrayerTime,
    countdown?.inSeconds,
    gregorianDate,
    hijriDate,
    errorMessage,
  ];
}
