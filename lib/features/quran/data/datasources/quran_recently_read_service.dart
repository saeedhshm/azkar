import '../../../../core/storage/local_storage_service.dart';

class RecentlyReadEntry {
  const RecentlyReadEntry({
    required this.pageNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.timestamp,
  });

  final int pageNumber;
  final int surahNumber;
  final int ayahNumber;
  final int timestamp;

  Map<String, dynamic> toJson() => {
    'page': pageNumber,
    'surah': surahNumber,
    'ayah': ayahNumber,
    'ts': timestamp,
  };

  factory RecentlyReadEntry.fromJson(Map<String, dynamic> json) =>
    RecentlyReadEntry(
      pageNumber: json['page'] as int,
      surahNumber: json['surah'] as int,
      ayahNumber: json['ayah'] as int,
      timestamp: json['ts'] as int,
    );
}

class QuranRecentlyReadService {
  QuranRecentlyReadService(this._storage);

  final LocalStorageService _storage;
  static const int _maxEntries = 20;
  static const String _key = 'quran_recently_read';

  List<RecentlyReadEntry> getAll() {
    final raw = _storage.getRaw(_key);
    if (raw is! List) return [];

    final entries = <RecentlyReadEntry>[];
    for (final item in raw) {
      // Hive decodes stored maps as Map<dynamic, dynamic>, so the entries must
      // be converted rather than filtered by a strict type check.
      if (item is! Map) {
        continue;
      }

      final json = Map<String, dynamic>.from(item);
      final entry = _tryParse(json);
      if (entry != null) {
        entries.add(entry);
      }
    }
    return entries;
  }

  /// Parses a stored entry, returning `null` for malformed data.
  ///
  /// A corrupt entry must never prevent the remaining history from loading.
  static RecentlyReadEntry? _tryParse(Map<String, dynamic> json) {
    final page = _asInt(json['page']);
    final surah = _asInt(json['surah']);
    final ayah = _asInt(json['ayah']);
    final timestamp = _asInt(json['ts']);

    if (page == null || surah == null || ayah == null || timestamp == null) {
      return null;
    }

    return RecentlyReadEntry(
      pageNumber: page,
      surahNumber: surah,
      ayahNumber: ayah,
      timestamp: timestamp,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  void addEntry(int page, int surah, int ayah) {
    final entries = getAll();
    entries.removeWhere((e) => e.pageNumber == page);
    entries.insert(
      0,
      RecentlyReadEntry(
        pageNumber: page,
        surahNumber: surah,
        ayahNumber: ayah,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    _storage.putRaw(
      _key,
      entries.map((e) => e.toJson()).toList(),
    );
  }

  void removeEntry(RecentlyReadEntry entry) {
    final entries = getAll();
    entries.removeWhere(
      (e) => e.pageNumber == entry.pageNumber && e.timestamp == entry.timestamp,
    );
    _storage.putRaw(
      _key,
      entries.map((e) => e.toJson()).toList(),
    );
  }

  void clear() {
    _storage.putRaw(_key, []);
  }
}
