import '../models/quran_page_model.dart';
import '../../services/quran_polygon_file_cache_service.dart';

class QuranPolygonLocalDataSource {
  const QuranPolygonLocalDataSource(this._fileCacheService);

  final QuranPolygonFileCacheService _fileCacheService;

  Future<QuranPageModel> loadPage(int pageNumber) async {
    final source = await _fileCacheService.getPageJson(pageNumber);
    return QuranPageModel.fromJsonString(source, pageNumber: pageNumber);
  }

  Future<void> prefetchPage(int pageNumber) {
    return _fileCacheService.prefetchPage(pageNumber);
  }
}
