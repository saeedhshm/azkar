import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/audio/domain/entities/reciter.dart';

void main() {
  group('Reciter', () {
    test('defaults list is not empty', () {
      expect(Reciter.defaults, isNotEmpty);
    });

    test('defaults has expected reciters', () {
      final ids = Reciter.defaults.map((r) => r.id).toSet();
      expect(ids, containsAll([
        'ar.abdurrahmaansudais',
        'ar.shaatree',
        'ar.mahermuaiqly',
        'ar.husarymujawwad',
        'ar.ahmedajamy',
      ]));
    });

    test('surahUrl replaces template correctly', () {
      final sudais = Reciter.defaults.first;
      expect(sudais.id, 'ar.abdurrahmaansudais');
      final url = sudais.surahUrl(1);
      expect(url, contains('/1.mp3'));
      expect(url, isNot(contains('{surah}')));
    });

    test('surahUrl works for different surah numbers', () {
      final sudais = Reciter.defaults.first;
      final url36 = sudais.surahUrl(36);
      expect(url36, contains('/36.mp3'));
    });

    test('all reciters have required fields', () {
      for (final reciter in Reciter.defaults) {
        expect(reciter.id, isNotEmpty);
        expect(reciter.name, isNotEmpty);
        expect(reciter.arabicName, isNotEmpty);
        expect(reciter.style, isNotEmpty);
        expect(reciter.surahUrlTemplate, isNotEmpty);
        expect(reciter.timingSource, isNotEmpty);
      }
    });
  });
}
