import 'package:equatable/equatable.dart';

import 'quran_ayah.dart';
import 'quran_surah.dart';

class QuranSearchResult extends Equatable {
  const QuranSearchResult({
    required this.surah,
    required this.ayah,
    this.matchedWord,
  });

  final QuranSurah surah;
  final QuranAyah ayah;
  final String? matchedWord;

  @override
  List<Object?> get props => [surah, ayah, matchedWord];
}
