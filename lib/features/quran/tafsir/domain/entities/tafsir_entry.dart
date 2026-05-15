import 'package:equatable/equatable.dart';

class TafsirEntry extends Equatable {
  const TafsirEntry({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.sourceName,
    required this.sourceLanguage,
    required this.text,
  });

  final String id;
  final int surahNumber;
  final int ayahNumber;
  final String sourceName;
  final String sourceLanguage;
  final String text;

  String get ayahKey => '$surahNumber:$ayahNumber';

  @override
  List<Object?> get props => [id, surahNumber, ayahNumber, sourceName, sourceLanguage, text];
}
