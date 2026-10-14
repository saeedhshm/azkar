import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/storage/local_storage_service.dart';

class QuranPageImageCacheService {
  QuranPageImageCacheService(
    this._localStorage, {
    http.Client? client,
    Future<Directory> Function()? documentsDirectoryProvider,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _timeout = timeout ?? downloadTimeout,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const int firstPage = 1;
  static const int lastPage = 604;
  static const int cacheVersion = 3;
  static const Duration downloadTimeout = Duration(seconds: 30);

  /// Download sources tried in order.
  ///
  /// The upstream repository moved from `quranpedia/quran-svg` to
  /// `quran-ws/quran-svg` with a new layout, so the old single URL 404s. The
  /// versioned CDN is primary (immutable files, per-client compression); the
  /// GitHub raw URL is the fallback.
  static const List<String> _baseUrls = [
    'https://cdn.quran.ws/svg/pages/v1.1.1/hafs-kfqc',
    'https://raw.githubusercontent.com/quran-ws/quran-svg/main/mushafs/hafs/kfqc/svg',
  ];

  final LocalStorageService _localStorage;
  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;
  final Future<Directory> Function() _documentsDirectoryProvider;

  /// Ensures every page is cached, downloading any missing page.
  ///
  /// This is no longer required for the app to start; it is used by the
  /// optional background prefetch and by tests.
  Future<void> ensurePagesCached({
    void Function(QuranPagesDownloadProgress progress)? onProgress,
    bool Function()? shouldContinue,
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
      if (shouldContinue != null && !shouldContinue()) {
        return;
      }

      final file = await _pageFile(pageNumber);
      if (!await _isValidPageFile(file)) {
        await _downloadPage(pageNumber, file);
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

  /// Returns the cached page file, downloading it when missing.
  ///
  /// Cached pages are always served from disk. A failed download leaves the
  /// cache untouched so a previously downloaded page is never discarded.
  Future<File> getPageFile(int pageNumber) async {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    final file = await _pageFile(safePage);

    if (await _isValidPageFile(file)) {
      return file;
    }

    await _downloadPage(safePage, file);
    return file;
  }

  /// Returns the cached page file without triggering any download.
  ///
  /// Returns `null` when the page is not available offline yet.
  Future<File?> getCachedPageFile(int pageNumber) async {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    final file = await _pageFile(safePage);

    if (await _isValidPageFile(file)) {
      return file;
    }
    return null;
  }

  Future<void> _downloadPage(int pageNumber, File file) async {
    Object? lastError;

    for (final url in pageUrls(pageNumber)) {
      try {
        final response = await _client
            .get(Uri.parse(url))
            .timeout(_timeout);

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(response.bodyBytes, flush: true);
          return;
        }

        lastError = QuranPageImageException(
          'Unable to download Quran page $pageNumber. HTTP ${response.statusCode}',
        );
      } on TimeoutException {
        lastError = QuranPageImageException(
          'Timed out downloading Quran page $pageNumber.',
        );
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError is QuranPageImageException) {
      throw lastError;
    }
    throw QuranPageImageException(
      'Unable to download Quran page $pageNumber (${lastError ?? 'unknown error'}).',
    );
  }

  Future<void> precachePage(int pageNumber) async {
    try {
      await getPageFile(pageNumber);
    } catch (_) {
      // Adjacent-page warmup should never interrupt reading.
    }
  }

  String pageUrl(int pageNumber) {
    return pageUrls(pageNumber).first;
  }

  /// Every candidate URL for a page, primary source first.
  List<String> pageUrls(int pageNumber) {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    return [
      for (final base in _baseUrls) '$base/${_pageFileName(safePage)}',
    ];
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<File> _pageFile(int pageNumber) async {
    final dir = await _svgPagesDirectory();
    return File('${dir.path}/${_pageFileName(pageNumber)}');
  }

  Future<Directory> _svgPagesDirectory() async {
    final dir = await _documentsDirectoryProvider();
    return Directory('${dir.path}/quran_pages/quran_svg');
  }

  Future<Directory> _legacyJpgDirectory() async {
    final dir = await _documentsDirectoryProvider();
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
