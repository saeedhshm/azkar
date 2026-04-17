import 'package:equatable/equatable.dart';

import 'quran_ayah.dart';
import 'quran_surah.dart';

class QuranSearchResult extends Equatable {
  const QuranSearchResult({required this.surah, required this.ayah});

  final QuranSurah surah;
  final QuranAyah ayah;

  @override
  List<Object?> get props => [surah, ayah];
}
