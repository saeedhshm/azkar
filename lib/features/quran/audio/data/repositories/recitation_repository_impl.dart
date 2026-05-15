import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah_timing.dart';
import '../../domain/repositories/recitation_repository.dart';
import '../datasources/recitation_timing_data_source.dart';

class RecitationRepositoryImpl implements RecitationRepository {
  RecitationRepositoryImpl(this._timingDataSource);

  final RecitationTimingDataSource _timingDataSource;

  @override
  List<Reciter> getAvailableReciters() => Reciter.defaults;

  @override
  Reciter get defaultReciter => Reciter.defaults.first;

  @override
  Future<SurahTiming> getTiming(int surahNumber, {required Reciter reciter}) {
    return _timingDataSource.getTiming(surahNumber);
  }
}
