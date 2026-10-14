import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/entities/reciter.dart';
import 'quran_audio_engine.dart';
enum AudioPlayerState { idle, loading, ready, playing, paused, completed, error }

/// Owns one audio engine for a single playback session.
///
/// This service is scoped to the cubit that owns it: it is created together
/// with its cubit and disposed with it. Registering it as an application
/// singleton while a screen disposes it would hand a disposed engine to the
/// next screen that resolves the same instance.
class QuranAudioPlayerService {
  QuranAudioPlayerService({QuranAudioEngineFactory? engineFactory})
    : _engine = (engineFactory ?? JustAudioEngine.new)();

  final QuranAudioEngine _engine;

  AudioPlayerState _state = AudioPlayerState.idle;
  String? _currentUrl;
  bool _disposed = false;

  AudioPlayerState get state => _state;
  Stream<Duration> get positionStream => _engine.positionStream;
  Stream<Duration> get durationStream =>
      _engine.durationStream.where((d) => d != null).cast<Duration>();
  Stream<AudioPlayerState> get stateStream =>
      _engine.processingStateStream.map(_mapEngineState);

  Duration get currentPosition => _engine.position;
  Duration? get duration => _engine.duration;

  /// Whether this service has already been disposed.
  bool get isDisposed => _disposed;

  Future<void> loadSurah(int surahNumber, Reciter reciter) async {
    if (_disposed) {
      throw StateError('QuranAudioPlayerService has been disposed.');
    }

    final url = reciter.surahUrl(surahNumber);
    if (url == _currentUrl && _engine.duration != null) {
      await _engine.seek(Duration.zero);
      return;
    }

    _setState(AudioPlayerState.loading);
    _currentUrl = url;
    await _engine.setSource(url);
    _setState(AudioPlayerState.ready);
  }

  Future<void> play() async {
    if (_disposed) return;
    await _engine.play();
    _setState(AudioPlayerState.playing);
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _engine.pause();
    _setState(AudioPlayerState.paused);
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _engine.stop();
    _setState(AudioPlayerState.idle);
    _currentUrl = null;
  }

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _engine.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    await _engine.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    if (_disposed) return;
    await _engine.setSpeed(speed.clamp(0.5, 2.0));
  }

  void _setState(AudioPlayerState next) {
    _state = next;
  }

  AudioPlayerState _mapEngineState(ProcessingState engineState) {
    if (_disposed) return AudioPlayerState.idle;
    return switch (engineState) {
      ProcessingState.idle => AudioPlayerState.idle,
      ProcessingState.loading => AudioPlayerState.loading,
      ProcessingState.buffering => AudioPlayerState.loading,
      ProcessingState.ready => AudioPlayerState.playing,
      ProcessingState.completed => AudioPlayerState.completed,
    };
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _engine.dispose();
  }
}
