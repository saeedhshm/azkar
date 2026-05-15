import 'package:equatable/equatable.dart';

class AyahTiming extends Equatable {
  const AyahTiming({
    required this.surahNumber,
    required this.ayahNumber,
    required this.startMs,
    required this.endMs,
  });

  final int surahNumber;
  final int ayahNumber;
  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;

  bool contains(int positionMs) => positionMs >= startMs && positionMs < endMs;

  @override
  List<Object?> get props => [surahNumber, ayahNumber, startMs, endMs];
}
