import '../../domain/entities/quran_surah.dart';
import 'quran_ayah_model.dart';

class QuranSurahModel extends QuranSurah {
  const QuranSurahModel({
    required super.number,
    required super.name,
    required super.englishName,
    required super.englishNameTranslation,
    required super.revelationType,
    required super.ayahCount,
    required super.ayahs,
  });

  factory QuranSurahModel.fromJson(Map<String, dynamic> json) {
    final number = (json['number'] as num).toInt();
    final ayahsRaw = json['ayahs'];
    final ayahs = ayahsRaw is List
        ? ayahsRaw
              .whereType<Map<String, dynamic>>()
              .map((ayah) => QuranAyahModel.fromJson(ayah, surahNumber: number))
              .toList(growable: false)
        : <QuranAyahModel>[];

    return QuranSurahModel(
      number: number,
      name: json['name']?.toString() ?? '',
      englishName: json['englishName']?.toString() ?? '',
      englishNameTranslation: json['englishNameTranslation']?.toString() ?? '',
      revelationType: json['revelationType']?.toString() ?? '',
      ayahCount: (json['ayahCount'] as num?)?.toInt() ?? ayahs.length,
      ayahs: ayahs,
    );
  }
}
