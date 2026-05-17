import 'package:azkar/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:azkar/features/quran/data/datasources/quran_search_index.dart';
import 'package:azkar/features/quran/data/models/quran_ayah_model.dart';
import 'package:azkar/features/quran/data/models/quran_surah_model.dart';
import 'package:azkar/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:azkar/features/quran/domain/entities/quran_ayah.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockDataSource extends QuranLocalDataSource {
  List<QuranSurahModel>? _surahs;

  void setSurahs(List<QuranSurahModel> surahs) {
    _surahs = surahs;
  }

  @override
  Future<List<QuranSurahModel>> loadSurahs() async {
    if (_surahs != null) return _surahs!;
    return [];
  }
}

QuranSurahModel _surah({
  required int number,
  required String name,
  required String englishName,
  required String englishNameTranslation,
  required List<QuranAyah> ayahs,
}) {
  return QuranSurahModel(
    number: number,
    name: name,
    englishName: englishName,
    englishNameTranslation: englishNameTranslation,
    revelationType: 'Meccan',
    ayahCount: ayahs.length,
    ayahs: ayahs,
  );
}

QuranAyahModel _ayah({
  required int surah,
  required int number,
  required String text,
  int page = 1,
}) {
  return QuranAyahModel(
    globalNumber: number,
    numberInSurah: number,
    surahNumber: surah,
    juz: 1,
    page: page,
    text: text,
  );
}

void main() {
  late _MockDataSource dataSource;
  late QuranSearchIndex searchIndex;
  late QuranRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    searchIndex = QuranSearchIndex();
    repository = QuranRepositoryImpl(dataSource, searchIndex);

    dataSource.setSurahs([
      _surah(
        number: 1,
        name: 'سُورَةُ ٱلْفَاتِحَةِ',
        englishName: 'Al-Faatiha',
        englishNameTranslation: 'The Opening',
        ayahs: [
          _ayah(surah: 1, number: 1, text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', page: 1),
          _ayah(surah: 1, number: 2, text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ', page: 1),
          _ayah(surah: 1, number: 3, text: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', page: 1),
          _ayah(surah: 1, number: 4, text: 'مَٰلِكِ يَوْمِ ٱلدِّينِ', page: 1),
        ],
      ),
      _surah(
        number: 112,
        name: 'سُورَةُ ٱلْإِخْلَاصِ',
        englishName: 'Al-Ikhlaas',
        englishNameTranslation: 'Sincerity',
        ayahs: [
          _ayah(surah: 112, number: 1, text: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ', page: 604),
          _ayah(surah: 112, number: 2, text: 'ٱللَّهُ ٱلصَّمَدُ', page: 604),
          _ayah(surah: 112, number: 3, text: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', page: 604),
        ],
      ),
    ]);
  });

  group('search - text matching', () {
    test('finds ayahs by Arabic text', () async {
      final results = await repository.search('الله');
      expect(results, isNotEmpty);
      final keys = results.map((r) => '${r.surah.number}:${r.ayah.numberInSurah}').toSet();
      expect(keys, contains('1:1'));
      expect(keys, contains('112:1'));
      expect(keys, contains('112:2'));
    });

    test('returns matchedWord in results', () async {
      final results = await repository.search('الله');
      expect(results, isNotEmpty);
      expect(results.first.matchedWord, isNotEmpty);
    });

    test('finds results with prefix matching', () async {
      final results = await repository.search('ال');
      expect(results, isNotEmpty);
    });

    test('returns empty for no matches', () async {
      final results = await repository.search('xYzNoNeXiStEnT');
      expect(results, isEmpty);
    });

    test('handles empty query', () async {
      final results = await repository.search('');
      expect(results, isEmpty);
    });

    test('handles whitespace-only query', () async {
      final results = await repository.search('   ');
      expect(results, isEmpty);
    });
  });

  group('search - ayah number matching', () {
    test('finds ayah by number in surah', () async {
      final results = await repository.search('4');
      final keys = results.map((r) => '${r.surah.number}:${r.ayah.numberInSurah}').toSet();
      expect(keys, contains('1:4'));
    });
  });

  group('search - surah name matching', () {
    test('finds all ayahs in surah by English name', () async {
      final results = await repository.search('ikhlaas');
      expect(results.length, 3);
    });

    test('finds all ayahs in surah by Arabic name', () async {
      final results = await repository.search('الإخلاص');
      expect(results.length, 3);
    });

    test('finds all ayahs in surah by surah number', () async {
      final results = await repository.search('112');
      expect(results.length, 3);
    });
  });

  group('search - normalization', () {
    test('finds ayahs with diacritics removed', () async {
      final results = await repository.search('الرحمن');
      expect(results, isNotEmpty);
    });

    test('finds matches with alef variants', () async {
      final results = await repository.search('الله');
      final keys = results.map((r) => '${r.surah.number}:${r.ayah.numberInSurah}').toSet();
      expect(keys, contains('1:1'));
      expect(keys, contains('112:1'));
      expect(keys, contains('112:2'));
    });
  });
}
