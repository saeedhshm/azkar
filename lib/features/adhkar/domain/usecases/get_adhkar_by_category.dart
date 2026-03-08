import '../entities/adhkar.dart';
import '../repositories/adhkar_repository.dart';

class GetAdhkarByCategoryUseCase {
  GetAdhkarByCategoryUseCase(this._repository);

  final AdhkarRepository _repository;

  Future<List<Adhkar>> call(String categoryKey) {
    return _repository.getAdhkarByCategory(categoryKey);
  }
}
