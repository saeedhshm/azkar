import '../../domain/entities/ayah_polygon.dart';
import 'bounds_model.dart';

class AyahPolygonModel extends AyahPolygon {
  const AyahPolygonModel({
    required super.id,
    required super.surah,
    required super.ayah,
    required super.line,
    required super.bounds,
    required super.path,
  });

  factory AyahPolygonModel.fromStructuredJson(
    Map<String, dynamic> json, {
    required int pageNumber,
    required int fallbackIndex,
  }) {
    final path = (json['path'] ?? '').toString().trim();
    return AyahPolygonModel(
      id: (json['id']?.toString().trim().isNotEmpty ?? false)
          ? json['id'].toString()
          : _fallbackId(
              pageNumber: pageNumber,
              index: fallbackIndex,
              surah: _readInt(json['surah']),
              ayah: _readInt(json['ayah']),
            ),
      surah: _readInt(json['surah']),
      ayah: _readInt(json['ayah']),
      line: _readInt(json['line'], fallback: fallbackIndex + 1),
      bounds: json['bounds'] is Map<String, dynamic>
          ? BoundsModel.fromJson(json['bounds'] as Map<String, dynamic>)
          : BoundsModel.fromPath(path),
      path: path,
    );
  }

  factory AyahPolygonModel.fromLegacyJson(
    Map<String, dynamic> json, {
    required int pageNumber,
    required int fallbackIndex,
  }) {
    final path = (json['polygon'] ?? json['path'] ?? '').toString().trim();
    final surah = _readInt(json['surahNumber'] ?? json['surah']);
    final ayah = _readInt(json['ayahNumber'] ?? json['ayah']);
    return AyahPolygonModel(
      id: _fallbackId(
        pageNumber: pageNumber,
        index: fallbackIndex,
        surah: surah,
        ayah: ayah,
      ),
      surah: surah,
      ayah: ayah,
      line: _readInt(json['line'], fallback: fallbackIndex + 1),
      bounds: BoundsModel.fromPath(path),
      path: path,
    );
  }
}

String _fallbackId({
  required int pageNumber,
  required int index,
  required int surah,
  required int ayah,
}) {
  final page = pageNumber.toString().padLeft(3, '0');
  return 'page-$page-s$surah-a$ayah-p${index + 1}';
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
