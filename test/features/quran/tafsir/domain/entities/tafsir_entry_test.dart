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
      expect(entry.props, containsAll([
        'jalalayn-1:1', 1, 1, 'تفسير الجلالين', 'ar', 'معنى بسم الله الرحمن الرحيم',
      ]));
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
  });
}
