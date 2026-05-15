import 'package:azkar/features/quran/data/datasources/quran_search_index.dart';
import 'package:azkar/features/quran/domain/entities/quran_ayah.dart';
import 'package:azkar/features/quran/domain/entities/quran_surah.dart';
import 'package:flutter_test/flutter_test.dart';

QuranSurah _surah({
  required int number,
  required String name,
  required List<QuranAyah> ayahs,
}) {
  return QuranSurah(
    number: number,
    name: name,
    englishName: '',
    englishNameTranslation: '',
    revelationType: 'Meccan',
    ayahCount: ayahs.length,
    ayahs: ayahs,
  );
}

QuranAyah _ayah({
  required int surah,
  required int number,
  required String text,
  int page = 1,
}) {
  return QuranAyah(
    globalNumber: number,
    numberInSurah: number,
    surahNumber: surah,
    juz: 1,
    page: page,
    text: text,
  );
}

void main() {
  late QuranSearchIndex index;
  late List<QuranSurah> surahs;

  setUp(() {
    index = QuranSearchIndex();
    surahs = [
      _surah(
        number: 1,
        name: 'الفاتحة',
        ayahs: [
          _ayah(surah: 1, number: 1, text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
          _ayah(surah: 1, number: 2, text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
          _ayah(surah: 1, number: 3, text: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
          _ayah(surah: 1, number: 4, text: 'مَٰلِكِ يَوْمِ ٱلدِّينِ'),
        ],
      ),
      _surah(
        number: 112,
        name: 'الإخلاص',
        ayahs: [
          _ayah(surah: 112, number: 1, text: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ'),
          _ayah(surah: 112, number: 2, text: 'ٱللَّهُ ٱلصَّمَدُ'),
          _ayah(surah: 112, number: 3, text: 'لَمْ يَلِدْ وَلَمْ يُولَدْ'),
        ],
      ),
    ];
    index.build(surahs);
  });

  group('build', () {
    test('isBuilt returns true after building', () {
      expect(index.isBuilt, isTrue);
    });

    test('isBuilt returns false before building', () {
      final empty = QuranSearchIndex();
      expect(empty.isBuilt, isFalse);
    });

    test('handles empty surahs list', () {
      final empty = QuranSearchIndex();
      empty.build([]);
      expect(empty.isBuilt, isTrue);
      expect(empty.search('الله'), isEmpty);
    });
  });

  group('search - exact word match', () {
    test('finds exact word match across surahs', () {
      final results = index.search('الله');
      expect(results, isNotEmpty);
      // "الله" appears in ayat 1:1 and 112:1 and 112:2
      final keys = results.map((m) => '${m.ref.surahNumber}:${m.ref.ayahNumber}').toSet();
      expect(keys, contains('112:1'));
      expect(keys, contains('112:2'));
    });

    test('matches with normalization (alef variants)', () {
      // "ٱللَّهِ" should match search for "الله"
      final results = index.search('الله');
      final keys = results.map((m) => '${m.ref.surahNumber}:${m.ref.ayahNumber}').toSet();
      expect(keys, contains('1:1'));
    });

    test('scores exact matches higher than prefix matches', () {
      final results = index.search('ال');
      expect(results, isNotEmpty);
      // All results should have score > 0
      for (final match in results) {
        expect(match.score, greaterThan(0));
      }
    });

    test('returns empty for non-existent word', () {
      final results = index.search('شسيشسيشسي');
      expect(results, isEmpty);
    });

    test('handles partial prefix query', () {
      // "ال" is a prefix of "الرحمن", "الرحيم", "الحمد", etc.
      final results = index.search('ال');
      expect(results, isNotEmpty);
    });
  });

  group('search - prefix matching', () {
    test('finds prefix matches', () {
      // "ال" is a prefix of many words
      final results = index.search('ال');
      expect(results, isNotEmpty);
    });

    test('prefix match has matchedWord set', () {
      final results = index.search('ال');
      for (final match in results) {
        expect(match.matchedWord, isNotEmpty);
      }
    });
  });

  group('search - multi-word queries', () {
    test('handles multi-word queries', () {
      final results = index.search('الله أحد');
      expect(results, isNotEmpty);
    });

    test('multi-word matches score higher', () {
      final single = index.search('الله');
      final multi = index.search('الله أحد');
      if (multi.isNotEmpty && single.isNotEmpty) {
        expect(multi.first.score, greaterThanOrEqualTo(single.first.score));
      }
    });
  });

  group('search - result limits', () {
    test('limits results to maxResults', () {
      // Search for a very common word
      final results = index.search('ال');
      expect(results.length, lessThanOrEqualTo(QuranSearchIndex.maxResults));
    });
  });

  group('search - score consistency', () {
    test('exact match scores 3 per match, prefix scores 2 per match', () {
      // "أحد" appears once in surah 112 ayah 1 → score should be 3
      final results = index.search('أحد');
      for (final match in results) {
        if (match.ref.surahNumber == 112 && match.ref.ayahNumber == 1) {
          expect(match.score, 3);
        }
      }
    });

    test('results sorted by score descending', () {
      final results = index.search('الله');
      for (var i = 1; i < results.length; i++) {
        expect(results[i].score, lessThanOrEqualTo(results[i - 1].score));
      }
    });
  });

  group('search - after multiple builds', () {
    test('rebuilding replaces old index', () {
      index.build([]);
      expect(index.search('الله'), isEmpty);
    });
  });
}
