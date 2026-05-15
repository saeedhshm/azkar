import 'package:equatable/equatable.dart';

class QuranSelectedAyah extends Equatable {
  const QuranSelectedAyah({
    required this.pageNumber,
    required this.polygonId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.lineNumber,
  });

  final int pageNumber;
  final String polygonId;
  final int surahNumber;
  final int ayahNumber;
  final int lineNumber;

  bool get hasValidAyah => surahNumber > 0 && ayahNumber > 0;

  @override
  List<Object> get props => [
    pageNumber,
    polygonId,
    surahNumber,
    ayahNumber,
    lineNumber,
  ];
}
