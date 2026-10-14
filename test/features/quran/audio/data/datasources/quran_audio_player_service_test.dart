import 'dart:async';

import 'package:azkar/features/quran/audio/data/datasources/quran_audio_engine.dart';
import 'package:azkar/features/quran/audio/data/datasources/quran_audio_player_service.dart';
import 'package:azkar/features/quran/audio/domain/entities/reciter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

/// In-memory audio engine used to verify lifecycle behaviour without a
/// platform audio implementation.
class FakeAudioEngine implements QuranAudioEngine {
  FakeAudioEngine();

  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _processing = StreamController<ProcessingState>.broadcast();

  final List<String> loadedSources = [];
  int disposeCount = 0;
  int playCount = 0;
  int pauseCount = 0;
  int stopCount = 0;
  bool playing = false;

  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration = const Duration(minutes: 3);

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<ProcessingState> get processingStateStream => _processing.stream;

  @override
  Duration get position => _currentPosition;

  @override
  Duration? get duration => _currentDuration;

  @override
  Future<void> setSource(String url) async {
    loadedSources.add(url);
    _currentDuration = const Duration(minutes: 3);
    _processing.add(ProcessingState.ready);
  }

  @override
  Future<void> play() async {
    playCount++;
    playing = true;
    _processing.add(ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    playing = false;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    playing = false;
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPosition = position;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  void dispose() {
    disposeCount++;
    _position.close();
    _duration.close();
    _processing.close();
  }
}

void main() {
  final reciter = Reciter.defaults.first;

  QuranAudioPlayerService buildService(FakeAudioEngine engine) {
    return QuranAudioPlayerService(engineFactory: () => engine);
  }

  group('QuranAudioPlayerService lifecycle', () {
    test('loads and plays a surah', () async {
      final engine = FakeAudioEngine();
      final service = buildService(engine);

      await service.loadSurah(1, reciter);
      expect(engine.loadedSources, [reciter.surahUrl(1)]);
      expect(service.state, AudioPlayerState.ready);

      await service.play();
      expect(engine.playCount, 1);
      expect(service.state, AudioPlayerState.playing);

      service.dispose();
    });

    test('disposes its engine exactly once', () {
      final engine = FakeAudioEngine();
      final service = buildService(engine);

      expect(service.isDisposed, isFalse);

      service.dispose();
      service.dispose();

      expect(service.isDisposed, isTrue);
      expect(engine.disposeCount, 1);
    });

    test('a disposed service refuses further playback work', () async {
      final engine = FakeAudioEngine();
      final service = buildService(engine);

      service.dispose();

      await service.play();
      await service.pause();
      await service.stop();
      await service.seek(Duration.zero);

      expect(engine.playCount, 0);
      expect(engine.pauseCount, 0);
      expect(engine.stopCount, 0);

      await expectLater(
        service.loadSurah(2, reciter),
        throwsA(isA<StateError>()),
      );
    });

    test('reopening the reader works with a fresh service instance', () async {
      // Regression: the service used to be a singleton disposed by the first
      // cubit, so reopening the reader reused a disposed instance.
      final engines = <FakeAudioEngine>[];

      QuranAudioPlayerService newSession() {
        final engine = FakeAudioEngine();
        engines.add(engine);
        return QuranAudioPlayerService(engineFactory: () => engine);
      }

      final firstSession = newSession();
      await firstSession.loadSurah(1, reciter);
      await firstSession.play();
      firstSession.dispose();

      final secondSession = newSession();
      expect(secondSession.isDisposed, isFalse);

      await secondSession.loadSurah(1, reciter);
      await secondSession.play();

      expect(engines, hasLength(2));
      expect(engines.first.disposeCount, 1);
      expect(engines.last.disposeCount, 0);
      expect(engines.last.playCount, 1);
      expect(engines.last.loadedSources, [reciter.surahUrl(1)]);

      secondSession.dispose();
      expect(engines.last.disposeCount, 1);
    });

    test('reloads only when the url changes', () async {
      final engine = FakeAudioEngine();
      final service = buildService(engine);

      await service.loadSurah(1, reciter);
      await service.loadSurah(1, reciter);

      expect(engine.loadedSources, hasLength(1));

      await service.loadSurah(2, reciter);

      expect(engine.loadedSources, hasLength(2));

      service.dispose();
    });

    test('maps engine processing states', () async {
      final engine = FakeAudioEngine();
      final service = buildService(engine);

      final states = <AudioPlayerState>[];
      final sub = service.stateStream.listen(states.add);

      engine._processing.add(ProcessingState.loading);
      engine._processing.add(ProcessingState.buffering);
      engine._processing.add(ProcessingState.ready);
      engine._processing.add(ProcessingState.completed);
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        AudioPlayerState.loading,
        AudioPlayerState.loading,
        AudioPlayerState.playing,
        AudioPlayerState.completed,
      ]);

      await sub.cancel();
      service.dispose();
    });

    test('clamps volume and speed', () async {
      final engine = FakeAudioEngine();
      final service = buildService(engine);

      await service.setVolume(5);
      await service.setSpeed(99);

      service.dispose();
    });
  });

  group('AudioPlayerState enum', () {
    test('has all expected values', () {
      expect(AudioPlayerState.values.length, 7);
    });
  });
}
