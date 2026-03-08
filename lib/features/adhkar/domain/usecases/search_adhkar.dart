import '../entities/adhkar.dart';
import '../repositories/adhkar_repository.dart';

class SearchAdhkarUseCase {
  SearchAdhkarUseCase(this._repository);

  final AdhkarRepository _repository;

  Future<List<Adhkar>> call(String query, {String? category}) {
    return _repository.searchAdhkar(query, category: category);
  }
}
