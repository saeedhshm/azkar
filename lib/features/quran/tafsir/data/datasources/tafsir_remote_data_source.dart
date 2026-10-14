import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/tafsir_entry.dart';
import '../../utils/tafsir_text_sanitizer.dart';

class TafsirRemoteDataSource {
  TafsirRemoteDataSource({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _timeout = timeout ?? requestTimeout;

  static const Duration requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;

  Future<TafsirEntry> fetchTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String apiEndpoint,
    required String sourceId,
    required String sourceName,
    required String sourceLanguage,
  }) async {
    final ayahKey = '$surahNumber:$ayahNumber';
    final url = '$apiEndpoint/$ayahKey';

    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      throw TafsirException(
        'Timed out loading tafsir for surah $surahNumber ayah $ayahNumber.',
      );
    }

    if (response.statusCode != 200) {
      throw TafsirException('Failed to load tafsir: ${response.statusCode}');
    }

    return _parseTafsirResponse(
      response.body,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceId: sourceId,
      sourceName: sourceName,
      sourceLanguage: sourceLanguage,
    );
  }

  TafsirEntry _parseTafsirResponse(
    String body, {
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
    required String sourceName,
    required String sourceLanguage,
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final tafsir = json['tafsir'] as Map<String, dynamic>?;
    if (tafsir == null) throw TafsirException('Invalid tafsir response');

    final text = tafsir['text'] as String?;
    if (text == null || text.isEmpty) {
      throw TafsirException('Tafsir text is empty');
    }

    return TafsirEntry(
      id: '$sourceId-$surahNumber:$ayahNumber',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceName: sourceName,
      sourceLanguage: sourceLanguage,
      // Sanitize once here so the cache and every display get clean text.
      text: TafsirTextSanitizer.clean(text),
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class TafsirException implements Exception {
  TafsirException(this.message);
  final String message;
  @override
  String toString() => message;
}
