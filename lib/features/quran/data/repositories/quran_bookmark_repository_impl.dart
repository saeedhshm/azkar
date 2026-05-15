import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/ayah_highlight.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';

class QuranBookmarkRepositoryImpl implements QuranBookmarkRepository {
  QuranBookmarkRepositoryImpl(this._localStorage);

  final LocalStorageService _localStorage;

  @override
  List<AyahHighlight> getAll() {
    final raw = _localStorage.getQuranBookmarks();
    return raw.map(_parseEntry).whereType<AyahHighlight>().toList();
  }

  @override
  Future<void> replaceAll(List<AyahHighlight> bookmarks) {
    final raw = bookmarks
        .map((h) => <String, dynamic>{
              'surah': h.surahNumber,
              'ayah': h.ayahNumber,
              'page': h.pageNumber,
            })
        .toList();
    return _localStorage.saveQuranBookmarks(raw);
  }

  @override
  bool isBookmarked(int surahNumber, int ayahNumber) {
    final bookmarks = _localStorage.getQuranBookmarks();
    return bookmarks.any(
      (b) => b['surah'] == surahNumber && b['ayah'] == ayahNumber,
    );
  }

  @override
  int bookmarkCount() {
    return _localStorage.getQuranBookmarks().length;
  }

  @override
  int bookmarkCountForPage(int pageNumber) {
    final bookmarks = _localStorage.getQuranBookmarks();
    return bookmarks.where((b) => b['page'] == pageNumber).length;
  }

  @override
  List<AyahHighlight> bookmarksForPage(int pageNumber) {
    final raw = _localStorage.getQuranBookmarks();
    return raw
        .where((b) => b['page'] == pageNumber)
        .map(_parseEntry)
        .whereType<AyahHighlight>()
        .toList();
  }

  AyahHighlight? _parseEntry(Map<String, dynamic> entry) {
    final surah = entry['surah'] as int?;
    final ayah = entry['ayah'] as int?;
    final page = entry['page'] as int?;
    if (surah == null || ayah == null || page == null) return null;
    return AyahHighlight(
      id: 'bookmark-$surah:$ayah',
      polygonId: '$surah:$ayah',
      pageNumber: page,
      surahNumber: surah,
      ayahNumber: ayah,
      type: AyahHighlightType.bookmark,
    );
  }
}
