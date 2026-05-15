import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/quran_surah.dart';
import '../../domain/entities/ayah_timing.dart';
import '../../domain/entities/surah_timing.dart';

class RecitationTimingDataSource {
  static const double _defaultCharsPerSecond = 14.0;
  static const double _pausePerAyahMs = 200.0;

  static const _timingAssetPath = 'assets/data/timings';

  final Map<int, SurahTiming> _cache = {};

  List<QuranSurah>? _surahs;

  void setSurahs(List<QuranSurah> surahs) {
    _surahs = surahs;
  }

  Future<SurahTiming> getTiming(int surahNumber) async {
    final cached = _cache[surahNumber];
    if (cached != null) return cached;

    final bundled = await _tryLoadBundledTiming(surahNumber);
    if (bundled != null) {
      _cache[surahNumber] = bundled;
      return bundled;
    }

    final estimated = _generateEstimatedTiming(surahNumber);
    _cache[surahNumber] = estimated;
    return estimated;
  }

  Future<SurahTiming?> _tryLoadBundledTiming(int surahNumber) async {
    try {
      final path = '$_timingAssetPath/$surahNumber.json';
      final jsonString = await rootBundle.loadString(path);
      final data = json.decode(jsonString) as List<dynamic>;
      final timings = data.map((item) {
        final map = item as Map<String, dynamic>;
        return AyahTiming(
          surahNumber: surahNumber,
          ayahNumber: (map['ayah'] as num).toInt(),
          startMs: (map['start'] as num).toInt(),
          endMs: (map['end'] as num).toInt(),
        );
      }).toList();
      return SurahTiming(surahNumber: surahNumber, ayahTimings: timings);
    } catch (_) {
      return null;
    }
  }

  SurahTiming _generateEstimatedTiming(int surahNumber) {
    final surah = _surahs?.where((s) => s.number == surahNumber).firstOrNull;
    final ayahs = surah?.ayahs;

    if (ayahs == null || ayahs.isEmpty) {
      return SurahTiming(surahNumber: surahNumber, ayahTimings: []);
    }

    final timings = <AyahTiming>[];
    var currentMs = 0;

    for (var i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      final charCount = ayah.text.replaceAll(' ', '').length;
      final durationMs = (charCount / _defaultCharsPerSecond * 1000).round();
      final startMs = currentMs;
      final endMs = currentMs + durationMs;

      timings.add(AyahTiming(
        surahNumber: surahNumber,
        ayahNumber: ayah.numberInSurah,
        startMs: startMs,
        endMs: endMs,
      ));

      currentMs = endMs + _pausePerAyahMs.round();
    }

    return SurahTiming(surahNumber: surahNumber, ayahTimings: timings);
  }

  void invalidateCache() {
    _cache.clear();
  }
}
