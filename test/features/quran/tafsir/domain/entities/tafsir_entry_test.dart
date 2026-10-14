import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_entry.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_source.dart';

void main() {
  group('TafsirEntry', () {
    const entry = TafsirEntry(
      id: 'jalalayn-1:1',
      surahNumber: 1,
      ayahNumber: 1,
      sourceName: 'تفسير الجلالين',
      sourceLanguage: 'ar',
      text: 'معنى بسم الله الرحمن الرحيم',
    );

    test('has correct ayahKey', () {
      expect(entry.ayahKey, '1:1');
    });

    test('props are correct', () {
      expect(
        entry.props,
        containsAll([
          'jalalayn-1:1',
          1,
          1,
          'تفسير الجلالين',
          'ar',
          'معنى بسم الله الرحمن الرحيم',
        ]),
      );
    });
  });

  group('TafsirSource', () {
    test('defaults list is not empty', () {
      expect(TafsirSource.defaults, isNotEmpty);
    });

    test('defaults has expected sources', () {
      final ids = TafsirSource.defaults.map((s) => s.id).toSet();
      expect(ids, containsAll(['jalalayn', 'ibn_kathir', 'muyassar', 'saadi']));
    });

    test('all sources have required fields', () {
      for (final source in TafsirSource.defaults) {
        expect(source.id, isNotEmpty);
        expect(source.name, isNotEmpty);
        expect(source.language, isNotEmpty);
        expect(source.apiEndpoint, isNotEmpty);
      }
    });

    test('online sources have apiEndpoint', () {
      for (final source in TafsirSource.defaults) {
        expect(source.apiEndpoint, isNotEmpty);
      }
    });

    test('sources use Quran.com resources in their declared language', () {
      final endpoints = {
        for (final source in TafsirSource.defaults)
          source.id: source.apiEndpoint,
      };

      expect(endpoints['ibn_kathir'], contains('/tafsirs/169/'));
      expect(endpoints['jalalayn'], contains('/tafsirs/16/'));
      expect(endpoints['muyassar'], contains('/tafsirs/14/'));
      expect(endpoints['saadi'], contains('/tafsirs/91/'));
      expect(
        TafsirSource.sourcesForLanguage(
          'en',
        ).every((source) => source.language == 'en'),
        isTrue,
      );
      expect(
        TafsirSource.sourcesForLanguage(
          'ar',
        ).every((source) => source.language == 'ar'),
        isTrue,
      );
    });

    test('default source matches the English app language', () {
      expect(TafsirSource.defaultForLanguage('en'), 'ibn_kathir');
    });

    test('default source falls back to Arabic for other app languages', () {
      for (final code in ['ar', 'tr', 'id']) {
        expect(
          TafsirSource.defaultForLanguage(code),
          'jalalayn',
          reason: 'no $code tafsir exists, Arabic is the fallback',
        );
      }
    });

    test('default source id always refers to a known source', () {
      final ids = TafsirSource.defaults.map((s) => s.id).toSet();
      for (final code in ['en', 'ar', 'tr', 'id', 'fr']) {
        expect(ids, contains(TafsirSource.defaultForLanguage(code)));
      }
    });

    test('sources for English are English only', () {
      final sources = TafsirSource.sourcesForLanguage('en');

      expect(sources, isNotEmpty);
      expect(sources.map((s) => s.language).toSet(), {'en'});
      expect(sources.map((s) => s.id), contains('ibn_kathir'));
    });

    test('sources for Arabic exclude English tafsirs', () {
      final sources = TafsirSource.sourcesForLanguage('ar');

      expect(sources.map((s) => s.language).toSet(), {'ar'});
      expect(
        sources.map((s) => s.id),
        containsAll(['jalalayn', 'muyassar', 'saadi']),
      );
      expect(sources.map((s) => s.id), isNot(contains('ibn_kathir')));
    });

    test('languages without their own tafsir fall back to Arabic', () {
      for (final code in ['tr', 'id', 'fr']) {
        final sources = TafsirSource.sourcesForLanguage(code);

        expect(sources, isNotEmpty);
        expect(sources.map((s) => s.language).toSet(), {'ar'});
      }
    });
  });
}
