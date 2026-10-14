import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/local_storage_service.dart';

class QuranPolygonFileCacheService {
  QuranPolygonFileCacheService(
    this._localStorage, {
    http.Client? client,
    Future<Directory> Function()? documentsDirectoryProvider,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _timeout = timeout ?? requestTimeout,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const int firstPage = 1;
  static const int lastPage = 604;
  static const int cacheVersion = 1;
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Download sources tried in order (see [QuranPageImageCacheService]).
  static const List<String> _baseUrls = [
    'https://cdn.quran.ws/svg/pages/v1.1.1/hafs-kfqc',
    'https://raw.githubusercontent.com/quran-ws/quran-svg/main/mushafs/hafs/kfqc/json',
  ];

  final LocalStorageService _localStorage;
  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<String> getPageJson(int pageNumber) async {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    await _ensureCacheVersion();
    final file = await _pageFile(safePage);
    if (!await _isValidFile(file)) {
      Object? lastError;

      for (final url in pageUrls(safePage)) {
        try {
          final response = await _client
              .get(Uri.parse(url))
              .timeout(_timeout);

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(response.bodyBytes, flush: true);
            return file.readAsString();
          }

          lastError = QuranPolygonException(
            'Unable to download Quran polygon page $safePage. HTTP ${response.statusCode}',
          );
        } on TimeoutException {
          lastError = QuranPolygonException(
            'Timed out downloading Quran polygon page $safePage.',
          );
        } catch (e) {
          lastError = e;
        }
      }

      if (lastError is QuranPolygonException) {
        throw lastError;
      }
      throw QuranPolygonException(
        'Unable to download Quran polygon page $safePage (${lastError ?? 'unknown error'}).',
      );
    }
    return file.readAsString();
  }

  Future<void> prefetchPage(int pageNumber) async {
    try {
      await getPageJson(pageNumber);
    } catch (_) {
      // Best-effort warmup for nearby pages.
    }
  }

  /// Releases the HTTP client when this service owns it.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  String pageUrl(int pageNumber) {
    return pageUrls(pageNumber).first;
  }

  /// Every candidate URL for a page, primary source first.
  List<String> pageUrls(int pageNumber) {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    return [
      for (final base in _baseUrls)
        '$base/${safePage.toString().padLeft(3, '0')}.json',
    ];
  }

  Future<void> _ensureCacheVersion() async {
    final storedVersion = _localStorage.getQuranPolygonCacheVersion();
    if (storedVersion == cacheVersion) {
      return;
    }
    await _clearJsonCache();
    await _localStorage.saveQuranPolygonCacheVersion(cacheVersion);
  }

  Future<File> _pageFile(int pageNumber) async {
    final dir = await _jsonDirectory();
    return File('${dir.path}/${pageNumber.toString().padLeft(3, '0')}.json');
  }

  Future<Directory> _jsonDirectory() async {
    final dir = await _documentsDirectoryProvider();
    return Directory('${dir.path}/quran_pages/hafs_polygon_json');
  }

  Future<void> _clearJsonCache() async {
    final dir = await _jsonDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<bool> _isValidFile(File file) async {
    return await file.exists() && await file.length() > 0;
  }
}

class QuranPolygonException implements Exception {
  const QuranPolygonException(this.message);

  final String message;

  @override
  String toString() => message;
}
