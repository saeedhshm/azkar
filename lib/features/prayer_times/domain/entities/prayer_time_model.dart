/// Domain model representing the next prayer information for widget display.
///
/// Encapsulates all data needed by the home widget:
/// - Next prayer name (localized)
/// - Time until next prayer
/// - Formatted prayer time
/// - Date and location metadata
class PrayerTimeModel {
  const PrayerTimeModel({
    required this.nextPrayerName,
    required this.nextPrayerLabel,
    required this.remainingDuration,
    required this.prayerTimeFormatted,
    required this.prayerTimeEpoch,
    required this.gregorianDate,
    required this.hijriDate,
    required this.locationLabel,
  });

  /// Localized name of the next prayer (e.g., "Dhuhr", "العصر")
  final String nextPrayerName;

  /// Localized label for the next prayer indicator (e.g., "Next prayer")
  final String nextPrayerLabel;

  /// Time remaining until the next prayer
  /// Guaranteed to be non-negative
  final Duration remainingDuration;

  /// Formatted prayer time string (e.g., "12:30 PM" or "12:30")
  final String prayerTimeFormatted;

  /// Epoch milliseconds of the next prayer time
  final int prayerTimeEpoch;

  /// Gregorian date string (e.g., "Monday, January 1, 2024")
  final String gregorianDate;

  /// Hijri date string (e.g., "15 Rajab 1445")
  final String hijriDate;

  /// Location label (e.g., "Cairo, Egypt" or "GPS")
  final String locationLabel;

  /// Creates a copy with updated fields.
  PrayerTimeModel copyWith({
    String? nextPrayerName,
    String? nextPrayerLabel,
    Duration? remainingDuration,
    String? prayerTimeFormatted,
    int? prayerTimeEpoch,
    String? gregorianDate,
    String? hijriDate,
    String? locationLabel,
  }) {
    return PrayerTimeModel(
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      nextPrayerLabel: nextPrayerLabel ?? this.nextPrayerLabel,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      prayerTimeFormatted: prayerTimeFormatted ?? this.prayerTimeFormatted,
      prayerTimeEpoch: prayerTimeEpoch ?? this.prayerTimeEpoch,
      gregorianDate: gregorianDate ?? this.gregorianDate,
      hijriDate: hijriDate ?? this.hijriDate,
      locationLabel: locationLabel ?? this.locationLabel,
    );
  }
}
