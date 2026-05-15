import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/local_storage_service.dart';

class QuranPolygonFileCacheService {
  QuranPolygonFileCacheService(this._localStorage, {http.Client? client})
    : _client = client ?? http.Client();

  static const int firstPage = 1;
  static const int lastPage = 604;
  static const int cacheVersion = 1;
  static const String _baseUrl =
      'https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/hafs/json';

  final LocalStorageService _localStorage;
  final http.Client _client;

  Future<String> getPageJson(int pageNumber) async {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    await _ensureCacheVersion();
    final file = await _pageFile(safePage);
    if (!await _isValidFile(file)) {
      final response = await _client.get(Uri.parse(pageUrl(safePage)));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw QuranPolygonException(
          'Unable to download Quran polygon page $safePage. HTTP ${response.statusCode}',
        );
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes, flush: true);
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

  String pageUrl(int pageNumber) {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    return '$_baseUrl/${safePage.toString().padLeft(3, '0')}.json';
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
    final dir = await getApplicationDocumentsDirectory();
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
