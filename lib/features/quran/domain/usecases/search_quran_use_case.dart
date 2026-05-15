import '../entities/quran_search_result.dart';
import '../repositories/quran_repository.dart';

class SearchQuranUseCase {
  const SearchQuranUseCase(this._repository);

  final QuranRepository _repository;

  Future<List<QuranSearchResult>> call(String query) {
    return _repository.search(query);
  }
}
