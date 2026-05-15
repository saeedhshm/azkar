import '../entities/quran_surah.dart';
import '../repositories/quran_repository.dart';

class GetQuranSurahsUseCase {
  const GetQuranSurahsUseCase(this._repository);

  final QuranRepository _repository;

  Future<List<QuranSurah>> call() {
    return _repository.getSurahs();
  }
}
