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
      name: 'تفسير الجلالين',
      language: 'ar',
      type: TafsirSourceType.online,
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/169/by_ayah',
    ),
    TafsirSource(
      id: 'ibn_kathir',
      name: 'Tafsir Ibn Kathir',
      language: 'en',
      type: TafsirSourceType.online,
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/171/by_ayah',
    ),
    TafsirSource(
      id: 'muyassar',
      name: 'التفسير الميسر',
      language: 'ar',
      type: TafsirSourceType.online,
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/168/by_ayah',
    ),
    TafsirSource(
      id: 'saadi',
      name: 'Tafsir As-Sa\'di',
      language: 'ar',
      type: TafsirSourceType.online,
      apiEndpoint: 'https://api.quran.com/api/v4/tafsirs/170/by_ayah',
    ),
  ];

  @override
  List<Object?> get props => [id, name, language, type, apiEndpoint];
}
