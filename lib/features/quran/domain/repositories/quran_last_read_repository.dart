abstract class QuranLastReadRepository {
  int? getLastPage();

  Future<void> saveLastPage(int pageNumber);

  ({int surah, int ayah})? getLastAyah();

  Future<void> saveLastAyah({required int surah, required int ayah});
}
