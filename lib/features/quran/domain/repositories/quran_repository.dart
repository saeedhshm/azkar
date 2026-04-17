import '../entities/quran_search_result.dart';
import '../entities/quran_surah.dart';

abstract class QuranRepository {
  Future<List<QuranSurah>> getSurahs();

  Future<QuranSurah?> getSurah(int surahNumber);

  Future<List<QuranSearchResult>> search(String query);
}
