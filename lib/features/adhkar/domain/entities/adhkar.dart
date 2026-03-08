import 'package:equatable/equatable.dart';

class Adhkar extends Equatable {
  const Adhkar({
    required this.id,
    required this.category,
    required this.text,
    required this.count,
    required this.reference,
    required this.description,
  });

  final int id;
  final String category;
  final String text;
  final int count;
  final String reference;
  final String description;

  @override
  List<Object?> get props => [
    id,
    category,
    text,
    count,
    reference,
    description,
  ];
}
