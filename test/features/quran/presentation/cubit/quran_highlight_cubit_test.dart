import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/domain/entities/ayah_highlight.dart';
import 'package:azkar/features/quran/presentation/cubit/quran_highlight_cubit.dart';

import '../../data/repositories/quran_bookmark_repository_mock.dart';

void main() {
  late QuranBookmarkRepositoryMock repository;
  late QuranHighlightCubit cubit;

  setUp(() {
    repository = QuranBookmarkRepositoryMock();
    cubit = QuranHighlightCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('initial state', () {
    test('starts with empty highlights', () {
      expect(cubit.state.highlights, isEmpty);
      expect(cubit.state.tapHighlightId, isNull);
      expect(cubit.state.readingHighlightId, isNull);
    });
  });

  group('tap highlights', () {
    test('addTapHighlight adds a tap highlight', () {
      final highlight = AyahHighlight(
        id: 'tap-1:1',
        polygonId: '1:1',
        pageNumber: 1,
        surahNumber: 1,
        ayahNumber: 1,
        type: AyahHighlightType.tap,
      );

      cubit.addTapHighlight(highlight);
      expect(cubit.state.tapHighlight, highlight);
      expect(cubit.state.tapHighlightId, 'tap-1:1');
    });

    test('addTapHighlight replaces previous tap highlight', () {
      final first = AyahHighlight(
        id: 'tap-1:1',
        polygonId: '1:1',
        pageNumber: 1,
        surahNumber: 1,
        ayahNumber: 1,
        type: AyahHighlightType.tap,
      );
      final second = AyahHighlight(
        id: 'tap-2:1',
        polygonId: '2:1',
        pageNumber: 2,
        surahNumber: 2,
        ayahNumber: 1,
        type: AyahHighlightType.tap,
      );

      cubit.addTapHighlight(first);
      cubit.addTapHighlight(second);
      expect(cubit.state.tapHighlight, second);
      expect(cubit.state.highlights.length, 1);
    });

    test('clearTapHighlight removes tap highlight', () {
      final highlight = AyahHighlight(
        id: 'tap-1:1',
        polygonId: '1:1',
        pageNumber: 1,
        surahNumber: 1,
        ayahNumber: 1,
        type: AyahHighlightType.tap,
      );

      cubit.addTapHighlight(highlight);
      expect(cubit.state.tapHighlight, isNotNull);

      cubit.clearTapHighlight();
      expect(cubit.state.tapHighlight, isNull);
      expect(cubit.state.tapHighlightId, isNull);
    });
  });

  group('reading highlights', () {
    test('setReadingHighlight adds reading highlight', () {
      final highlight = AyahHighlight(
        id: 'reading-36:1',
        polygonId: '36:1',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 1,
        type: AyahHighlightType.reading,
      );

      cubit.setReadingHighlight(highlight);
      expect(cubit.state.readingHighlightId, 'reading-36:1');
      expect(cubit.state.readingHighlight, highlight);
    });

    test('setReadingHighlight replaces previous reading highlight', () {
      final first = AyahHighlight(
        id: 'reading-36:1',
        polygonId: '36:1',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 1,
        type: AyahHighlightType.reading,
      );
      final second = AyahHighlight(
        id: 'reading-36:2',
        polygonId: '36:2',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 2,
        type: AyahHighlightType.reading,
      );

      cubit.setReadingHighlight(first);
      cubit.setReadingHighlight(second);
      expect(cubit.state.readingHighlight, second);
      expect(cubit.state.readingHighlightId, 'reading-36:2');
    });

    test('setReadingHighlight(null) removes reading highlight', () {
      final highlight = AyahHighlight(
        id: 'reading-36:1',
        polygonId: '36:1',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 1,
        type: AyahHighlightType.reading,
      );

      cubit.setReadingHighlight(highlight);
      expect(cubit.state.readingHighlight, isNotNull);

      cubit.setReadingHighlight(null);
      expect(cubit.state.readingHighlight, isNull);
    });
  });

  group('search highlights', () {
    test('addSearchHighlights adds multiple search highlights', () {
      final highlights = [
        AyahHighlight(
          id: 'search-1',
          polygonId: '1:1',
          pageNumber: 1,
          surahNumber: 1,
          ayahNumber: 1,
          type: AyahHighlightType.search,
          searchQuery: 'الله',
        ),
        AyahHighlight(
          id: 'search-2',
          polygonId: '2:255',
          pageNumber: 50,
          surahNumber: 2,
          ayahNumber: 255,
          type: AyahHighlightType.search,
          searchQuery: 'الله',
        ),
      ];

      cubit.addSearchHighlights(highlights);
      expect(cubit.state.searchHighlights.length, 2);
    });

    test('addSearchHighlights replaces previous search highlights', () {
      cubit.addSearchHighlights([
        AyahHighlight(
          id: 'search-1',
          polygonId: '1:1',
          pageNumber: 1,
          surahNumber: 1,
          ayahNumber: 1,
          type: AyahHighlightType.search,
          searchQuery: 'الله',
        ),
      ]);

      cubit.addSearchHighlights([
        AyahHighlight(
          id: 'search-2',
          polygonId: '2:255',
          pageNumber: 50,
          surahNumber: 2,
          ayahNumber: 255,
          type: AyahHighlightType.search,
          searchQuery: 'الله',
        ),
      ]);

      expect(cubit.state.searchHighlights.length, 1);
      expect(cubit.state.searchHighlights.first.ayahNumber, 255);
    });

    test('clearSearchHighlights removes all search highlights', () {
      cubit.addSearchHighlights([
        AyahHighlight(
          id: 'search-1',
          polygonId: '1:1',
          pageNumber: 1,
          surahNumber: 1,
          ayahNumber: 1,
          type: AyahHighlightType.search,
        ),
      ]);
      expect(cubit.state.searchHighlights, isNotEmpty);

      cubit.clearSearchHighlights();
      expect(cubit.state.searchHighlights, isEmpty);
    });
  });

  group('bookmark highlights', () {
    test('toggleBookmarkHighlight adds a bookmark', () {
      final highlight = AyahHighlight(
        id: 'bookmark-36:1',
        polygonId: '36:1',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 1,
        type: AyahHighlightType.bookmark,
      );

      cubit.toggleBookmarkHighlight(highlight);
      expect(cubit.state.bookmarkHighlights.length, 1);
      expect(cubit.isBookmarked(36, 1), isTrue);
    });

    test('toggleBookmarkHighlight removes existing bookmark', () {
      final highlight = AyahHighlight(
        id: 'bookmark-36:1',
        polygonId: '36:1',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 1,
        type: AyahHighlightType.bookmark,
      );

      cubit.toggleBookmarkHighlight(highlight);
      expect(cubit.state.bookmarkHighlights.length, 1);

      cubit.toggleBookmarkHighlight(highlight);
      expect(cubit.state.bookmarkHighlights, isEmpty);
      expect(cubit.isBookmarked(36, 1), isFalse);
    });

    test('toggleBookmarkHighlight persists to storage', () {
      final highlight = AyahHighlight(
        id: 'bookmark-36:1',
        polygonId: '36:1',
        pageNumber: 440,
        surahNumber: 36,
        ayahNumber: 1,
        type: AyahHighlightType.bookmark,
      );

      cubit.toggleBookmarkHighlight(highlight);
      expect(repository.savedBookmarks.length, 1);
      expect(repository.savedBookmarks.first.ayahNumber, 1);
    });

    test('bookmarks are loaded from storage on init', () async {
      repository.setPreloadedBookmarks([
        AyahHighlight(
          id: 'bookmark-36:1',
          polygonId: '36:1',
          pageNumber: 440,
          surahNumber: 36,
          ayahNumber: 1,
          type: AyahHighlightType.bookmark,
        ),
        AyahHighlight(
          id: 'bookmark-1:1',
          polygonId: '1:1',
          pageNumber: 1,
          surahNumber: 1,
          ayahNumber: 1,
          type: AyahHighlightType.bookmark,
        ),
      ]);

      final newCubit = QuranHighlightCubit(repository);
      await Future(() {});

      expect(newCubit.isBookmarked(36, 1), isTrue);
      expect(newCubit.isBookmarked(1, 1), isTrue);
      expect(newCubit.state.bookmarkHighlights.length, 2);

      newCubit.close();
    });
  });

  group('isPolygonHighlighted', () {
    test('returns true when polygon is highlighted', () {
      final highlight = AyahHighlight(
        id: 'tap-1:1',
        polygonId: '1:1',
        pageNumber: 1,
        surahNumber: 1,
        ayahNumber: 1,
        type: AyahHighlightType.tap,
      );

      cubit.addTapHighlight(highlight);
      expect(cubit.isPolygonHighlighted('1:1', 1), isTrue);
    });

    test('returns false when polygon is not highlighted', () {
      expect(cubit.isPolygonHighlighted('1:1', 1), isFalse);
    });
  });

  group('clearAll', () {
    test('clears all highlights', () {
      cubit.addTapHighlight(
        AyahHighlight(
          id: 'tap-1:1',
          polygonId: '1:1',
          pageNumber: 1,
          surahNumber: 1,
          ayahNumber: 1,
          type: AyahHighlightType.tap,
        ),
      );
      cubit.clearAll();
      expect(cubit.state.highlights, isEmpty);
      expect(cubit.state.tapHighlightId, isNull);
      expect(cubit.state.readingHighlightId, isNull);
    });
  });

  group('clearTemporaryHighlights', () {
    test('removes non-bookmark highlights', () {
      cubit.addTapHighlight(
        AyahHighlight(
          id: 'tap-1:1',
          polygonId: '1:1',
          pageNumber: 1,
          surahNumber: 1,
          ayahNumber: 1,
          type: AyahHighlightType.tap,
        ),
      );
      cubit.toggleBookmarkHighlight(
        AyahHighlight(
          id: 'bookmark-36:1',
          polygonId: '36:1',
          pageNumber: 440,
          surahNumber: 36,
          ayahNumber: 1,
          type: AyahHighlightType.bookmark,
        ),
      );

      cubit.clearTemporaryHighlights();
      expect(cubit.state.tapHighlight, isNull);
      expect(cubit.state.bookmarkHighlights, isNotEmpty);
    });
  });
}
