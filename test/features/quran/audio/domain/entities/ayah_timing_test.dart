import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/audio/domain/entities/ayah_timing.dart';

void main() {
  group('AyahTiming', () {
    const timing = AyahTiming(
      surahNumber: 1,
      ayahNumber: 1,
      startMs: 0,
      endMs: 5000,
    );

    test('durationMs returns endMs - startMs', () {
      expect(timing.durationMs, 5000);
    });

    test('contains returns true when positionMs is within range', () {
      expect(timing.contains(0), isTrue);
      expect(timing.contains(2500), isTrue);
      expect(timing.contains(4999), isTrue);
    });

    test('contains returns false when positionMs is outside range', () {
      expect(timing.contains(-1), isFalse);
      expect(timing.contains(5000), isFalse);
      expect(timing.contains(6000), isFalse);
    });

    test('props are correct', () {
      expect(
        timing.props,
        containsAll([1, 1, 0, 5000]),
      );
    });
  });
}
