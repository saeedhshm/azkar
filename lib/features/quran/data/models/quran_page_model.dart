import 'dart:convert';

import '../../domain/entities/quran_page.dart';
import 'ayah_polygon_model.dart';

class QuranPageModel extends QuranPage {
  const QuranPageModel({
    required super.pageNumber,
    required super.mushafId,
    required super.polygons,
  });

  factory QuranPageModel.fromJsonString(
    String source, {
    required int pageNumber,
  }) {
    final decoded = jsonDecode(source);

    if (decoded is Map<String, dynamic>) {
      final rawPolygons = decoded['polygons'];
      if (rawPolygons is! List) {
        throw const FormatException('Invalid polygon JSON: missing polygons');
      }
      return QuranPageModel(
        pageNumber: _readInt(decoded['page'], fallback: pageNumber),
        mushafId: _readInt(decoded['mushaf_id'], fallback: 1),
        polygons: List<AyahPolygonModel>.generate(rawPolygons.length, (index) {
          final item = rawPolygons[index];
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid polygon item');
          }
          return AyahPolygonModel.fromStructuredJson(
            item,
            pageNumber: pageNumber,
            fallbackIndex: index,
          );
        }, growable: false),
      );
    }

    if (decoded is List) {
      return QuranPageModel(
        pageNumber: pageNumber,
        mushafId: 1,
        polygons: List<AyahPolygonModel>.generate(decoded.length, (index) {
          final item = decoded[index];
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid polygon item');
          }
          return AyahPolygonModel.fromLegacyJson(
            item,
            pageNumber: pageNumber,
            fallbackIndex: index,
          );
        }, growable: false),
      );
    }

    throw const FormatException('Unsupported polygon JSON format');
  }
}

int _readInt(Object? value, {required int fallback}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
