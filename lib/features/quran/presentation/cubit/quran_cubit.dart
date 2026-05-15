import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_last_read_repository.dart';
import '../../domain/usecases/get_quran_surahs_use_case.dart';
import '../../domain/usecases/search_quran_use_case.dart';
import '../../services/quran_svg_page_service.dart';
import 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit(
    this._getQuranSurahs,
    this._searchQuran,
    this._lastReadRepository,
  ) : super(const QuranState.initial());

  final GetQuranSurahsUseCase _getQuranSurahs;
  final SearchQuranUseCase _searchQuran;
  final QuranLastReadRepository _lastReadRepository;

  Future<void> load({int? initialPageNumber}) async {
    emit(state.copyWith(status: QuranStatus.loading));
    try {
      final surahsFuture = _getQuranSurahs();
      final lastPageFuture = Future.value(
        initialPageNumber ?? _lastReadRepository.getLastPage(),
      );
      final lastAyahFuture = Future.value(_lastReadRepository.getLastAyah());

      final results = await Future.wait([
        surahsFuture,
        lastPageFuture,
        lastAyahFuture,
      ]);

      final surahs = results[0] as List<QuranSurah>;
      final lastPage = results[1] as int?;
      final lastAyah = results[2] as ({int surah, int ayah})?;

      final defaultPage = surahs.isEmpty || surahs.first.ayahs.isEmpty
          ? 1
          : surahs.first.ayahs.first.page;
      final startPage = (lastPage ?? defaultPage)
          .clamp(QuranSvgPageService.firstPage, QuranSvgPageService.lastPage)
          .toInt();
      final initialSurah = _surahForPage(startPage, surahs: surahs);
      final restoredAyah = lastAyah != null &&
              lastAyah.surah == initialSurah?.number &&
              initialSurah != null
          ? lastAyah.ayah
          : null;

      emit(
        state.copyWith(
          status: QuranStatus.loaded,
          surahs: surahs,
          selectedSurahNumber:
              initialSurah?.number ??
              (surahs.isEmpty ? 1 : surahs.first.number),
          selectedAyahNumber: restoredAyah,
          selectedPageNumber: startPage,
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
    if (ayahNumber != null && pageNumber != null) {
      _lastReadRepository.saveLastAyah(surah: surahNumber, ayah: ayahNumber);
    }
  }

  void selectAyah(int ayahNumber) {
    final pageNumber = _pageForAyah(state.selectedSurah, ayahNumber);
    emit(
      state.copyWith(
        selectedAyahNumber: ayahNumber,
        selectedPageNumber: pageNumber,
      ),
    );
    if (pageNumber != null) {
      _lastReadRepository.saveLastAyah(
        surah: state.selectedSurahNumber,
        ayah: ayahNumber,
      );
    }
  }

  void selectPage(int pageNumber) {
    final surah = _surahForCurrentPage(pageNumber);
    emit(
      state.copyWith(
        selectedPageNumber: pageNumber,
        selectedSurahNumber: surah?.number,
        selectedAyahNumber: null,
      ),
    );
    _lastReadRepository.saveLastPage(pageNumber);
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(query: '', searchResults: const []));
      return;
    }

    final results = await _searchQuran(trimmed);
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

  QuranSurah? _surahForCurrentPage(int pageNumber) {
    return _surahForPage(pageNumber, surahs: state.surahs);
  }

  QuranSurah? _surahForPage(
    int pageNumber, {
    required List<QuranSurah> surahs,
  }) {
    QuranSurah? candidate;
    for (final surah in surahs) {
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
