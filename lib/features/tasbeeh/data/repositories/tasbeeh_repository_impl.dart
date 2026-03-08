import '../../../../core/storage/local_storage_service.dart';
import '../../domain/repositories/tasbeeh_repository.dart';

class TasbeehRepositoryImpl implements TasbeehRepository {
  TasbeehRepositoryImpl(this._localStorage);

  final LocalStorageService _localStorage;

  @override
  Future<int> getCount() async {
    return _localStorage.getTasbeehCount();
  }

  @override
  Future<void> saveCount(int count) {
    return _localStorage.saveTasbeehCount(count);
  }

  @override
  Future<void> reset() {
    return _localStorage.saveTasbeehCount(0);
  }
}
