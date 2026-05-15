import 'dart:ui';

import '../domain/entities/ayah_polygon.dart';
import '../domain/entities/quran_page.dart';

class _CompiledPageData {
  _CompiledPageData({
    required this.polygons,
    required this.pathMap,
  });

  final List<_CompiledAyahPolygon> polygons;
  final Map<String, Path> pathMap;
}

class QuranPolygonHitTestEngine {
  static const int _maxCachedPages = 12;

  final Map<int, _CompiledPageData> _compiledPages =
      <int, _CompiledPageData>{};
  final List<int> _accessOrder = [];

  AyahPolygon? hitTest(QuranPage page, Offset point) {
    final data = _compiledFor(page);
    for (final polygon in data.polygons.reversed) {
      if (!polygon.rect.contains(point)) {
        continue;
      }
      if (polygon.path.contains(point)) {
        return polygon.source;
      }
    }
    return null;
  }

  bool hasPolygon(QuranPage page, String polygonId) {
    return polygonPath(page, polygonId) != null;
  }

  Path? polygonPath(QuranPage page, String polygonId) {
    final data = _compiledFor(page);
    return data.pathMap[polygonId];
  }

  _CompiledPageData _compiledFor(QuranPage page) {
    final existing = _compiledPages[page.pageNumber];
    if (existing != null) {
      _touch(page.pageNumber);
      return existing;
    }

    _evictIfNeeded();

    final compiled = page.polygons.map(
      (polygon) => _CompiledAyahPolygon(
        source: polygon,
        path: _QuranPolygonPathParser.parse(polygon.path),
      ),
    ).toList(growable: false);

    final pathMap = <String, Path>{};
    for (final p in compiled) {
      pathMap[p.source.id] = p.path;
    }

    final data = _CompiledPageData(polygons: compiled, pathMap: pathMap);
    _compiledPages[page.pageNumber] = data;
    _accessOrder.add(page.pageNumber);
    return data;
  }

  void _touch(int pageNumber) {
    _accessOrder.remove(pageNumber);
    _accessOrder.add(pageNumber);
  }

  void _evictIfNeeded() {
    while (_compiledPages.length >= _maxCachedPages && _accessOrder.isNotEmpty) {
      final oldest = _accessOrder.removeAt(0);
      _compiledPages.remove(oldest);
    }
  }

  void evictPage(int pageNumber) {
    _compiledPages.remove(pageNumber);
    _accessOrder.remove(pageNumber);
  }

  void clearCache() {
    _compiledPages.clear();
    _accessOrder.clear();
  }
}

class _CompiledAyahPolygon {
  const _CompiledAyahPolygon({required this.source, required this.path});

  final AyahPolygon source;
  final Path path;

  Rect get rect => Rect.fromLTWH(
    source.bounds.x,
    source.bounds.y,
    source.bounds.width,
    source.bounds.height,
  );
}

class _QuranPolygonPathParser {
  static Path parse(String raw) {
    final source = raw.trim();
    if (source.isEmpty) {
      return Path();
    }

    if (!_containsSvgCommand(source)) {
      return _parsePointList(source);
    }

    return _parseSvgPath(source);
  }

  static bool _containsSvgCommand(String source) {
    return RegExp(r'[MLHVZmlhvz]').hasMatch(source);
  }

  static Path _parsePointList(String source) {
    final path = Path();
    final pairs = source
        .trim()
        .split(RegExp(r'\s+'))
        .map((token) => token.split(','))
        .where((parts) => parts.length >= 2)
        .map(
          (parts) => Offset(
            double.tryParse(parts[0]) ?? 0,
            double.tryParse(parts[1]) ?? 0,
          ),
        )
        .toList(growable: false);

    if (pairs.isEmpty) {
      return path;
    }

    path.moveTo(pairs.first.dx, pairs.first.dy);
    for (final point in pairs.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  static Path _parseSvgPath(String source) {
    final normalized = source.replaceAll(',', ' ');
    final commandPattern = RegExp(r'[MLHVZmlhvz]|-?\d+(?:\.\d+)?');
    final tokens = commandPattern
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .toList(growable: false);

    final path = Path();
    var index = 0;
    var command = '';
    var current = Offset.zero;
    var subPathStart = Offset.zero;

    while (index < tokens.length) {
      final token = tokens[index];
      if (_isCommand(token)) {
        command = token;
        index++;
        if (command == 'Z' || command == 'z') {
          path.close();
          current = subPathStart;
        }
        continue;
      }

      switch (command) {
        case 'M':
        case 'm':
          final point = _readPoint(
            tokens,
            index,
            relative: command == 'm',
            current: current,
          );
          index += 2;
          current = point;
          subPathStart = point;
          path.moveTo(point.dx, point.dy);
          command = command == 'm' ? 'l' : 'L';
          break;
        case 'L':
        case 'l':
          final point = _readPoint(
            tokens,
            index,
            relative: command == 'l',
            current: current,
          );
          index += 2;
          current = point;
          path.lineTo(point.dx, point.dy);
          break;
        case 'H':
        case 'h':
          final value = double.tryParse(tokens[index]) ?? 0;
          index += 1;
          final dx = command == 'h' ? current.dx + value : value;
          current = Offset(dx, current.dy);
          path.lineTo(current.dx, current.dy);
          break;
        case 'V':
        case 'v':
          final value = double.tryParse(tokens[index]) ?? 0;
          index += 1;
          final dy = command == 'v' ? current.dy + value : value;
          current = Offset(current.dx, dy);
          path.lineTo(current.dx, current.dy);
          break;
        default:
          index++;
          break;
      }
    }

    return path;
  }

  static Offset _readPoint(
    List<String> tokens,
    int index, {
    required bool relative,
    required Offset current,
  }) {
    final dx = double.tryParse(tokens[index]) ?? 0.0;
    final dy = index + 1 < tokens.length
        ? double.tryParse(tokens[index + 1]) ?? 0.0
        : 0.0;
    if (!relative) {
      return Offset(dx, dy);
    }
    return Offset(current.dx + dx, current.dy + dy);
  }

  static bool _isCommand(String token) =>
      token.length == 1 && RegExp(r'[MLHVZmlhvz]').hasMatch(token);
}
