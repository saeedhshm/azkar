import 'package:azkar/features/quran/domain/entities/ayah_highlight.dart';
import 'package:azkar/features/quran/domain/repositories/quran_bookmark_repository.dart';

class QuranBookmarkRepositoryMock implements QuranBookmarkRepository {
  final List<AyahHighlight> _bookmarks = [];
  final List<AyahHighlight> savedBookmarks = [];

  void setPreloadedBookmarks(List<AyahHighlight> bookmarks) {
    _bookmarks.clear();
    _bookmarks.addAll(bookmarks);
  }

  @override
  List<AyahHighlight> getAll() {
    return List.from(_bookmarks);
  }

  @override
  Future<void> replaceAll(List<AyahHighlight> bookmarks) async {
    savedBookmarks.clear();
    savedBookmarks.addAll(bookmarks.map((e) => e));
    _bookmarks.clear();
    _bookmarks.addAll(bookmarks);
  }

  @override
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _bookmarks.any(
      (h) => h.surahNumber == surahNumber && h.ayahNumber == ayahNumber,
    );
  }

  @override
  int bookmarkCount() => _bookmarks.length;

  @override
  int bookmarkCountForPage(int pageNumber) {
    return _bookmarks.where((h) => h.pageNumber == pageNumber).length;
  }

  @override
  List<AyahHighlight> bookmarksForPage(int pageNumber) {
    return _bookmarks.where((h) => h.pageNumber == pageNumber).toList();
  }
}
