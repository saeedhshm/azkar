import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/adhkar_model.dart';

class AdhkarLocalDataSource {
  List<AdhkarModel>? _cache;

  Future<List<AdhkarModel>> loadAdhkar() async {
    if (_cache != null) {
      return _cache!;
    }

    final rawJson = await rootBundle.loadString(AppConstants.adhkarAssetPath);
    final decoded = jsonDecode(rawJson);

    final items = _extractItems(decoded);

    _cache = items
        .whereType<Map>()
        .map((json) => AdhkarModel.fromJson(Map<String, dynamic>.from(json)))
        .toList(growable: false);

    return _cache!;
  }

  List<dynamic> _extractItems(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['adhkar'];
      if (nested is List) {
        return nested;
      }
    }

    return <dynamic>[];
  }
}
