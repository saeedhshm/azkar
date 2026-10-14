import 'dart:async';

import 'package:azkar/features/quran/audio/data/datasources/quran_audio_engine.dart';
import 'package:azkar/features/quran/audio/data/datasources/quran_audio_player_service.dart';
import 'package:azkar/features/quran/audio/domain/entities/ayah_timing.dart';
import 'package:azkar/features/quran/audio/domain/entities/reciter.dart';
import 'package:azkar/features/quran/audio/domain/entities/surah_timing.dart';
import 'package:azkar/features/quran/audio/domain/repositories/recitation_repository.dart';
import 'package:azkar/features/quran/audio/presentation/cubit/quran_audio_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

class _FakeAudioEngine implements QuranAudioEngine {
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _processing = StreamController<ProcessingState>.broadcast();

  final List<String> loadedSources = [];
  int disposeCount = 0;
  int playCount = 0;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<ProcessingState> get processingStateStream => _processing.stream;

  @override
  Duration get position => Duration.zero;

  @override
  Duration? get duration => const Duration(minutes: 3);

  @override
  Future<void> setSource(String url) async {
    loadedSources.add(url);
    _processing.add(ProcessingState.ready);
  }

  @override
  Future<void> play() async {
    playCount++;
    _processing.add(ProcessingState.ready);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

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

class _FakeRecitationRepository implements RecitationRepository {
  @override
  List<Reciter> getAvailableReciters() => Reciter.defaults;

  @override
  Reciter get defaultReciter => Reciter.defaults.first;

  @override
  Future<SurahTiming> getTiming(
    int surahNumber, {
    required Reciter reciter,
  }) async {
    return SurahTiming(
      surahNumber: surahNumber,
      ayahTimings: const [
        AyahTiming(surahNumber: 1, ayahNumber: 1, startMs: 0, endMs: 5000),
        AyahTiming(surahNumber: 1, ayahNumber: 2, startMs: 5000, endMs: 9000),
      ],
    );
  }
}

void main() {
  final repo = _FakeRecitationRepository();

  test('two sequential cubits each initialize playback on a live service', () async {
    // Regression: the player service used to be an application singleton that
    // every cubit disposed, so the second reader received a disposed service.
    final engines = <_FakeAudioEngine>[];

    Future<QuranAudioCubit> openReader() async {
      final engine = _FakeAudioEngine();
      engines.add(engine);
      final cubit = QuranAudioCubit(
        QuranAudioPlayerService(engineFactory: () => engine),
        repo,
      );
      await cubit.playSurah(1);
      return cubit;
    }

    final first = await openReader();
    expect(first.state.playerState, isNotNull);
    expect(engines.first.loadedSources, isNotEmpty);
    expect(engines.first.playCount, 1);
    expect(first.hasDisposedPlayerService, isFalse);

    await first.close();
    expect(first.hasDisposedPlayerService, isTrue);
    expect(engines.first.disposeCount, 1);

    final second = await openReader();
    expect(second.hasDisposedPlayerService, isFalse);
    expect(engines, hasLength(2));
    expect(engines.last.loadedSources, isNotEmpty);
    expect(engines.last.playCount, 1);
    expect(engines.last.disposeCount, 0);

    await second.close();
    expect(engines.last.disposeCount, 1);
  });

  test('closing a cubit disposes its service exactly once', () async {
    final engine = _FakeAudioEngine();
    final cubit = QuranAudioCubit(
      QuranAudioPlayerService(engineFactory: () => engine),
      repo,
    );

    await cubit.close();

    expect(engine.disposeCount, 1);
  });
}
