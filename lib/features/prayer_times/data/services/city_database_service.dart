import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/city_entry.dart';

class CityDatabaseService {
  CityDatabaseService();

  static const _assetPath = 'assets/data/cities_min.json.gz';

  List<CityEntry>? _cache;
  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> isDownloaded() async {
    return true;
  }

  Future<bool> ensureDownloaded() async {
    _lastError = null;
    return true;
  }

  Future<List<CityEntry>> search(String query, {int limit = 25}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final cities = await _loadCities();
    if (cities.isEmpty) {
      return const [];
    }

    final results = <CityEntry>[];
    for (final city in cities) {
      if (city.searchKey.contains(normalized)) {
        results.add(city);
        if (results.length >= limit) {
          break;
        }
      }
    }
    return results;
  }

  Future<List<CityEntry>> _loadCities() async {
    if (_cache != null) {
      return _cache!;
    }

    try {
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List();
      final decoded = gzip.decode(bytes);
      final raw = utf8.decode(decoded);
      final parsed = await compute<String, List<CityEntry>>(_decodeCities, raw);
      _cache = parsed;
      return parsed;
    } catch (e) {
      _lastError = e.toString();
      return const [];
    }
  }
}

List<CityEntry> _decodeCities(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    return const [];
  }

  final cities = <CityEntry>[];
  for (final item in decoded) {
    if (item is! Map) {
      continue;
    }

    final name = (item['name'] ?? '').toString().trim();
    final country = (item['country_name'] ?? '').toString().trim();
    final countryAr = (item['country_ar'] ?? '').toString().trim();
    final countryTr = (item['country_tr'] ?? '').toString().trim();
    final countryId = (item['country_id'] ?? '').toString().trim();
    final cityAr = (item['city_ar'] ?? '').toString().trim();
    final cityTr = (item['city_tr'] ?? '').toString().trim();
    final cityId = (item['city_id'] ?? '').toString().trim();
    final state = (item['state_name'] ?? '').toString().trim();
    final latitude = _parseDouble(item['latitude']);
    final longitude = _parseDouble(item['longitude']);

    if (name.isEmpty ||
        country.isEmpty ||
        latitude == null ||
        longitude == null) {
      continue;
    }

    final searchKey = [
      name.toLowerCase(),
      cityAr.toLowerCase(),
      cityTr.toLowerCase(),
      cityId.toLowerCase(),
      state.toLowerCase(),
      country.toLowerCase(),
      countryAr.toLowerCase(),
      countryTr.toLowerCase(),
      countryId.toLowerCase(),
    ].where((part) => part.isNotEmpty).join(' ');

    cities.add(
      CityEntry(
        name: name,
        country: country,
        state: state.isEmpty ? null : state,
        latitude: latitude,
        longitude: longitude,
        searchKey: searchKey,
      ),
    );
  }

  return cities;
}

double? _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
