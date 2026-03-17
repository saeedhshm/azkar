import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/adhkar.dart';
import '../../domain/entities/reader_progress.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../datasources/adhkar_local_data_source.dart';

class AdhkarRepositoryImpl implements AdhkarRepository {
  AdhkarRepositoryImpl({
    required AdhkarLocalDataSource localDataSource,
    required LocalStorageService localStorage,
  }) : _localDataSource = localDataSource,
       _localStorage = localStorage;

  final AdhkarLocalDataSource _localDataSource;
  final LocalStorageService _localStorage;

  @override
  Future<List<Adhkar>> getAllAdhkar() async {
    return _localDataSource.loadAdhkar();
  }

  @override
  Future<List<Adhkar>> getAdhkarByCategory(String category) async {
    final all = await getAllAdhkar();
    return all
        .where(
          (adhkar) => adhkar.category.toLowerCase() == category.toLowerCase(),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Adhkar>> searchAdhkar(String query, {String? category}) async {
    final normalizedQuery = query.trim().toLowerCase();
    final source = category == null || category.isEmpty
        ? await getAllAdhkar()
        : await getAdhkarByCategory(category);

    if (normalizedQuery.isEmpty) {
      return source;
    }

    return source
        .where((adhkar) {
          return adhkar.text.toLowerCase().contains(normalizedQuery) ||
              adhkar.reference.toLowerCase().contains(normalizedQuery) ||
              adhkar.description.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  @override
  Future<Set<int>> getFavoriteIds() async {
    return _localStorage.getFavoriteIds();
  }

  @override
  Future<void> toggleFavorite(int adhkarId) async {
    final favorites = _localStorage.getFavoriteIds();
    if (!favorites.remove(adhkarId)) {
      favorites.add(adhkarId);
    }
    await _localStorage.saveFavoriteIds(favorites);
  }

  @override
  Future<List<Adhkar>> getFavorites() async {
    final favorites = _localStorage.getFavoriteIds();
    final all = await getAllAdhkar();
    return all.where((adhkar) => favorites.contains(adhkar.id)).toList();
  }

  @override
  Future<Map<int, int>> getAdhkarProgressMap() async {
    return _localStorage.getAdhkarProgressMap();
  }

  @override
  Future<void> saveAdhkarRemainingCount({
    required int adhkarId,
    required int remainingCount,
  }) {
    return _localStorage.saveAdhkarRemainingCount(
      adhkarId: adhkarId,
      remainingCount: remainingCount,
    );
  }

  @override
  Future<void> resetCategoryProgress(String categoryKey) async {
    final items = await getAdhkarByCategory(categoryKey);
    final ids = items.map((item) => item.id).toSet();
    await _localStorage.removeAdhkarProgressForIds(ids);
    await _localStorage.clearReaderProgress(categoryKey);
  }

  @override
  Future<ReaderProgress?> getReaderProgress(String categoryKey) async {
    final raw = _localStorage.getReaderProgress(categoryKey);
    if (raw == null) {
      return null;
    }

    final index = raw['index'];
    final remaining = raw['remainingCount'];

    if (index is! int || remaining is! int) {
      return null;
    }

    return ReaderProgress(index: index, remainingCount: remaining);
  }

  @override
  Future<void> saveReaderProgress({
    required String categoryKey,
    required int index,
    required int remainingCount,
  }) {
    return _localStorage.saveReaderProgress(
      categoryKey: categoryKey,
      index: index,
      remainingCount: remainingCount,
    );
  }
}
