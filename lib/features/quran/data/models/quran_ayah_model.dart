import '../../domain/entities/quran_ayah.dart';

class QuranAyahModel extends QuranAyah {
  const QuranAyahModel({
    required super.globalNumber,
    required super.numberInSurah,
    required super.surahNumber,
    required super.juz,
    required super.page,
    required super.text,
  });

  factory QuranAyahModel.fromJson(
    Map<String, dynamic> json, {
    required int surahNumber,
  }) {
    return QuranAyahModel(
      globalNumber: (json['number'] as num).toInt(),
      numberInSurah: (json['numberInSurah'] as num).toInt(),
      surahNumber: surahNumber,
      juz: (json['juz'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      text: json['text']?.toString() ?? '',
    );
  }
}
