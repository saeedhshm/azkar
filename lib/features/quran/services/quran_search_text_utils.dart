class QuranSearchTextUtils {
  QuranSearchTextUtils._();

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> tokenize(String normalized) {
    return normalized.split(' ').where((w) => w.isNotEmpty).toList();
  }

  static List<WordMatch> findMatches(String original, String normalizedQuery) {
    final matches = <WordMatch>[];
    final words = original.split(' ');
    var offset = 0;
    for (final word in words) {
      final normalized = normalize(word);
      final wordLen = word.length;
      if (normalized.contains(normalizedQuery) || normalizedQuery.contains(normalized)) {
        matches.add(WordMatch(start: offset, end: offset + wordLen));
      }
      offset += wordLen + 1;
    }
    return matches;
  }
}

class WordMatch {
  const WordMatch({required this.start, required this.end});
  final int start;
  final int end;
}
