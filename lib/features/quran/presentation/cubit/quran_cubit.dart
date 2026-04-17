import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_surah.dart';
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
          selectedPageNumber: surahs.isEmpty || surahs.first.ayahs.isEmpty
              ? 1
              : surahs.first.ayahs.first.page,
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
    final surah = _findSurah(surahNumber);
    final pageNumber =
        _pageForAyah(surah, ayahNumber) ??
        (surah?.ayahs.isEmpty ?? true ? null : surah!.ayahs.first.page);
    emit(
      state.copyWith(
        selectedSurahNumber: surahNumber,
        selectedAyahNumber: ayahNumber,
        selectedPageNumber: pageNumber,
      ),
    );
  }

  void selectAyah(int ayahNumber) {
    final pageNumber = _pageForAyah(state.selectedSurah, ayahNumber);
    emit(
      state.copyWith(
        selectedAyahNumber: ayahNumber,
        selectedPageNumber: pageNumber,
      ),
    );
  }

  void selectPage(int pageNumber) {
    final surah = _surahForPage(pageNumber);
    emit(
      state.copyWith(
        selectedPageNumber: pageNumber,
        selectedSurahNumber: surah?.number,
        selectedAyahNumber: null,
      ),
    );
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

  QuranSurah? _findSurah(int surahNumber) {
    for (final surah in state.surahs) {
      if (surah.number == surahNumber) {
        return surah;
      }
    }
    return null;
  }

  int? _pageForAyah(QuranSurah? surah, int? ayahNumber) {
    if (surah == null || ayahNumber == null) {
      return null;
    }
    for (final ayah in surah.ayahs) {
      if (ayah.numberInSurah == ayahNumber) {
        return ayah.page;
      }
    }
    return null;
  }

  QuranSurah? _surahForPage(int pageNumber) {
    QuranSurah? candidate;
    for (final surah in state.surahs) {
      if (surah.ayahs.any((ayah) => ayah.page == pageNumber)) {
        return surah;
      }
      if (surah.ayahs.isNotEmpty && surah.ayahs.first.page <= pageNumber) {
        candidate = surah;
      }
    }
    return candidate;
  }
}
