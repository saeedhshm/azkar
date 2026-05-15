import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ayah_highlight.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';
import 'quran_highlight_state.dart';

class QuranHighlightCubit extends Cubit<QuranHighlightState> {
  QuranHighlightCubit(this._bookmarkRepository)
    : super(QuranHighlightState.initial) {
    _loadBookmarks();
  }

  final QuranBookmarkRepository _bookmarkRepository;

  static const _maxSearchHighlights = 80;
  static const _maxBookmarkHighlights = 200;

  void addTapHighlight(AyahHighlight highlight) {
    assert(highlight.type == AyahHighlightType.tap);

    final existingTapId = state.tapHighlightId;
    var updated = Map<String, AyahHighlight>.from(state.highlights);

    if (existingTapId != null) {
      updated.remove(existingTapId);
    }

    updated[highlight.id] = highlight;

    emit(
      state.copyWith(
        highlights: updated,
        tapHighlightId: highlight.id,
      ),
    );
  }

  void clearTapHighlight() {
    final tapId = state.tapHighlightId;
    if (tapId == null) return;

    final updated = Map<String, AyahHighlight>.from(state.highlights);
    updated.remove(tapId);

    emit(state.copyWith(highlights: updated, tapHighlightId: null));
  }

  void setReadingHighlight(AyahHighlight? highlight) {
    final oldReadingId = state.readingHighlightId;
    var updated = Map<String, AyahHighlight>.from(state.highlights);

    if (oldReadingId != null) {
      updated.remove(oldReadingId);
    }

    if (highlight != null) {
      assert(highlight.type == AyahHighlightType.reading);
      updated[highlight.id] = highlight;
    }

    emit(
      state.copyWith(
        highlights: updated,
        readingHighlightId: highlight?.id,
      ),
    );
  }

  void addSearchHighlights(List<AyahHighlight> highlights) {
    var updated = Map<String, AyahHighlight>.from(state.highlights);

    final oldSearchIds = state.searchHighlights.map((h) => h.id).toSet();
    for (final id in oldSearchIds) {
      updated.remove(id);
    }

    final limited = highlights.take(_maxSearchHighlights);
    for (final h in limited) {
      updated[h.id] = h;
    }

    emit(state.copyWith(highlights: updated));
  }

  void clearSearchHighlights() {
    final searchIds = state.searchHighlights.map((h) => h.id).toSet();
    if (searchIds.isEmpty) return;

    var updated = Map<String, AyahHighlight>.from(state.highlights);
    for (final id in searchIds) {
      updated.remove(id);
    }

    emit(state.copyWith(highlights: updated));
  }

  void toggleBookmarkHighlight(AyahHighlight highlight) {
    assert(highlight.type == AyahHighlightType.bookmark);

    var updated = Map<String, AyahHighlight>.from(state.highlights);

    if (updated.containsKey(highlight.id)) {
      updated.remove(highlight.id);
    } else {
      if (state.bookmarkHighlights.length >= _maxBookmarkHighlights) {
        return;
      }
      updated[highlight.id] = highlight;
    }

    emit(state.copyWith(highlights: updated));
    _saveBookmarks();
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return state.bookmarkHighlights.any(
      (h) => h.surahNumber == surahNumber && h.ayahNumber == ayahNumber,
    );
  }

  bool isPolygonHighlighted(String polygonId, int pageNumber) {
    return state.highlights.values.any(
      (h) => h.polygonId == polygonId && h.pageNumber == pageNumber,
    );
  }

  void clearPageHighlights(int pageNumber) {
    var updated = Map<String, AyahHighlight>.from(state.highlights);
    updated.removeWhere((_, h) => h.pageNumber == pageNumber);
    emit(state.copyWith(highlights: updated));
  }

  void clearTemporaryHighlights() {
    var updated = Map<String, AyahHighlight>.from(state.highlights);
    updated.removeWhere((_, h) => h.type != AyahHighlightType.bookmark);
    emit(
      state.copyWith(
        highlights: updated,
        tapHighlightId: null,
        readingHighlightId: null,
      ),
    );
  }

  void clearAll() {
    emit(QuranHighlightState.initial);
  }

  void _loadBookmarks() {
    final bookmarks = _bookmarkRepository.getAll();
    if (bookmarks.isEmpty) return;

    final highlights = Map<String, AyahHighlight>.from(state.highlights);
    for (final entry in bookmarks) {
      highlights[entry.id] = entry;
    }
    emit(state.copyWith(highlights: highlights));
  }

  void _saveBookmarks() {
    _bookmarkRepository.replaceAll(state.bookmarkHighlights);
  }
}
