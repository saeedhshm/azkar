import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_search_result.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../services/quran_search_text_utils.dart';
import '../datasources/quran_local_data_source.dart';
import '../datasources/quran_search_index.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._localDataSource, this._searchIndex);

  final QuranLocalDataSource _localDataSource;
  final QuranSearchIndex _searchIndex;

  @override
  Future<List<QuranSurah>> getSurahs() async {
    final surahs = await _localDataSource.loadSurahs();
    _buildIndexInBackground(surahs);
    return surahs;
  }

  void _buildIndexInBackground(List<QuranSurah> surahs) {
    if (_searchIndex.isBuilt) return;
    Future.microtask(() {
      _searchIndex.build(surahs);
    });
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
    final normalized = QuranSearchTextUtils.normalize(query);
    if (normalized.isEmpty) {
      return const <QuranSearchResult>[];
    }

    final surahs = await getSurahs();

    if (!_searchIndex.isBuilt) {
      _searchIndex.build(surahs);
    }

    final results = <QuranSearchResult>[];
    final seenKeys = <String>{};
    final numeric = int.tryParse(normalized);

    // Step 1: Use inverted index for text matching (fast word lookup)
    final indexMatches = _searchIndex.search(normalized);
    for (final match in indexMatches) {
      final surah = _findSurah(surahs, match.ref.surahNumber);
      if (surah == null) continue;
      final ayah = _findAyah(surah, match.ref.ayahNumber);
      if (ayah == null) continue;
      final key = '${surah.number}:${ayah.numberInSurah}';
      if (seenKeys.add(key)) {
        results.add(QuranSearchResult(
          surah: surah,
          ayah: ayah,
          matchedWord: match.matchedWord,
        ));
      }
      if (results.length >= QuranSearchIndex.maxResults) break;
    }

    // Step 2: Surah name matching (fast, only 114 surahs)
    for (final surah in surahs) {
      final surahName = QuranSearchTextUtils.normalize(surah.name);
      final englishName = QuranSearchTextUtils.normalize(surah.englishName);
      final englishTranslation = QuranSearchTextUtils.normalize(
        surah.englishNameTranslation,
      );
      final matchesSurah =
          surahName.contains(normalized) ||
          englishName.contains(normalized) ||
          englishTranslation.contains(normalized) ||
          numeric == surah.number;

      if (matchesSurah) {
        for (final ayah in surah.ayahs) {
          final key = '${surah.number}:${ayah.numberInSurah}';
          if (seenKeys.add(key)) {
            results.add(QuranSearchResult(surah: surah, ayah: ayah));
          }
          if (results.length >= QuranSearchIndex.maxResults) break;
        }
        if (results.length >= QuranSearchIndex.maxResults) break;
      }
    }

    // Step 3: Ayah number matching
    if (numeric != null) {
      for (final surah in surahs) {
        for (final ayah in surah.ayahs) {
          if (ayah.numberInSurah == numeric || ayah.globalNumber == numeric) {
            final key = '${surah.number}:${ayah.numberInSurah}';
            if (seenKeys.add(key)) {
              results.add(QuranSearchResult(surah: surah, ayah: ayah));
            }
            if (results.length >= QuranSearchIndex.maxResults) break;
          }
        }
        if (results.length >= QuranSearchIndex.maxResults) break;
      }
    }

    return results;
  }

  QuranSurah? _findSurah(List<QuranSurah> surahs, int number) {
    for (final surah in surahs) {
      if (surah.number == number) return surah;
    }
    return null;
  }

  QuranAyah? _findAyah(QuranSurah surah, int number) {
    for (final ayah in surah.ayahs) {
      if (ayah.numberInSurah == number) return ayah;
    }
    return null;
  }
}
