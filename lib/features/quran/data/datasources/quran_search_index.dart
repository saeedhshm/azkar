import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_surah.dart';
import '../../services/quran_search_text_utils.dart';

class AyahRef {
  const AyahRef({
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
  });

  final int surahNumber;
  final int ayahNumber;
  final int page;
}

class SearchMatch {
  SearchMatch({
    required this.ref,
    required this.matchedWord,
  });

  final AyahRef ref;
  String matchedWord;
  int score = 0;
}

class QuranSearchIndex {
  Map<String, List<AyahRef>>? _wordIndex;
  List<String>? _allWords;
  bool _built = false;

  static const int maxResults = 80;

  bool get isBuilt => _built;

  void build(List<QuranSurah> surahs) {
    _wordIndex = <String, List<AyahRef>>{};
    for (final surah in surahs) {
      for (final ayah in surah.ayahs) {
        _indexAyah(surah.number, ayah);
      }
    }
    _allWords = _wordIndex!.keys.toList(growable: false);
    _built = true;
  }

  void _indexAyah(int surahNumber, QuranAyah ayah) {
    final normalized = QuranSearchTextUtils.normalize(ayah.text);
    final words = QuranSearchTextUtils.tokenize(normalized);
    final unique = words.toSet();
    for (final word in unique) {
      _wordIndex!
          .putIfAbsent(word, () => <AyahRef>[])
          .add(AyahRef(
            surahNumber: surahNumber,
            ayahNumber: ayah.numberInSurah,
            page: ayah.page,
          ));
    }
  }

  List<SearchMatch> search(String normalizedQuery) {
    if (!_built || _wordIndex == null || _allWords == null) {
      return const <SearchMatch>[];
    }

    final queryWords = QuranSearchTextUtils.tokenize(normalizedQuery);
    if (queryWords.isEmpty) return const <SearchMatch>[];

    final matchMap = <String, SearchMatch>{};

    for (final queryWord in queryWords) {
      final exactRefs = _wordIndex![queryWord];
      if (exactRefs != null) {
        for (final ref in exactRefs) {
          final key = '${ref.surahNumber}:${ref.ayahNumber}';
          final existing = matchMap.putIfAbsent(
            key,
            () => SearchMatch(ref: ref, matchedWord: queryWord),
          );
          existing.score += 3;
        }
      }

      for (final indexedWord in _allWords!) {
        if (indexedWord.length > queryWord.length &&
            indexedWord.startsWith(queryWord)) {
          final refs = _wordIndex![indexedWord]!;
          for (final ref in refs) {
            final key = '${ref.surahNumber}:${ref.ayahNumber}';
            final existing = matchMap.putIfAbsent(
              key,
              () => SearchMatch(ref: ref, matchedWord: indexedWord),
            );
            if (existing.matchedWord == queryWord) {
              existing.matchedWord = indexedWord;
            }
            existing.score += 2;
          }
        }
      }
    }

    final matches = matchMap.values.toList(growable: false);
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(maxResults).toList(growable: false);
  }
}
