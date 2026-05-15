import '../../domain/entities/tafsir_entry.dart';
import '../../domain/entities/tafsir_source.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../datasources/tafsir_local_data_source.dart';
import '../datasources/tafsir_remote_data_source.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  TafsirRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final TafsirRemoteDataSource _remoteDataSource;
  final TafsirLocalDataSource _localDataSource;

  final Map<String, TafsirSource> _sourceMap = {
    for (final source in TafsirSource.defaults) source.id: source,
  };

  @override
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) async {
    final cached = await _localDataSource.getCachedTafsir(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceId: sourceId,
    );
    if (cached != null) return cached;

    final source = _sourceMap[sourceId];
    if (source == null) {
      throw Exception('Unknown tafsir source: $sourceId');
    }

    final entry = await _remoteDataSource.fetchTafsir(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      apiEndpoint: source.apiEndpoint!,
      sourceId: source.id,
      sourceName: source.name,
      sourceLanguage: source.language,
    );

    await _localDataSource.cacheTafsir(entry);
    return entry;
  }

  @override
  Future<List<TafsirEntry>> getMultipleTafsir({
    required int surahNumber,
    required int ayahNumber,
    required List<String> sourceIds,
  }) async {
    final results = <TafsirEntry>[];
    for (final sourceId in sourceIds) {
      try {
        final entry = await getTafsir(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          sourceId: sourceId,
        );
        results.add(entry);
      } catch (_) {
        // Skip failed sources
      }
    }
    return results;
  }
}
