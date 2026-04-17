import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_search_result.dart';
import '../../domain/entities/quran_surah.dart';

enum QuranStatus { initial, loading, loaded, failure }

enum QuranAudioStatus { idle, preparing, playing, paused, unavailable }

class QuranState extends Equatable {
  const QuranState({
    required this.status,
    required this.surahs,
    required this.selectedSurahNumber,
    required this.selectedAyahNumber,
    required this.query,
    required this.searchResults,
    required this.audioStatus,
    this.errorMessage,
  });

  const QuranState.initial()
    : status = QuranStatus.initial,
      surahs = const <QuranSurah>[],
      selectedSurahNumber = 1,
      selectedAyahNumber = null,
      query = '',
      searchResults = const <QuranSearchResult>[],
      audioStatus = QuranAudioStatus.idle,
      errorMessage = null;

  final QuranStatus status;
  final List<QuranSurah> surahs;
  final int selectedSurahNumber;
  final int? selectedAyahNumber;
  final String query;
  final List<QuranSearchResult> searchResults;
  final QuranAudioStatus audioStatus;
  final String? errorMessage;

  QuranSurah? get selectedSurah {
    for (final surah in surahs) {
      if (surah.number == selectedSurahNumber) {
        return surah;
      }
    }
    return surahs.isEmpty ? null : surahs.first;
  }

  bool get isSearching => query.trim().isNotEmpty;

  QuranState copyWith({
    QuranStatus? status,
    List<QuranSurah>? surahs,
    int? selectedSurahNumber,
    Object? selectedAyahNumber = _sentinel,
    String? query,
    List<QuranSearchResult>? searchResults,
    QuranAudioStatus? audioStatus,
    String? errorMessage,
  }) {
    return QuranState(
      status: status ?? this.status,
      surahs: surahs ?? this.surahs,
      selectedSurahNumber: selectedSurahNumber ?? this.selectedSurahNumber,
      selectedAyahNumber: selectedAyahNumber == _sentinel
          ? this.selectedAyahNumber
          : selectedAyahNumber as int?,
      query: query ?? this.query,
      searchResults: searchResults ?? this.searchResults,
      audioStatus: audioStatus ?? this.audioStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    surahs,
    selectedSurahNumber,
    selectedAyahNumber,
    query,
    searchResults,
    audioStatus,
    errorMessage,
  ];
}

const _sentinel = Object();
