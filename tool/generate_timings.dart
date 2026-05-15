import 'dart:convert';
import 'dart:io';

const _defaultCharsPerSecond = 14.0;
const _pausePerAyahMs = 200.0;

void main() async {
  final file = File('assets/data/quran_uthmani.json');
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final surahs = json['surahs'] as List<dynamic>;
  final outDir = Directory('assets/data/timings');
  if (!outDir.existsSync()) outDir.createSync();

  for (final surahData in surahs) {
    final surah = surahData as Map<String, dynamic>;
    final number = surah['number'] as int;
    final ayahs = surah['ayahs'] as List<dynamic>;

    final timings = <Map<String, int>>[];
    var currentMs = 0;

    for (final ayahData in ayahs) {
      final ayah = ayahData as Map<String, dynamic>;
      final text = ayah['text'] as String;
      final charCount = text.replaceAll(' ', '').length;
      final durationMs = (charCount / _defaultCharsPerSecond * 1000).round();
      final startMs = currentMs;
      final endMs = currentMs + durationMs;

      timings.add({
        'ayah': ayah['numberInSurah'] as int,
        'start': startMs,
        'end': endMs,
      });

      currentMs = endMs + _pausePerAyahMs.round();
    }

    final outFile = File('${outDir.path}/$number.json');
    outFile.writeAsStringSync(jsonEncode(timings));
    print('Generated: surah $number (${timings.length} ayahs, ${currentMs}ms)');
  }

  print('Done! Generated ${json.length} timing files.');
}
