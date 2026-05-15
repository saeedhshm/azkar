import '../../domain/entities/bounds.dart';

class BoundsModel extends Bounds {
  const BoundsModel({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  });

  factory BoundsModel.fromJson(Map<String, dynamic> json) {
    return BoundsModel(
      x: _readDouble(json['x']),
      y: _readDouble(json['y']),
      width: _readDouble(json['width']),
      height: _readDouble(json['height']),
    );
  }

  factory BoundsModel.fromPath(String path) {
    final matches = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(path)
        .map((match) => double.parse(match.group(0)!))
        .toList(growable: false);

    if (matches.length < 4) {
      return const BoundsModel(x: 0, y: 0, width: 0, height: 0);
    }

    var minX = matches.first;
    var maxX = matches.first;
    var minY = matches[1];
    var maxY = matches[1];

    for (var index = 0; index < matches.length - 1; index += 2) {
      final x = matches[index];
      final y = matches[index + 1];
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }

    return BoundsModel(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
