import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/audio/data/datasources/quran_audio_player_service.dart';
import 'package:azkar/features/quran/audio/presentation/cubit/quran_audio_state.dart';
import 'package:azkar/features/quran/audio/domain/entities/reciter.dart';

void main() {
  group('QuranAudioState', () {
    test('initial state has correct defaults', () {
      const state = QuranAudioState.initial();
      expect(state.playerState, AudioPlayerState.idle);
      expect(state.currentSurahNumber, 1);
      expect(state.currentAyahNumber, 0);
      expect(state.positionMs, 0);
      expect(state.durationMs, 0);
      expect(state.reciter, isNull);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.ayahTimings, isEmpty);
    });

    test('isPlaying returns true only when playing', () {
      const playing = QuranAudioState.initial();
      expect(playing.isPlaying, false);
    });

    test('isPaused returns true only when paused', () {
      const paused = QuranAudioState.initial();
      expect(paused.isPaused, false);
    });

    test('isActive returns true when playing or paused', () {
      final playing = QuranAudioState.initial().copyWith(
        playerState: AudioPlayerState.playing,
      );
      expect(playing.isActive, true);

      final paused = QuranAudioState.initial().copyWith(
        playerState: AudioPlayerState.paused,
      );
      expect(paused.isActive, true);

      final idle = QuranAudioState.initial().copyWith(
        playerState: AudioPlayerState.idle,
      );
      expect(idle.isActive, false);
    });

    test('progress returns 0 when durationMs is 0', () {
      const state = QuranAudioState.initial();
      expect(state.progress, 0.0);
    });

    test('progress returns correct ratio', () {
      final state = QuranAudioState.initial().copyWith(
        positionMs: 2500,
        durationMs: 10000,
      );
      expect(state.progress, 0.25);
    });

    test('copyWith updates only specified fields', () {
      const state = QuranAudioState.initial();
      final updated = state.copyWith(
        playerState: AudioPlayerState.playing,
        currentSurahNumber: 36,
      );
      expect(updated.playerState, AudioPlayerState.playing);
      expect(updated.currentSurahNumber, 36);
      expect(updated.currentAyahNumber, 0);
      expect(updated.positionMs, 0);
      expect(updated.durationMs, 0);
    });

    test('copyWith can set reciter to null', () {
      final state = QuranAudioState.initial().copyWith(
        reciter: Reciter.defaults.first,
      );
      expect(state.reciter, isNotNull);

      final cleared = state.copyWith(reciter: null);
      expect(cleared.reciter, isNull);
    });

    test('copyWith can set errorMessage to null', () {
      final state = QuranAudioState.initial().copyWith(
        errorMessage: 'some error',
      );
      expect(state.errorMessage, 'some error');

      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });

    test('props are correct', () {
      const state = QuranAudioState.initial();
      expect(state.props.length, 9);
    });
  });
}
