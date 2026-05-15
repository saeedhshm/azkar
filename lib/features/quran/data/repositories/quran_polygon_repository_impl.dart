import '../../domain/entities/quran_page.dart';
import '../../domain/repositories/quran_polygon_repository.dart';
import '../datasources/quran_polygon_local_data_source.dart';

class QuranPolygonRepositoryImpl implements QuranPolygonRepository {
  QuranPolygonRepositoryImpl(this._localDataSource);

  final QuranPolygonLocalDataSource _localDataSource;
  final Map<int, QuranPage> _memoryCache = <int, QuranPage>{};

  @override
  Future<QuranPage> getPagePolygons(int pageNumber) async {
    final cached = _memoryCache[pageNumber];
    if (cached != null) {
      return cached;
    }

    final page = await _localDataSource.loadPage(pageNumber);
    _memoryCache[pageNumber] = page;
    return page;
  }

  @override
  QuranPage? getCachedPagePolygons(int pageNumber) {
    return _memoryCache[pageNumber];
  }

  @override
  Future<void> warmUpWindow(int pageNumber, {int radius = 1}) async {
    for (
      var targetPage = pageNumber - radius;
      targetPage <= pageNumber + radius;
      targetPage++
    ) {
      if (targetPage < 1 ||
          targetPage > 604 ||
          _memoryCache.containsKey(targetPage)) {
        continue;
      }
      try {
        final page = await _localDataSource.loadPage(targetPage);
        _memoryCache[targetPage] = page;
      } catch (_) {
        // Keep warmup best-effort only.
      }
    }
  }

  @override
  void clearMemoryCache() {
    _memoryCache.clear();
  }
}
