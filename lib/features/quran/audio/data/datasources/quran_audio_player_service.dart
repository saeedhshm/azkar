import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/entities/reciter.dart';

enum AudioPlayerState { idle, loading, ready, playing, paused, completed, error }

class QuranAudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayerState _state = AudioPlayerState.idle;
  String? _currentUrl;
  bool _disposed = false;

  AudioPlayerState get state => _state;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get durationStream =>
      _player.durationStream.where((d) => d != null).cast<Duration>();
  Stream<AudioPlayerState> get stateStream => _player.playerStateStream.map(
    (p) {
      if (_disposed) return AudioPlayerState.idle;
      switch (p.processingState) {
        case ProcessingState.idle:
          return AudioPlayerState.idle;
        case ProcessingState.loading:
          return AudioPlayerState.loading;
        case ProcessingState.buffering:
          return AudioPlayerState.loading;
        case ProcessingState.ready:
          if (p.playing) return AudioPlayerState.playing;
          return AudioPlayerState.paused;
        case ProcessingState.completed:
          return AudioPlayerState.completed;
      }
    },
  );
  Duration get currentPosition => _player.position;
  Duration? get duration => _player.duration;

  StreamSubscription<dynamic>? _positionSub;

  Future<void> loadSurah(int surahNumber, Reciter reciter) async {
    final url = reciter.surahUrl(surahNumber);
    if (url == _currentUrl && _player.duration != null) {
      await _player.seek(Duration.zero);
      return;
    }
    _state = AudioPlayerState.loading;
    _currentUrl = url;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    _state = AudioPlayerState.ready;
  }

  Future<void> play() async {
    if (_disposed) return;
    await _player.play();
    _state = AudioPlayerState.playing;
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _player.pause();
    _state = AudioPlayerState.paused;
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _player.stop();
    _state = AudioPlayerState.idle;
    _currentUrl = null;
  }

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    if (_disposed) return;
    await _player.setSpeed(speed.clamp(0.5, 2.0));
  }

  void dispose() {
    _disposed = true;
    _positionSub?.cancel();
    _player.dispose();
  }
}
