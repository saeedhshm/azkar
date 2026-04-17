import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/quran_surah_model.dart';

class QuranLocalDataSource {
  List<QuranSurahModel>? _cache;

  Future<List<QuranSurahModel>> loadSurahs() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final payload = await rootBundle.loadString(AppConstants.quranAssetPath);
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final rawSurahs = decoded['surahs'];
    if (rawSurahs is! List) {
      return const <QuranSurahModel>[];
    }

    final surahs = rawSurahs
        .whereType<Map<String, dynamic>>()
        .map(QuranSurahModel.fromJson)
        .toList(growable: false);
    _cache = surahs;
    return surahs;
  }
}
