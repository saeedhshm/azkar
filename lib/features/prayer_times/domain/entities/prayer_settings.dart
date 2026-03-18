import 'package:adhan/adhan.dart';
import 'package:equatable/equatable.dart';

class PrayerSettings extends Equatable {
  const PrayerSettings({
    required this.method,
    required this.madhab,
    required this.offsets,
    required this.useDeviceLocation,
    this.manualLatitude,
    this.manualLongitude,
    this.manualLabel,
    this.customAdhanSound,
  });

  final CalculationMethod method;
  final Madhab madhab;
  final Map<Prayer, int> offsets;
  final bool useDeviceLocation;
  final double? manualLatitude;
  final double? manualLongitude;
  final String? manualLabel;
  final String? customAdhanSound;

  PrayerSettings copyWith({
    CalculationMethod? method,
    Madhab? madhab,
    Map<Prayer, int>? offsets,
    bool? useDeviceLocation,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLabel,
    String? customAdhanSound,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      offsets: offsets ?? this.offsets,
      useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
      manualLatitude: manualLatitude ?? this.manualLatitude,
      manualLongitude: manualLongitude ?? this.manualLongitude,
      manualLabel: manualLabel ?? this.manualLabel,
      customAdhanSound: customAdhanSound ?? this.customAdhanSound,
    );
  }

  static PrayerSettings defaults() {
    return PrayerSettings(
      method: CalculationMethod.egyptian,
      madhab: Madhab.shafi,
      offsets: const {
        Prayer.fajr: 0,
        Prayer.dhuhr: 0,
        Prayer.asr: 0,
        Prayer.maghrib: 0,
        Prayer.isha: 0,
      },
      useDeviceLocation: true,
    );
  }

  @override
  List<Object?> get props => [
    method,
    madhab,
    offsets,
    useDeviceLocation,
    manualLatitude,
    manualLongitude,
    manualLabel,
    customAdhanSound,
  ];
}
