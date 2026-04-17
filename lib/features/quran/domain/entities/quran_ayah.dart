import 'package:equatable/equatable.dart';

class QuranAyah extends Equatable {
  const QuranAyah({
    required this.globalNumber,
    required this.numberInSurah,
    required this.surahNumber,
    required this.juz,
    required this.page,
    required this.text,
  });

  final int globalNumber;
  final int numberInSurah;
  final int surahNumber;
  final int juz;
  final int page;
  final String text;

  @override
  List<Object?> get props => [
    globalNumber,
    numberInSurah,
    surahNumber,
    juz,
    page,
    text,
  ];
}
