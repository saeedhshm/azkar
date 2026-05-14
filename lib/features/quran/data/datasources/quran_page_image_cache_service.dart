import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/storage/local_storage_service.dart';

class QuranPageImageCacheService {
  QuranPageImageCacheService(this._localStorage, {http.Client? client})
    : _client = client ?? http.Client();

  static const int firstPage = 1;
  static const int lastPage = 604;
  static const int cacheVersion = 3;
  static const String _baseUrl =
      'https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/hafs/svg';

  final LocalStorageService _localStorage;
  final http.Client _client;

  Future<void> ensurePagesCached({
    void Function(QuranPagesDownloadProgress progress)? onProgress,
  }) async {
    await _deleteLegacyCacheIfNeeded();

    final storedVersion = _localStorage.getQuranPagesCacheVersion();
    if (storedVersion != null && storedVersion != cacheVersion) {
      await _clearSvgCache();
      await _localStorage.clearQuranPagesCacheVersion();
    }

    final downloadedCount = await _countValidPages();

    if (storedVersion == cacheVersion && downloadedCount == lastPage) {
      return;
    }

    onProgress?.call(
      const QuranPagesDownloadProgress(
        downloadedCount: 0,
        totalCount: lastPage,
      ),
    );

    var processedCount = 0;
    for (var pageNumber = firstPage; pageNumber <= lastPage; pageNumber++) {
      final file = await _pageFile(pageNumber);
      if (!await _isValidPageFile(file)) {
        final uri = Uri.parse(pageUrl(pageNumber));
        final response = await _client.get(uri);
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          throw QuranPageImageException(
            'Unable to download Quran page $pageNumber. HTTP ${response.statusCode}',
          );
        }

        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes, flush: true);
      }

      processedCount++;
      onProgress?.call(
        QuranPagesDownloadProgress(
          downloadedCount: processedCount,
          totalCount: lastPage,
        ),
      );
    }

    await _localStorage.saveQuranPagesCacheVersion(cacheVersion);
  }

  Future<File> getPageFile(int pageNumber) async {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    final file = await _pageFile(safePage);
    if (await _isValidPageFile(file)) {
      return file;
    }

    throw QuranPageImageException(
      'Quran page $safePage is not available offline yet.',
    );
  }

  Future<void> precachePage(int pageNumber) async {
    try {
      await getPageFile(pageNumber);
    } catch (_) {
      // Adjacent-page validation should never interrupt reading.
    }
  }

  String pageUrl(int pageNumber) {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    return '$_baseUrl/${_pageFileName(safePage)}';
  }

  Future<File> _pageFile(int pageNumber) async {
    final dir = await _svgPagesDirectory();
    return File('${dir.path}/${_pageFileName(pageNumber)}');
  }

  Future<Directory> _svgPagesDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/quran_pages/quran_svg');
  }

  Future<Directory> _legacyJpgDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/quran_pages/hafs_wasat');
  }

  Future<void> _deleteLegacyCacheIfNeeded() async {
    final legacyDir = await _legacyJpgDirectory();
    if (await legacyDir.exists()) {
      await legacyDir.delete(recursive: true);
    }
  }

  Future<void> _clearSvgCache() async {
    final dir = await _svgPagesDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<int> _countValidPages() async {
    var count = 0;
    for (var pageNumber = firstPage; pageNumber <= lastPage; pageNumber++) {
      final file = await _pageFile(pageNumber);
      if (await _isValidPageFile(file)) {
        count++;
      }
    }
    return count;
  }

  Future<bool> _isValidPageFile(File file) async {
    return await file.exists() && await file.length() > 0;
  }

  String _pageFileName(int pageNumber) {
    return '${pageNumber.toString().padLeft(3, '0')}.svg';
  }
}

class QuranPagesDownloadProgress {
  const QuranPagesDownloadProgress({
    required this.downloadedCount,
    required this.totalCount,
  });

  final int downloadedCount;
  final int totalCount;

  double get ratio {
    if (totalCount <= 0) {
      return 0;
    }
    return (downloadedCount / totalCount).clamp(0.0, 1.0);
  }

  int get percentage => (ratio * 100).round().clamp(0, 100);
}

class QuranPageImageException implements Exception {
  const QuranPageImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
