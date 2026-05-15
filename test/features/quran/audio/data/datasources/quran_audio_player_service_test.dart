import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/audio/data/datasources/quran_audio_player_service.dart';

void main() {
  group('AudioPlayerState enum', () {
    test('has all expected values', () {
      expect(AudioPlayerState.values.length, 7);
      expect(AudioPlayerState.idle, isA<AudioPlayerState>());
      expect(AudioPlayerState.loading, isA<AudioPlayerState>());
      expect(AudioPlayerState.ready, isA<AudioPlayerState>());
      expect(AudioPlayerState.playing, isA<AudioPlayerState>());
      expect(AudioPlayerState.paused, isA<AudioPlayerState>());
      expect(AudioPlayerState.completed, isA<AudioPlayerState>());
      expect(AudioPlayerState.error, isA<AudioPlayerState>());
    });
  });
}
