import 'package:equatable/equatable.dart';

import 'quran_ayah.dart';

class QuranSurah extends Equatable {
  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahCount,
    required this.ayahs,
  });

  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int ayahCount;
  final List<QuranAyah> ayahs;

  @override
  List<Object?> get props => [
    number,
    name,
    englishName,
    englishNameTranslation,
    revelationType,
    ayahCount,
    ayahs,
  ];
}
