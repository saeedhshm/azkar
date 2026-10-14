import 'package:equatable/equatable.dart';

enum TafsirSourceType { online, offline }

class TafsirSource extends Equatable {
  const TafsirSource({
    required this.id,
    required this.name,
    required this.language,
    required this.type,
    this.apiEndpoint,
  });

  final String id;
  final String name;
  final String language;
  final TafsirSourceType type;
  final String? apiEndpoint;

  static const List<TafsirSource> defaults = [
    TafsirSource(
      id: 'jalalayn',
      name: 'التفسير الميسر',
      language: 'ar',
      type: TafsirSourceType.online,
      // Quran.com resource 16 is an Arabic tafsir (Muyassar).
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/16/by_ayah',
    ),
    TafsirSource(
      id: 'ibn_kathir',
      name: 'Tafsir Ibn Kathir',
      language: 'en',
      type: TafsirSourceType.online,
      // Quran.com resource 169 is the English Ibn Kathir tafsir.
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/169/by_ayah',
    ),
    TafsirSource(
      id: 'muyassar',
      name: 'تفسير ابن كثير',
      language: 'ar',
      type: TafsirSourceType.online,
      // Quran.com resource 14 is the Arabic Ibn Kathir tafsir.
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/14/by_ayah',
    ),
    TafsirSource(
      id: 'saadi',
      name: 'Tafsir As-Sa\'di',
      language: 'ar',
      type: TafsirSourceType.online,
      // Quran.com resource 91 is the Arabic Al-Sa'di tafsir.
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/91/by_ayah',
    ),
  ];

  @override
  List<Object?> get props => [id, name, language, type, apiEndpoint];

  /// Default source id matching the app's language.
  ///
  /// Only Arabic and English tafsirs exist, so English maps to Ibn Kathir
  /// and every other app language falls back to Jalalayn (Arabic).
  static String defaultForLanguage(String languageCode) {
    if (languageCode == 'en') {
      return 'ibn_kathir';
    }
    return 'jalalayn';
  }

  /// Sources available in the app's language.
  ///
  /// The selector must only offer these: showing an English tafsir inside an
  /// Arabic app (or vice versa) is the mismatch users report. Languages
  /// without their own tafsir fall back to the Arabic ones.
  static List<TafsirSource> sourcesForLanguage(String languageCode) {
    final target = languageCode == 'en' ? 'en' : 'ar';
    final matches = defaults
        .where((source) => source.language == target)
        .toList();
    // Never strand the UI without a choice, even if data changes.
    return matches.isEmpty ? List.of(defaults) : matches;
  }
}
