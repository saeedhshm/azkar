import 'package:equatable/equatable.dart';

import 'ayah_timing.dart';

class SurahTiming extends Equatable {
  const SurahTiming({
    required this.surahNumber,
    required this.ayahTimings,
  });

  final int surahNumber;
  final List<AyahTiming> ayahTimings;

  int get totalDurationMs =>
      ayahTimings.isEmpty ? 0 : ayahTimings.last.endMs;

  AyahTiming? ayahAtPosition(int positionMs) {
    for (final timing in ayahTimings) {
      if (timing.contains(positionMs)) {
        return timing;
      }
    }
    return null;
  }

  AyahTiming? ayahByNumber(int ayahNumber) {
    for (final timing in ayahTimings) {
      if (timing.ayahNumber == ayahNumber) {
        return timing;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [surahNumber, ayahTimings];
}
