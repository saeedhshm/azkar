import '../entities/tafsir_entry.dart';
import '../repositories/tafsir_repository.dart';

class GetTafsirUseCase {
  GetTafsirUseCase(this._repository);

  final TafsirRepository _repository;

  Future<TafsirEntry> call({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) {
    return _repository.getTafsir(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceId: sourceId,
    );
  }
}
