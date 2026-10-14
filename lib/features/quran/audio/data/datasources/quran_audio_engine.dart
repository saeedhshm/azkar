import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Abstraction over the underlying audio engine.
///
/// Exists so [QuranAudioPlayerService] can be tested without a platform audio
/// implementation, and so the service's ownership model is verifiable.
abstract class QuranAudioEngine {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<ProcessingState> get processingStateStream;
  Duration get position;
  Duration? get duration;

  Future<void> setSource(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  void dispose();
}

/// Default engine backed by `just_audio`.
class JustAudioEngine implements QuranAudioEngine {
  JustAudioEngine() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _player.playerStateStream.map((state) => state.processingState);

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  Future<void> setSource(String url) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  void dispose() => _player.dispose();
}

/// Creates the audio engine used by a player service instance.
typedef QuranAudioEngineFactory = QuranAudioEngine Function();
