import '../../domain/entities/adhkar.dart';

class AdhkarModel extends Adhkar {
  const AdhkarModel({
    required super.id,
    required super.category,
    required super.text,
    required super.count,
    required super.reference,
    required super.description,
  });

  factory AdhkarModel.fromJson(Map<String, dynamic> json) {
    return AdhkarModel(
      id: json['id'] as int,
      category: json['category'] as String,
      text: json['text'] as String,
      count: (json['count'] as num).toInt(),
      reference: (json['reference'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}
