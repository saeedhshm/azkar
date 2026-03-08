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
    final rawId = json['id'];
    final rawCount = json['count'];

    return AdhkarModel(
      id: rawId is num ? rawId.toInt() : 0,
      category: json['category']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      count: rawCount is num ? rawCount.toInt() : 1,
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
