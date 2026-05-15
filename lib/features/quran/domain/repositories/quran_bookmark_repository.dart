import '../entities/ayah_highlight.dart';

abstract class QuranBookmarkRepository {
  List<AyahHighlight> getAll();

  Future<void> replaceAll(List<AyahHighlight> bookmarks);

  bool isBookmarked(int surahNumber, int ayahNumber);

  int bookmarkCount();

  int bookmarkCountForPage(int pageNumber);

  List<AyahHighlight> bookmarksForPage(int pageNumber);
}
