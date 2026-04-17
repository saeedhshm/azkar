import '../../domain/entities/quran_search_result.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  const QuranRepositoryImpl(this._localDataSource);

  final QuranLocalDataSource _localDataSource;

  @override
  Future<List<QuranSurah>> getSurahs() async {
    return _localDataSource.loadSurahs();
  }

  @override
  Future<QuranSurah?> getSurah(int surahNumber) async {
    final surahs = await getSurahs();
    for (final surah in surahs) {
      if (surah.number == surahNumber) {
        return surah;
      }
    }
    return null;
  }

  @override
  Future<List<QuranSearchResult>> search(String query) async {
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return const <QuranSearchResult>[];
    }

    final surahs = await getSurahs();
    final results = <QuranSearchResult>[];
    final numeric = int.tryParse(normalized);

    for (final surah in surahs) {
      final surahName = _normalize(surah.name);
      final englishName = _normalize(surah.englishName);
      final englishTranslation = _normalize(surah.englishNameTranslation);
      final matchesSurah =
          surahName.contains(normalized) ||
          englishName.contains(normalized) ||
          englishTranslation.contains(normalized) ||
          numeric == surah.number;

      for (final ayah in surah.ayahs) {
        final matchesAyahNumber =
            numeric != null &&
            (ayah.numberInSurah == numeric || ayah.globalNumber == numeric);
        final matchesText = _normalize(ayah.text).contains(normalized);

        if (matchesSurah || matchesAyahNumber || matchesText) {
          results.add(QuranSearchResult(surah: surah, ayah: ayah));
        }

        if (results.length >= 80) {
          return results;
        }
      }
    }

    return results;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
