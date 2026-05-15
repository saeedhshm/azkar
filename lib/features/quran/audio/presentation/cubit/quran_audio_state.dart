import 'package:equatable/equatable.dart';

import '../../domain/entities/surah_timing.dart';
import '../../data/datasources/quran_audio_player_service.dart';
import '../../domain/entities/reciter.dart';

class QuranAudioState extends Equatable {
  const QuranAudioState({
    required this.playerState,
    required this.currentSurahNumber,
    required this.currentAyahNumber,
    required this.positionMs,
    required this.durationMs,
    required this.reciter,
    required this.isLoading,
    required this.errorMessage,
    required this.ayahTimings,
  });

  const QuranAudioState.initial()
    : playerState = AudioPlayerState.idle,
      currentSurahNumber = 1,
      currentAyahNumber = 0,
      positionMs = 0,
      durationMs = 0,
      reciter = null,
      isLoading = false,
      errorMessage = null,
      ayahTimings = const {};

  final AudioPlayerState playerState;
  final int currentSurahNumber;
  final int currentAyahNumber;
  final int positionMs;
  final int durationMs;
  final Reciter? reciter;
  final bool isLoading;
  final String? errorMessage;
  final Map<int, SurahTiming> ayahTimings;

  bool get isPlaying => playerState == AudioPlayerState.playing;
  bool get isPaused => playerState == AudioPlayerState.paused;
  bool get isActive =>
      playerState == AudioPlayerState.playing ||
      playerState == AudioPlayerState.paused;

  double get progress => durationMs > 0 ? positionMs / durationMs : 0.0;

  QuranAudioState copyWith({
    AudioPlayerState? playerState,
    int? currentSurahNumber,
    int? currentAyahNumber,
    int? positionMs,
    int? durationMs,
    Object? reciter = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Map<int, SurahTiming>? ayahTimings,
  }) {
    return QuranAudioState(
      playerState: playerState ?? this.playerState,
      currentSurahNumber: currentSurahNumber ?? this.currentSurahNumber,
      currentAyahNumber: currentAyahNumber ?? this.currentAyahNumber,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      reciter: reciter == _sentinel ? this.reciter : reciter as Reciter?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage == _sentinel
              ? this.errorMessage
              : errorMessage as String?,
      ayahTimings: ayahTimings ?? this.ayahTimings,
    );
  }

  @override
  List<Object?> get props => [
    playerState,
    currentSurahNumber,
    currentAyahNumber,
    positionMs,
    durationMs,
    reciter,
    isLoading,
    errorMessage,
    ayahTimings,
  ];
}

const _sentinel = Object();
