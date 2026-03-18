import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/city_entry.dart';
import 'network_service.dart';

class CityDatabaseService {
  CityDatabaseService(this._networkService);

  final NetworkService _networkService;

  static const _citiesUrl =
      'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/cities.json';
  static const _citiesUrlFallback =
      'https://cdn.jsdelivr.net/gh/dr5hn/countries-states-cities-database@master/json/cities.json';
  static const _fileName = 'cities_db.json';

  List<CityEntry>? _cache;

  Future<bool> isDownloaded() async {
    final file = await _citiesFilePath();
    return file.exists();
  }

  Future<bool> ensureDownloaded() async {
    if (await isDownloaded()) {
      return true;
    }
    final urls = [_citiesUrl, _citiesUrlFallback];
    for (final url in urls) {
      final success = await _downloadToFile(url);
      if (success) {
        _cache = null;
        return true;
      }
    }
    return false;
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

    final file = await _citiesFilePath();
    if (!await file.exists()) {
      return const [];
    }

    final raw = await file.readAsString();
    final parsed = await compute<String, List<CityEntry>>(_decodeCities, raw);
    _cache = parsed;
    return parsed;
  }

  static Future<File> _citiesFilePath() async {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }
}

Future<bool> _downloadToFile(String url) async {
  try {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send().timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      return false;
    }

    final file = await CityDatabaseService._citiesFilePath();
    final sink = file.openWrite();
    await response.stream.pipe(sink);
    await sink.flush();
    await sink.close();
    return await file.exists();
  } catch (_) {
    return false;
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
      state.toLowerCase(),
      country.toLowerCase(),
    ].join(' ');

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
