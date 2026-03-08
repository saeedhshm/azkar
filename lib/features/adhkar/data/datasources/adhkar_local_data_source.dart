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

    _cache = items.map(AdhkarModel.fromJson).toList(growable: false);

    return _cache!;
  }

  List<Map<String, dynamic>> _extractItems(dynamic decoded) {
    if (decoded is List) {
      if (decoded.isEmpty) {
        return const <Map<String, dynamic>>[];
      }

      final first = decoded.first;
      if (first is Map &&
          first.containsKey('name') &&
          first['adhkar'] is List) {
        return _flattenCategoryList(decoded);
      }

      return decoded
          .whereType<Map>()
          .map((json) => Map<String, dynamic>.from(json))
          .toList(growable: false);
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['adhkar'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((json) => Map<String, dynamic>.from(json))
            .toList(growable: false);
      }
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _flattenCategoryList(List<dynamic> categories) {
    final flattened = <Map<String, dynamic>>[];

    for (final rawCategory in categories) {
      if (rawCategory is! Map) {
        continue;
      }

      final category = Map<String, dynamic>.from(rawCategory);
      final categoryName = category['name']?.toString();
      final adhkar = category['adhkar'];

      if (categoryName == null || adhkar is! List) {
        continue;
      }

      for (final rawItem in adhkar) {
        if (rawItem is! Map) {
          continue;
        }

        final item = Map<String, dynamic>.from(rawItem);
        item['category'] = categoryName;
        flattened.add(item);
      }
    }

    return flattened;
  }
}
