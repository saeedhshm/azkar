import 'package:azkar/core/storage/local_storage_service.dart';

class LocalStorageServiceMock extends LocalStorageService {
  List<Map<String, dynamic>> _bookmarks = [];
  final List<Map<String, dynamic>> savedBookmarks = [];

  LocalStorageServiceMock() {
    _bookmarks = [];
  }

  void setPreloadedBookmarks(List<Map<String, dynamic>> bookmarks) {
    _bookmarks = List.from(bookmarks);
  }

  @override
  List<Map<String, dynamic>> getQuranBookmarks() {
    return List.from(_bookmarks);
  }

  @override
  Future<void> saveQuranBookmarks(List<Map<String, dynamic>> bookmarks) async {
    savedBookmarks.clear();
    savedBookmarks.addAll(bookmarks.map((e) => Map<String, dynamic>.from(e)));
    _bookmarks = List.from(bookmarks);
  }
}
