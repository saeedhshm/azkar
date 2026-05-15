import '../entities/reciter.dart';
import '../entities/surah_timing.dart';

abstract class RecitationRepository {
  List<Reciter> getAvailableReciters();
  Reciter get defaultReciter;
  Future<SurahTiming> getTiming(int surahNumber, {required Reciter reciter});
}
