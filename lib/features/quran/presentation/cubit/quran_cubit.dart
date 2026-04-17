import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/quran_repository.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit(this._repository) : super(const QuranState.initial());

  final QuranRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: QuranStatus.loading));
    try {
      final surahs = await _repository.getSurahs();
      emit(
        state.copyWith(
          status: QuranStatus.loaded,
          surahs: surahs,
          selectedSurahNumber: surahs.isEmpty ? 1 : surahs.first.number,
          selectedAyahNumber: null,
          query: '',
          searchResults: const [],
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void selectSurah(int surahNumber, {int? ayahNumber}) {
    emit(
      state.copyWith(
        selectedSurahNumber: surahNumber,
        selectedAyahNumber: ayahNumber,
      ),
    );
  }

  void selectAyah(int ayahNumber) {
    emit(state.copyWith(selectedAyahNumber: ayahNumber));
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(query: '', searchResults: const []));
      return;
    }

    final results = await _repository.search(trimmed);
    emit(state.copyWith(query: trimmed, searchResults: results));
  }

  void clearSearch() {
    emit(state.copyWith(query: '', searchResults: const []));
  }

  void markAudioUnavailable() {
    emit(state.copyWith(audioStatus: QuranAudioStatus.unavailable));
  }
}
