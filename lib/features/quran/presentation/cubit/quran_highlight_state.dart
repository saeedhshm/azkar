import 'package:equatable/equatable.dart';

import '../../domain/entities/ayah_highlight.dart';

class QuranHighlightState extends Equatable {
  const QuranHighlightState._({
    required this.highlights,
    required this.tapHighlightId,
    required this.readingHighlightId,
    required Map<int, List<AyahHighlight>> highlightsByPage,
    required Map<int, List<AyahHighlight>> bookmarksByPage,
    required List<AyahHighlight> searchHighlights,
    required List<AyahHighlight> bookmarkHighlights,
    required List<AyahHighlight> temporaryHighlights,
  })  : _highlightsByPage = highlightsByPage,
        _bookmarksByPage = bookmarksByPage,
        _searchHighlights = searchHighlights,
        _bookmarkHighlights = bookmarkHighlights,
        _temporaryHighlights = temporaryHighlights;

  factory QuranHighlightState({
    required Map<String, AyahHighlight> highlights,
    String? tapHighlightId,
    String? readingHighlightId,
  }) {
    return QuranHighlightState._fromMap(
      highlights: highlights,
      tapHighlightId: tapHighlightId,
      readingHighlightId: readingHighlightId,
    );
  }

  static const QuranHighlightState initial = QuranHighlightState._(
    highlights: <String, AyahHighlight>{},
    tapHighlightId: null,
    readingHighlightId: null,
    highlightsByPage: <int, List<AyahHighlight>>{},
    bookmarksByPage: <int, List<AyahHighlight>>{},
    searchHighlights: <AyahHighlight>[],
    bookmarkHighlights: <AyahHighlight>[],
    temporaryHighlights: <AyahHighlight>[],
  );

  factory QuranHighlightState._fromMap({
    required Map<String, AyahHighlight> highlights,
    String? tapHighlightId,
    String? readingHighlightId,
  }) {
    final byPage = <int, List<AyahHighlight>>{};
    final bookmarksByPage = <int, List<AyahHighlight>>{};
    final search = <AyahHighlight>[];
    final bookmarks = <AyahHighlight>[];
    final temporary = <AyahHighlight>[];

    for (final h in highlights.values) {
      byPage.putIfAbsent(h.pageNumber, () => []).add(h);
      if (h.type == AyahHighlightType.search) {
        search.add(h);
      } else if (h.type == AyahHighlightType.bookmark) {
        bookmarks.add(h);
        bookmarksByPage.putIfAbsent(h.pageNumber, () => []).add(h);
      }
      if (h.type != AyahHighlightType.bookmark) {
        temporary.add(h);
      }
    }

    return QuranHighlightState._(
      highlights: highlights,
      tapHighlightId: tapHighlightId,
      readingHighlightId: readingHighlightId,
      highlightsByPage: byPage,
      bookmarksByPage: bookmarksByPage,
      searchHighlights: search,
      bookmarkHighlights: bookmarks,
      temporaryHighlights: temporary,
    );
  }

  final Map<String, AyahHighlight> highlights;
  final String? tapHighlightId;
  final String? readingHighlightId;
  final Map<int, List<AyahHighlight>> _highlightsByPage;
  final Map<int, List<AyahHighlight>> _bookmarksByPage;
  final List<AyahHighlight> _searchHighlights;
  final List<AyahHighlight> _bookmarkHighlights;
  final List<AyahHighlight> _temporaryHighlights;

  AyahHighlight? get tapHighlight =>
      tapHighlightId != null ? highlights[tapHighlightId] : null;

  AyahHighlight? get readingHighlight =>
      readingHighlightId != null ? highlights[readingHighlightId] : null;

  List<AyahHighlight> get searchHighlights => _searchHighlights;

  List<AyahHighlight> get bookmarkHighlights => _bookmarkHighlights;

  int get bookmarkCount => _bookmarkHighlights.length;

  List<AyahHighlight> get temporaryHighlights => _temporaryHighlights;

  List<AyahHighlight> highlightsForPage(int pageNumber) {
    return _highlightsByPage[pageNumber] ?? const [];
  }

  List<AyahHighlight> bookmarksForPage(int pageNumber) {
    return _bookmarksByPage[pageNumber] ?? const [];
  }

  AyahHighlight? highlightForPolygon(String polygonId, int pageNumber) {
    final onPage = _highlightsByPage[pageNumber];
    if (onPage == null || onPage.isEmpty) return null;
    AyahHighlight? best;
    for (final h in onPage) {
      if (h.polygonId == polygonId &&
          (best == null || h.type.priority > best.type.priority)) {
        best = h;
      }
    }
    return best;
  }

  QuranHighlightState copyWith({
    Map<String, AyahHighlight>? highlights,
    Object? tapHighlightId = _sentinel,
    Object? readingHighlightId = _sentinel,
  }) {
    final newHighlights = highlights ?? this.highlights;
    final newTapId = tapHighlightId == _sentinel
        ? this.tapHighlightId
        : tapHighlightId as String?;
    final newReadingId = readingHighlightId == _sentinel
        ? this.readingHighlightId
        : readingHighlightId as String?;

    return QuranHighlightState._fromMap(
      highlights: newHighlights,
      tapHighlightId: newTapId,
      readingHighlightId: newReadingId,
    );
  }

  @override
  List<Object?> get props => [
    highlights,
    tapHighlightId,
    readingHighlightId,
  ];
}

const _sentinel = Object();
