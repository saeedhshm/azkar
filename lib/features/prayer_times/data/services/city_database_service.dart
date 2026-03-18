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
  static const _fileName = 'cities_db.json';

  List<CityEntry>? _cache;

  Future<bool> isDownloaded() async {
    final file = await _citiesFile();
    return file.exists();
  }

  Future<void> ensureDownloaded() async {
    if (await isDownloaded()) {
      return;
    }
    final online = await _networkService.isOnline();
    if (!online) {
      return;
    }

    final response = await http.get(Uri.parse(_citiesUrl));
    if (response.statusCode == 200) {
      final file = await _citiesFile();
      await file.writeAsString(response.body);
      _cache = null;
    }
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

    final file = await _citiesFile();
    if (!await file.exists()) {
      return const [];
    }

    final raw = await file.readAsString();
    final parsed = await compute(_decodeCities, raw);
    _cache = parsed;
    return parsed;
  }

  Future<File> _citiesFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
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
