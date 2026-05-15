import 'package:equatable/equatable.dart';

import 'bounds.dart';

class AyahPolygon extends Equatable {
  const AyahPolygon({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.line,
    required this.bounds,
    required this.path,
  });

  final String id;
  final int surah;
  final int ayah;
  final int line;
  final Bounds bounds;
  final String path;

  String get ayahKey => '$surah:$ayah';

  @override
  List<Object> get props => [id, surah, ayah, line, bounds, path];
}
