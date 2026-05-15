import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/tafsir/data/datasources/tafsir_local_data_source.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_entry.dart';

void main() {
  group('TafsirLocalDataSource', () {
    late TafsirLocalDataSource dataSource;

    setUp(() {
      dataSource = TafsirLocalDataSource();
    });

    test('getCachedTafsir returns null for empty cache', () async {
      final result = await dataSource.getCachedTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        sourceId: 'jalalayn',
      );
      expect(result, isNull);
    });

    test('cacheTafsir and getCachedTafsir round-trip', () async {
      const entry = TafsirEntry(
        id: 'jalalayn-1:1',
        surahNumber: 1,
        ayahNumber: 1,
        sourceName: 'Test',
        sourceLanguage: 'ar',
        text: 'Tafsir text',
      );

      await dataSource.cacheTafsir(entry);
      final result = await dataSource.getCachedTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        sourceId: 'jalalayn',
      );
      expect(result, isNotNull);
      expect(result!.text, 'Tafsir text');
    });

    test('cacheTafsir replaces existing entry for same source', () async {
      const first = TafsirEntry(
        id: 'jalalayn-1:1',
        surahNumber: 1,
        ayahNumber: 1,
        sourceName: 'Test',
        sourceLanguage: 'ar',
        text: 'First',
      );
      const second = TafsirEntry(
        id: 'jalalayn-1:1',
        surahNumber: 1,
        ayahNumber: 1,
        sourceName: 'Test',
        sourceLanguage: 'ar',
        text: 'Second',
      );

      await dataSource.cacheTafsir(first);
      await dataSource.cacheTafsir(second);
      final result = await dataSource.getCachedTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        sourceId: 'jalalayn',
      );
      expect(result!.text, 'Second');
    });

    test('clearCache removes all entries', () async {
      const entry = TafsirEntry(
        id: 'jalalayn-1:1',
        surahNumber: 1,
        ayahNumber: 1,
        sourceName: 'Test',
        sourceLanguage: 'ar',
        text: 'Tafsir text',
      );

      await dataSource.cacheTafsir(entry);
      await dataSource.clearCache();
      final result = await dataSource.getCachedTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        sourceId: 'jalalayn',
      );
      expect(result, isNull);
    });
  });
}
