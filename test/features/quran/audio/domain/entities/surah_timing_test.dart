import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/audio/domain/entities/surah_timing.dart';
import 'package:azkar/features/quran/audio/domain/entities/ayah_timing.dart';

void main() {
  group('SurahTiming', () {
    final ayahTimings = List.generate(7, (i) {
      final startMs = i * 3000;
      return AyahTiming(
        surahNumber: 1,
        ayahNumber: i + 1,
        startMs: startMs,
        endMs: startMs + 2500,
      );
    });

    const surahNumber = 1;
    final timing = SurahTiming(surahNumber: surahNumber, ayahTimings: ayahTimings);

    test('totalDurationMs returns last ayah endMs', () {
      expect(timing.totalDurationMs, ayahTimings.last.endMs);
    });

    test('totalDurationMs returns 0 when empty', () {
      const emptyTiming = SurahTiming(surahNumber: 1, ayahTimings: []);
      expect(emptyTiming.totalDurationMs, 0);
    });

    test('ayahAtPosition returns correct ayah', () {
      final result = timing.ayahAtPosition(2499);
      expect(result, isNotNull);
      expect(result!.ayahNumber, 1);
    });

    test('ayahAtPosition returns null for position beyond end', () {
      final result = timing.ayahAtPosition(99999);
      expect(result, isNull);
    });

    test('ayahAtPosition returns null for position before start', () {
      final result = timing.ayahAtPosition(-1);
      expect(result, isNull);
    });

    test('ayahByNumber returns correct ayah', () {
      final result = timing.ayahByNumber(5);
      expect(result, isNotNull);
      expect(result!.ayahNumber, 5);
    });

    test('ayahByNumber returns null for non-existent ayah', () {
      final result = timing.ayahByNumber(99);
      expect(result, isNull);
    });
  });
}
