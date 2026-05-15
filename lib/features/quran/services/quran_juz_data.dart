class QuranJuzData {
  const QuranJuzData({
    required this.number,
    required this.startPage,
    required this.endPage,
    required this.startSurah,
    required this.startAyah,
  });

  final int number;
  final int startPage;
  final int endPage;
  final int startSurah;
  final int startAyah;

  int get pageCount => endPage - startPage + 1;

  static const List<QuranJuzData> all = [
    QuranJuzData(number: 1, startPage: 1, endPage: 21, startSurah: 1, startAyah: 1),
    QuranJuzData(number: 2, startPage: 22, endPage: 41, startSurah: 2, startAyah: 142),
    QuranJuzData(number: 3, startPage: 42, endPage: 61, startSurah: 2, startAyah: 253),
    QuranJuzData(number: 4, startPage: 62, endPage: 81, startSurah: 3, startAyah: 93),
    QuranJuzData(number: 5, startPage: 82, endPage: 101, startSurah: 4, startAyah: 24),
    QuranJuzData(number: 6, startPage: 102, endPage: 120, startSurah: 4, startAyah: 148),
    QuranJuzData(number: 7, startPage: 121, endPage: 141, startSurah: 5, startAyah: 82),
    QuranJuzData(number: 8, startPage: 142, endPage: 161, startSurah: 6, startAyah: 111),
    QuranJuzData(number: 9, startPage: 162, endPage: 181, startSurah: 7, startAyah: 88),
    QuranJuzData(number: 10, startPage: 182, endPage: 201, startSurah: 8, startAyah: 41),
    QuranJuzData(number: 11, startPage: 202, endPage: 221, startSurah: 9, startAyah: 93),
    QuranJuzData(number: 12, startPage: 222, endPage: 241, startSurah: 11, startAyah: 6),
    QuranJuzData(number: 13, startPage: 242, endPage: 261, startSurah: 12, startAyah: 53),
    QuranJuzData(number: 14, startPage: 262, endPage: 281, startSurah: 15, startAyah: 1),
    QuranJuzData(number: 15, startPage: 282, endPage: 301, startSurah: 17, startAyah: 1),
    QuranJuzData(number: 16, startPage: 302, endPage: 321, startSurah: 18, startAyah: 75),
    QuranJuzData(number: 17, startPage: 322, endPage: 341, startSurah: 21, startAyah: 1),
    QuranJuzData(number: 18, startPage: 342, endPage: 361, startSurah: 23, startAyah: 1),
    QuranJuzData(number: 19, startPage: 362, endPage: 381, startSurah: 25, startAyah: 21),
    QuranJuzData(number: 20, startPage: 382, endPage: 401, startSurah: 27, startAyah: 56),
    QuranJuzData(number: 21, startPage: 402, endPage: 421, startSurah: 29, startAyah: 46),
    QuranJuzData(number: 22, startPage: 422, endPage: 441, startSurah: 33, startAyah: 31),
    QuranJuzData(number: 23, startPage: 442, endPage: 461, startSurah: 36, startAyah: 28),
    QuranJuzData(number: 24, startPage: 462, endPage: 481, startSurah: 39, startAyah: 32),
    QuranJuzData(number: 25, startPage: 482, endPage: 501, startSurah: 41, startAyah: 47),
    QuranJuzData(number: 26, startPage: 502, endPage: 521, startSurah: 46, startAyah: 1),
    QuranJuzData(number: 27, startPage: 522, endPage: 541, startSurah: 51, startAyah: 31),
    QuranJuzData(number: 28, startPage: 542, endPage: 561, startSurah: 58, startAyah: 1),
    QuranJuzData(number: 29, startPage: 562, endPage: 581, startSurah: 67, startAyah: 1),
    QuranJuzData(number: 30, startPage: 582, endPage: 604, startSurah: 78, startAyah: 1),
  ];

  static int juzForPage(int page) {
    int result = 1;
    for (final juz in all) {
      if (juz.startPage <= page) {
        result = juz.number;
      } else {
        break;
      }
    }
    return result;
  }

  static QuranJuzData? forNumber(int number) {
    if (number < 1 || number > 30) return null;
    return all[number - 1];
  }

  static double juzProgress(int currentPage) {
    for (final juz in all) {
      if (currentPage >= juz.startPage && currentPage <= juz.endPage) {
        final pagesIn = currentPage - juz.startPage + 1;
        return pagesIn / juz.pageCount;
      }
    }
    return 0.0;
  }

  static QuranJuzData? juzForSurah(int surahNumber) {
    for (final juz in all.reversed) {
      if (juz.startSurah <= surahNumber) {
        return juz;
      }
    }
    return null;
  }

  static List<QuranJuzData> juzsForSurah(int surahNumber) {
    final result = <QuranJuzData>[];
    for (final juz in all) {
      if (juz.startSurah <= surahNumber) {
        if (result.isNotEmpty &&
            result.last.startSurah == juz.startSurah) {
          result.removeLast();
        }
        result.add(juz);
      }
      if (result.length > 1 && juz.startSurah > surahNumber) {
        break;
      }
    }
    if (result.isEmpty) {
      result.add(all.last);
    }
    return result;
  }
}
