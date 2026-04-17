import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QuranPageImageCacheService {
  static const int firstPage = 1;
  static const int lastPage = 604;
  static const String _baseUrl =
      'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/kfgqpc/hafs-wasat';

  Future<File> getPageImage(int pageNumber) async {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    final file = await _pageFile(safePage);
    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    final uri = Uri.parse('$_baseUrl/$safePage.jpg');
    final response = await http.get(uri);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw QuranPageImageException(
        'Unable to download Quran page $safePage. HTTP ${response.statusCode}',
      );
    }

    await file.parent.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<void> precachePage(int pageNumber) async {
    try {
      await getPageImage(pageNumber);
    } catch (_) {
      // Adjacent-page prefetch should never interrupt reading.
    }
  }

  String pageUrl(int pageNumber) {
    final safePage = pageNumber.clamp(firstPage, lastPage).toInt();
    return '$_baseUrl/$safePage.jpg';
  }

  Future<File> _pageFile(int pageNumber) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/quran_pages/hafs_wasat/$pageNumber.jpg');
  }
}

class QuranPageImageException implements Exception {
  const QuranPageImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
