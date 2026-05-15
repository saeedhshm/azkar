class Reciter {
  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.style,
    required this.surahUrlTemplate,
    required this.timingSource,
  });

  final String id;
  final String name;
  final String arabicName;
  final String style;
  final String surahUrlTemplate;
  final String timingSource;

  String surahUrl(int surahNumber) {
    return surahUrlTemplate.replaceAll('{surah}', surahNumber.toString());
  }

  static const List<Reciter> defaults = [
    Reciter(
      id: 'ar.abdurrahmaansudais',
      name: 'Abdurrahman As-Sudais',
      arabicName: 'عبد الرحمن السديس',
      style: 'Hafs',
      surahUrlTemplate:
          'https://cdn.islamic.network/quran/audio/128/ar.abdurrahmaansudais/{surah}.mp3',
      timingSource: 'hafs_128kbps',
    ),
    Reciter(
      id: 'ar.shaatree',
      name: 'Abu Bakr Ash-Shatri',
      arabicName: 'أبو بكر الشاطري',
      style: 'Hafs',
      surahUrlTemplate:
          'https://cdn.islamic.network/quran/audio/128/ar.shaatree/{surah}.mp3',
      timingSource: 'hafs_128kbps',
    ),
    Reciter(
      id: 'ar.mahermuaiqly',
      name: 'Maher Al-Muaiqly',
      arabicName: 'ماهر المعيقلي',
      style: 'Hafs',
      surahUrlTemplate:
          'https://cdn.islamic.network/quran/audio/128/ar.mahermuaiqly/{surah}.mp3',
      timingSource: 'hafs_128kbps',
    ),
    Reciter(
      id: 'ar.husarymujawwad',
      name: 'Mahmoud Khalil Al-Husary',
      arabicName: 'محمود خليل الحصري',
      style: 'Hafs',
      surahUrlTemplate:
          'https://cdn.islamic.network/quran/audio/128/ar.husarymujawwad/{surah}.mp3',
      timingSource: 'hafs_128kbps',
    ),
    Reciter(
      id: 'ar.ahmedajamy',
      name: 'Ahmed Al-Ajamy',
      arabicName: 'أحمد العجمي',
      style: 'Hafs',
      surahUrlTemplate:
          'https://cdn.islamic.network/quran/audio/128/ar.ahmedajamy/{surah}.mp3',
      timingSource: 'hafs_128kbps',
    ),
  ];
}
