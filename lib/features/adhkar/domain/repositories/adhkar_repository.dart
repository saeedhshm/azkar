import '../entities/adhkar.dart';
import '../entities/reader_progress.dart';

abstract class AdhkarRepository {
  Future<List<Adhkar>> getAllAdhkar();

  Future<List<Adhkar>> getAdhkarByCategory(String category);

  Future<List<Adhkar>> searchAdhkar(String query, {String? category});

  Future<Set<int>> getFavoriteIds();

  Future<void> toggleFavorite(int adhkarId);

  Future<List<Adhkar>> getFavorites();

  Future<ReaderProgress?> getReaderProgress(String categoryKey);

  Future<void> saveReaderProgress({
    required String categoryKey,
    required int index,
    required int remainingCount,
  });
}
