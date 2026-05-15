import 'package:azkar/features/quran/services/quran_search_text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('removes diacritics', () {
      final input = 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      final result = QuranSearchTextUtils.normalize(input);
      expect(result.contains('َ'), isFalse);
      expect(result.contains('ِ'), isFalse);
      expect(result.contains('ّ'), isFalse);
      expect(result.contains('ٰ'), isFalse);
    });

    test('normalizes alef variants to ا', () {
      expect(QuranSearchTextUtils.normalize('أ'), 'ا');
      expect(QuranSearchTextUtils.normalize('إ'), 'ا');
      expect(QuranSearchTextUtils.normalize('آ'), 'ا');
      expect(QuranSearchTextUtils.normalize('ٱ'), 'ا');
    });

    test('normalizes taa marbouta to haa', () {
      expect(QuranSearchTextUtils.normalize('ة'), 'ه');
    });

    test('lowercases English text', () {
      expect(QuranSearchTextUtils.normalize('ALLAH'), 'allah');
    });

    test('trims whitespace and collapses spaces', () {
      expect(QuranSearchTextUtils.normalize('  الله   رحيم  '), 'الله رحيم');
    });

    test('handles empty string', () {
      expect(QuranSearchTextUtils.normalize(''), '');
    });
  });

  group('tokenize', () {
    test('splits normalized text into words', () {
      final result = QuranSearchTextUtils.tokenize('الله رحيم كريم');
      expect(result, ['الله', 'رحيم', 'كريم']);
    });

    test('filters empty tokens', () {
      final result = QuranSearchTextUtils.tokenize('hello   world');
      expect(result, ['hello', 'world']);
    });
  });

  group('findMatches', () {
    test('finds matching words', () {
      final matches = QuranSearchTextUtils.findMatches('الله رحيم كريم', 'الله');
      expect(matches.length, 1);
      expect(matches.first.start, 0);
    });

    test('returns empty list for no matches', () {
      final matches = QuranSearchTextUtils.findMatches('الله رحيم', 'شيطان');
      expect(matches, isEmpty);
    });
  });
}
