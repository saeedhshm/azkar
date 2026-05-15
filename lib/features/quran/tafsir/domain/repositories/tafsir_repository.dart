import '../entities/tafsir_entry.dart';

abstract class TafsirRepository {
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  });

  Future<List<TafsirEntry>> getMultipleTafsir({
    required int surahNumber,
    required int ayahNumber,
    required List<String> sourceIds,
  });
}
