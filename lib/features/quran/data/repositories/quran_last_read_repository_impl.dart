import '../../../../core/storage/local_storage_service.dart';
import '../../domain/repositories/quran_last_read_repository.dart';

class QuranLastReadRepositoryImpl implements QuranLastReadRepository {
  QuranLastReadRepositoryImpl(this._localStorage);

  final LocalStorageService _localStorage;

  @override
  int? getLastPage() {
    return _localStorage.getQuranLastPage();
  }

  @override
  Future<void> saveLastPage(int pageNumber) {
    return _localStorage.saveQuranLastPage(pageNumber);
  }

  @override
  ({int surah, int ayah})? getLastAyah() {
    return _localStorage.getQuranLastReadAyah();
  }

  @override
  Future<void> saveLastAyah({required int surah, required int ayah}) {
    return _localStorage.saveQuranLastReadAyah(surah: surah, ayah: ayah);
  }
}
