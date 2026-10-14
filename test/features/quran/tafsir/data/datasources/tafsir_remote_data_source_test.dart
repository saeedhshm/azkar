
import 'package:azkar/features/quran/tafsir/data/datasources/tafsir_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TafsirRemoteDataSource', () {
    const endpoint = 'https://example.test/tafsir';

    TafsirRemoteDataSource buildSource({
      required Future<http.Response> Function(http.Request request) handler,
      Duration? timeout,
    }) {
      return TafsirRemoteDataSource(
        client: MockClient((request) => handler(request)),
        timeout: timeout,
      );
    }

    test('fetches and parses tafsir', () async {
      final source = buildSource(
        handler: (request) async => http.Response(
          '{"tafsir": {"text": "Tafsir text"}}',
          200,
        ),
      );

      final entry = await source.fetchTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        apiEndpoint: endpoint,
        sourceId: 'jalalayn',
        sourceName: 'Jalalayn',
        sourceLanguage: 'ar',
      );

      expect(entry.surahNumber, 1);
      expect(entry.ayahNumber, 1);
      expect(entry.text, 'Tafsir text');
      expect(entry.sourceName, 'Jalalayn');
    });

    test('throws for a non-200 response', () async {
      final source = buildSource(
        handler: (request) async => http.Response('missing', 404),
      );

      await expectLater(
        source.fetchTafsir(
          surahNumber: 2,
          ayahNumber: 255,
          apiEndpoint: endpoint,
          sourceId: 'jalalayn',
          sourceName: 'Jalalayn',
          sourceLanguage: 'ar',
        ),
        throwsA(isA<TafsirException>()),
      );
    });

    test('throws when the response body has no tafsir text', () async {
      final source = buildSource(
        handler: (request) async => http.Response('{"tafsir": {}}', 200),
      );

      await expectLater(
        source.fetchTafsir(
          surahNumber: 1,
          ayahNumber: 1,
          apiEndpoint: endpoint,
          sourceId: 'jalalayn',
          sourceName: 'Jalalayn',
          sourceLanguage: 'ar',
        ),
        throwsA(isA<TafsirException>()),
      );
    });

    test('a stalled request fails within the timeout', () async {
      final source = buildSource(
        handler: (request) async {
          await Future<void>.delayed(const Duration(seconds: 5));
          return http.Response('{"tafsir": {"text": "late"}}', 200);
        },
        timeout: const Duration(milliseconds: 200),
      );

      await expectLater(
        source.fetchTafsir(
          surahNumber: 1,
          ayahNumber: 1,
          apiEndpoint: endpoint,
          sourceId: 'jalalayn',
          sourceName: 'Jalalayn',
          sourceLanguage: 'ar',
        ),
        throwsA(
          isA<TafsirException>().having(
            (e) => e.message,
            'message',
            contains('Timed out'),
          ),
        ),
      );
    });

    test('sanitizes HTML markup out of the parsed text', () async {
      final source = buildSource(
        handler: (request) async => http.Response(
          '{"tafsir": {"text": "h2>Ordering Faith> spending</h2>'
          '<p>Allah orders &amp; encourages faith.</p>"}}',
          200,
        ),
      );

      final entry = await source.fetchTafsir(
        surahNumber: 57,
        ayahNumber: 9,
        apiEndpoint: endpoint,
        sourceId: 'ibn_kathir',
        sourceName: 'Tafsir Ibn Kathir',
        sourceLanguage: 'en',
      );

      expect(entry.text, isNot(contains('<')));
      expect(entry.text, isNot(contains('>')));
      expect(entry.text, contains('Ordering Faith'));
      expect(entry.text, contains('Allah orders & encourages faith.'));
    });

    test('uses the expected ayah key in the request url', () async {
      final requested = <Uri>[];
      final source = buildSource(
        handler: (request) async {
          requested.add(request.url);
          return http.Response('{"tafsir": {"text": "ok"}}', 200);
        },
      );

      await source.fetchTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        apiEndpoint: endpoint,
        sourceId: 'ibn_kathir',
        sourceName: 'Ibn Kathir',
        sourceLanguage: 'ar',
      );

      expect(requested.single.path, endsWith('/tafsir/2:255'));
    });
  });
}
