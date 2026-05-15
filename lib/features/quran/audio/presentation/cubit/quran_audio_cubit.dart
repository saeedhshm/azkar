import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/storage/local_storage_service.dart';
import '../../../domain/entities/quran_surah.dart';
import '../../data/datasources/quran_audio_player_service.dart';
import '../../domain/entities/ayah_timing.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah_timing.dart';
import '../../domain/repositories/recitation_repository.dart';
import 'quran_audio_state.dart';

class QuranAudioCubit extends Cubit<QuranAudioState> {
  QuranAudioCubit(this._playerService, this._recitationRepo)
    : super(const QuranAudioState.initial());

  final QuranAudioPlayerService _playerService;
  final RecitationRepository _recitationRepo;

  StreamSubscription<AudioPlayerState>? _stateSub;
  Timer? _ayahCheckTimer;

  int? _lastAyahNumber;
  List<QuranSurah>? _surahs;
  void Function(int page)? onPageNeeded;

  void setSurahs(List<QuranSurah> surahs) {
    _surahs = surahs;
  }

  Future<void> playSurah(int surahNumber, {Reciter? reciter}) async {
    final r = reciter ?? state.reciter ?? _recitationRepo.defaultReciter;

    emit(
      state.copyWith(
        playerState: AudioPlayerState.loading,
        currentSurahNumber: surahNumber,
        reciter: r,
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      final timing = await _recitationRepo.getTiming(surahNumber, reciter: r);
      final updatedTimings =
          Map<int, SurahTiming>.from(state.ayahTimings);
      updatedTimings[surahNumber] = timing;

      await _playerService.loadSurah(surahNumber, r);
      _stateSub?.cancel();
      _stateSub = _playerService.stateStream.listen(_onPlayerStateChanged);

      emit(
        state.copyWith(
          playerState: AudioPlayerState.ready,
          positionMs: 0,
          currentAyahNumber: 0,
          durationMs: _playerService.duration?.inMilliseconds ?? 0,
          isLoading: false,
          ayahTimings: updatedTimings,
        ),
      );

      await _playerService.play();
      _startAyahTracking();

      if (timing.ayahTimings.isNotEmpty) {
        final firstAyah = timing.ayahTimings.first;
        _updateCurrentAyah(firstAyah.ayahNumber, surahNumber);
      }
    } catch (e) {
      emit(
        state.copyWith(
          playerState: AudioPlayerState.error,
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> resume() async {
    if (state.playerState != AudioPlayerState.paused) return;
    await _playerService.play();
    _startAyahTracking();
  }

  Future<void> pause() async {
    if (state.playerState != AudioPlayerState.playing) return;
    await _playerService.pause();
    _stopAyahTracking();
    emit(
      state.copyWith(
        playerState: AudioPlayerState.paused,
        positionMs: _playerService.currentPosition.inMilliseconds,
      ),
    );
  }

  Future<void> stop() async {
    _stopAyahTracking();
    _stateSub?.cancel();
    _stateSub = null;
    _lastAyahNumber = null;
    await _playerService.stop();
    emit(const QuranAudioState.initial());
  }

  Future<void> seekToAyah(int ayahNumber) async {
    final timing = state.ayahTimings[state.currentSurahNumber];
    if (timing == null) return;

    final ayahTiming = timing.ayahByNumber(ayahNumber);
    if (ayahTiming == null) return;

    await _playerService.seek(Duration(milliseconds: ayahTiming.startMs));
    _updateCurrentAyah(ayahNumber, state.currentSurahNumber);
  }

  Future<void> seekToPosition(Duration position) async {
    await _playerService.seek(position);
    _checkCurrentAyah();
  }

  Future<void> setReciter(Reciter reciter) async {
    final isActive = state.isActive;
    if (isActive) {
      await stop();
    }
    emit(state.copyWith(reciter: reciter));
  }

  void setFavoriteReciter(Reciter reciter) {
    setReciter(reciter);
    getIt<LocalStorageService>().putRaw(
      AppConstants.quranFavoriteReciterKey,
      reciter.id,
    );
  }

  Reciter? getFavoriteReciter() {
    final storage = getIt<LocalStorageService>();
    final faveId = storage.getRaw(AppConstants.quranFavoriteReciterKey) as String?;
    if (faveId == null) return null;
    return Reciter.defaults.cast<Reciter?>().firstWhere(
      (r) => r!.id == faveId,
      orElse: () => null,
    );
  }

  bool isFavoriteReciter(Reciter reciter) {
    final fave = getFavoriteReciter();
    return fave?.id == reciter.id;
  }

  Future<void> playWithFavoriteReciter(int surahNumber) async {
    final fave = getFavoriteReciter();
    await playSurah(surahNumber, reciter: fave);
  }

  void _startAyahTracking() {
    _stopAyahTracking();
    _ayahCheckTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _checkCurrentAyah(),
    );
  }

  void _stopAyahTracking() {
    _ayahCheckTimer?.cancel();
    _ayahCheckTimer = null;
  }

  void _checkCurrentAyah() {
    final timing = state.ayahTimings[state.currentSurahNumber];
    if (timing == null) return;

    final posMs = _playerService.currentPosition.inMilliseconds;
    final matched = timing.ayahAtPosition(posMs);

    if (matched != null && matched.ayahNumber != _lastAyahNumber) {
      _updateCurrentAyah(matched.ayahNumber, state.currentSurahNumber);
      _triggerPageNavigationIfNeeded(matched);
    }

    if (state.positionMs != posMs) {
      emit(
        state.copyWith(
          positionMs: posMs,
          durationMs:
              _playerService.duration?.inMilliseconds ?? state.durationMs,
        ),
      );
    }
  }

  void _updateCurrentAyah(int ayahNumber, int surahNumber) {
    _lastAyahNumber = ayahNumber;
    emit(state.copyWith(currentAyahNumber: ayahNumber));
  }

  void _triggerPageNavigationIfNeeded(AyahTiming ayah) {
    if (_surahs == null || onPageNeeded == null) return;

    for (final surah in _surahs!) {
      if (surah.number == ayah.surahNumber) {
        for (final a in surah.ayahs) {
          if (a.numberInSurah == ayah.ayahNumber) {
            onPageNeeded!(a.page);
            return;
          }
        }
      }
    }
  }

  void _onPlayerStateChanged(AudioPlayerState playerState) {
    if (isClosed) return;

    if (playerState == AudioPlayerState.completed) {
      _stopAyahTracking();
      _lastAyahNumber = null;
    }

    emit(state.copyWith(playerState: playerState));
  }

  @override
  Future<void> close() {
    _stopAyahTracking();
    _stateSub?.cancel();
    _playerService.dispose();
    return super.close();
  }
}
