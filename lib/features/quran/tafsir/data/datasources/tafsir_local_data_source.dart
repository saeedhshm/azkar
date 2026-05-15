import '../../domain/entities/tafsir_entry.dart';

class TafsirLocalDataSource {
  final List<TafsirEntry> _cache = [];

  Future<TafsirEntry?> getCachedTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) async {
    for (final entry in _cache) {
      if (entry.surahNumber == surahNumber &&
          entry.ayahNumber == ayahNumber &&
          entry.id.startsWith(sourceId)) {
        return entry;
      }
    }
    return null;
  }

  Future<void> cacheTafsir(TafsirEntry entry) async {
    _cache.removeWhere(
      (e) =>
          e.surahNumber == entry.surahNumber &&
          e.ayahNumber == entry.ayahNumber &&
          e.id.startsWith(entry.id.split('-').first),
    );
    _cache.add(entry);
  }

  Future<void> clearCache() async {
    _cache.clear();
  }
}
