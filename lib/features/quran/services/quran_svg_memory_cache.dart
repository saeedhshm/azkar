import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuranSvgMemoryCache {
  QuranSvgMemoryCache({int maxEntries = 8}) : _maxEntries = maxEntries;

  final int _maxEntries;
  final Map<int, Uint8List> _bytesCache = {};
  final List<int> _accessOrder = [];

  SvgPicture? get(int pageNumber) {
    final bytes = _bytesCache[pageNumber];
    if (bytes == null) return null;
    _touch(pageNumber);
    return SvgPicture.memory(
      bytes,
      width: 345,
      height: 550,
      fit: BoxFit.fill,
      alignment: Alignment.topCenter,
    );
  }

  Uint8List? getBytes(int pageNumber) {
    final bytes = _bytesCache[pageNumber];
    if (bytes != null) {
      _touch(pageNumber);
      return bytes;
    }
    return null;
  }

  Future<void> set(int pageNumber, File file) async {
    if (_bytesCache.containsKey(pageNumber)) return;
    final bytes = await file.readAsBytes();
    _putBytes(pageNumber, bytes);
  }

  void setBytes(int pageNumber, Uint8List bytes) {
    _putBytes(pageNumber, bytes);
  }

  bool containsKey(int pageNumber) => _bytesCache.containsKey(pageNumber);

  void evict(int pageNumber) {
    _bytesCache.remove(pageNumber);
    _accessOrder.remove(pageNumber);
  }

  void clear() {
    _bytesCache.clear();
    _accessOrder.clear();
  }

  void _putBytes(int pageNumber, Uint8List bytes) {
    if (_bytesCache.length >= _maxEntries &&
        !_bytesCache.containsKey(pageNumber)) {
      _evictOldest();
    }
    _bytesCache[pageNumber] = bytes;
    _accessOrder.remove(pageNumber);
    _accessOrder.add(pageNumber);
  }

  void _touch(int pageNumber) {
    _accessOrder.remove(pageNumber);
    _accessOrder.add(pageNumber);
  }

  void _evictOldest() {
    if (_accessOrder.isEmpty) return;
    final oldest = _accessOrder.removeAt(0);
    _bytesCache.remove(oldest);
  }
}
