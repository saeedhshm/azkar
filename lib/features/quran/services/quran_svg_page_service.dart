import 'dart:async';
import 'dart:io';

import '../data/datasources/quran_page_image_cache_service.dart';
import 'quran_svg_memory_cache.dart';

class QuranSvgPageService {
  QuranSvgPageService(this._cacheService, this._memoryCache);

  final QuranPageImageCacheService _cacheService;
  final QuranSvgMemoryCache _memoryCache;

  QuranSvgMemoryCache get cache => _memoryCache;

  static const int firstPage = QuranPageImageCacheService.firstPage;
  static const int lastPage = QuranPageImageCacheService.lastPage;

  int clampPage(int pageNumber) {
    return pageNumber.clamp(firstPage, lastPage).toInt();
  }

  Future<File> getPageFile(int pageNumber) {
    return _cacheService.getPageFile(clampPage(pageNumber));
  }

  Future<File?> getCachedPageFile(int pageNumber) async {
    final safe = clampPage(pageNumber);
    if (_memoryCache.containsKey(safe)) {
      return null;
    }
    final file = await _cacheService.getPageFile(safe);
    unawaited(_memoryCache.set(safe, file));
    return file;
  }

  void cachePageBytes(int pageNumber, File file) {
    unawaited(_memoryCache.set(clampPage(pageNumber), file));
  }

  void preloadWindow(int currentPage, {int radius = 1}) {
    final safePage = clampPage(currentPage);
    for (
      var pageNumber = safePage - radius;
      pageNumber <= safePage + radius;
      pageNumber++
    ) {
      if (pageNumber < firstPage || pageNumber > lastPage) {
        continue;
      }
      unawaited(_cacheService.precachePage(pageNumber));
      if (!_memoryCache.containsKey(pageNumber)) {
        unawaited(_warmMemory(pageNumber));
      }
    }
  }

  Future<void> _warmMemory(int pageNumber) async {
    try {
      final file = await _cacheService.getPageFile(pageNumber);
      await _memoryCache.set(pageNumber, file);
    } catch (_) {}
  }
}
