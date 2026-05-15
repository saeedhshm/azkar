import 'package:equatable/equatable.dart';

import 'ayah_polygon.dart';

class QuranPage extends Equatable {
  const QuranPage({
    required this.pageNumber,
    required this.mushafId,
    required this.polygons,
  });

  final int pageNumber;
  final int mushafId;
  final List<AyahPolygon> polygons;

  bool get hasPolygons => polygons.isNotEmpty;

  @override
  List<Object> get props => [pageNumber, mushafId, polygons];
}
