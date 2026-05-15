import '../entities/quran_page.dart';

abstract class QuranPolygonRepository {
  Future<QuranPage> getPagePolygons(int pageNumber);

  QuranPage? getCachedPagePolygons(int pageNumber);

  Future<void> warmUpWindow(int pageNumber, {int radius = 1});

  void clearMemoryCache();
}
