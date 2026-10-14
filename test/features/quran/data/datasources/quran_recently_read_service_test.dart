import 'package:azkar/core/storage/local_storage_service.dart';
import 'package:azkar/features/quran/data/datasources/quran_recently_read_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Storage stub that mimics Hive's dynamic map decoding.
///
/// Hive decodes stored maps as `Map<dynamic, dynamic>` rather than
/// `Map<String, dynamic>`, which is the exact condition these tests verify.
class HiveLikeStorage extends LocalStorageService {
  Object? _value;

  @override
  Object? getRaw(String key) => _value;

  @override
  Future<void> putRaw(String key, Object? value) async {
    _value = value;
  }
}

void main() {
  late HiveLikeStorage storage;
  late QuranRecentlyReadService service;

  setUp(() {
    storage = HiveLikeStorage();
    service = QuranRecentlyReadService(storage);
  });

  group('QuranRecentlyReadService.getAll', () {
    test('reads entries stored as Hive dynamic maps', () {
      // Reproduce Hive decoding: Map<dynamic, dynamic> values.
      storage.putRaw('quran_recently_read', [
        {
          'page': 12,
          'surah': 2,
          'ayah': 255,
          'ts': 1700000000000,
        },
        {
          'page': 34,
          'surah': 2,
          'ayah': 100,
          'ts': 1700000001000,
        },
      ]);

      final entries = service.getAll();

      expect(entries, hasLength(2));
      expect(entries.first.pageNumber, 12);
      expect(entries.first.surahNumber, 2);
      expect(entries.first.ayahNumber, 255);
      expect(entries.first.timestamp, 1700000000000);
      expect(entries.last.pageNumber, 34);
    });

    test('ignores malformed entries instead of failing the whole list', () {
      storage.putRaw('quran_recently_read', [
        {'page': 1, 'surah': 1, 'ayah': 1, 'ts': 1000},
        'not a map',
        {'page': 'invalid', 'surah': 1, 'ayah': 1, 'ts': 1001},
        {'page': 7, 'surah': 1, 'ayah': 3, 'ts': 1002},
      ]);

      final entries = service.getAll();

      expect(entries, hasLength(2));
      expect(entries.map((e) => e.pageNumber), [1, 7]);
    });

    test('returns an empty list when nothing is stored', () {
      expect(service.getAll(), isEmpty);
    });

    test('returns an empty list when the stored value is not a list', () {
      storage.putRaw('quran_recently_read', 'unexpected');

      expect(service.getAll(), isEmpty);
    });
  });

  group('QuranRecentlyReadService.addEntry', () {
    test('persists an entry so it can be read back', () {
      service.addEntry(12, 2, 255);

      final entries = service.getAll();

      expect(entries, hasLength(1));
      expect(entries.single.pageNumber, 12);
      expect(entries.single.surahNumber, 2);
      expect(entries.single.ayahNumber, 255);
      expect(entries.single.timestamp, greaterThan(0));
    });

    test('keeps at most 20 entries', () {
      for (var page = 1; page <= 25; page++) {
        service.addEntry(page, 1, 1);
      }

      final entries = service.getAll();

      expect(entries, hasLength(20));
      expect(entries.first.pageNumber, 25);
      expect(entries.last.pageNumber, 6);
    });

    test('moves an already present page to the front', () {
      service.addEntry(10, 2, 1);
      service.addEntry(20, 3, 1);
      service.addEntry(10, 2, 5);

      final entries = service.getAll();

      expect(entries.map((e) => e.pageNumber), [10, 20]);
      expect(entries.first.ayahNumber, 5);
    });
  });
}
