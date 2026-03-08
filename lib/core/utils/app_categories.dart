import 'package:flutter/material.dart';

class CategorySection {
  const CategorySection({
    required this.key,
    required this.titleKey,
    required this.subtitleKey,
  });

  final String key;
  final String titleKey;
  final String subtitleKey;
}

class CategoryInfo {
  const CategoryInfo({
    required this.key,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.colors,
    required this.sectionKey,
  });

  final String key;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final List<Color> colors;
  final String sectionKey;

  static CategoryInfo fallback(String key) {
    return CategoryInfo(
      key: key,
      titleKey: 'categories.$key.title',
      subtitleKey: 'categories.$key.subtitle',
      icon: Icons.menu_book_outlined,
      colors: const [Color(0xFF4A90E2), Color(0xFF50C9C3)],
      sectionKey: 'general',
    );
  }
}

class AppCategories {
  AppCategories._();

  static const List<CategorySection> sections = [
    CategorySection(
      key: 'daily',
      titleKey: 'home.sections.daily.title',
      subtitleKey: 'home.sections.daily.subtitle',
    ),
    CategorySection(
      key: 'prayer',
      titleKey: 'home.sections.prayer.title',
      subtitleKey: 'home.sections.prayer.subtitle',
    ),
    CategorySection(
      key: 'general',
      titleKey: 'home.sections.general.title',
      subtitleKey: 'home.sections.general.subtitle',
    ),
    CategorySection(
      key: 'quran',
      titleKey: 'home.sections.quran.title',
      subtitleKey: 'home.sections.quran.subtitle',
    ),
    CategorySection(
      key: 'life',
      titleKey: 'home.sections.life.title',
      subtitleKey: 'home.sections.life.subtitle',
    ),
  ];

  static const List<CategoryInfo> items = [
    CategoryInfo(
      key: 'morning_adhkar',
      titleKey: 'categories.morning_adhkar.title',
      subtitleKey: 'categories.morning_adhkar.subtitle',
      icon: Icons.wb_sunny_outlined,
      colors: [Color(0xFFFABF75), Color(0xFFF3904F)],
      sectionKey: 'daily',
    ),
    CategoryInfo(
      key: 'evening_adhkar',
      titleKey: 'categories.evening_adhkar.title',
      subtitleKey: 'categories.evening_adhkar.subtitle',
      icon: Icons.nights_stay_outlined,
      colors: [Color(0xFF8E9EAB), Color(0xFF3B4653)],
      sectionKey: 'daily',
    ),
    CategoryInfo(
      key: 'sleep_adhkar',
      titleKey: 'categories.sleep_adhkar.title',
      subtitleKey: 'categories.sleep_adhkar.subtitle',
      icon: Icons.bedtime_outlined,
      colors: [Color(0xFF614385), Color(0xFF516395)],
      sectionKey: 'daily',
    ),
    CategoryInfo(
      key: 'waking_up',
      titleKey: 'categories.waking_up.title',
      subtitleKey: 'categories.waking_up.subtitle',
      icon: Icons.alarm_outlined,
      colors: [Color(0xFF43C6AC), Color(0xFF191654)],
      sectionKey: 'daily',
    ),
    CategoryInfo(
      key: 'after_prayer',
      titleKey: 'categories.after_prayer.title',
      subtitleKey: 'categories.after_prayer.subtitle',
      icon: Icons.mosque_outlined,
      colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
      sectionKey: 'prayer',
    ),
    CategoryInfo(
      key: 'after_wudu',
      titleKey: 'categories.after_wudu.title',
      subtitleKey: 'categories.after_wudu.subtitle',
      icon: Icons.water_drop_outlined,
      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
      sectionKey: 'prayer',
    ),
    CategoryInfo(
      key: 'after_adhan',
      titleKey: 'categories.after_adhan.title',
      subtitleKey: 'categories.after_adhan.subtitle',
      icon: Icons.campaign_outlined,
      colors: [Color(0xFF1D976C), Color(0xFF93F9B9)],
      sectionKey: 'prayer',
    ),
    CategoryInfo(
      key: 'tasbeeh',
      titleKey: 'categories.tasbeeh.title',
      subtitleKey: 'categories.tasbeeh.subtitle',
      icon: Icons.track_changes_outlined,
      colors: [Color(0xFFB24592), Color(0xFFF15F79)],
      sectionKey: 'general',
    ),
    CategoryInfo(
      key: 'istighfar',
      titleKey: 'categories.istighfar.title',
      subtitleKey: 'categories.istighfar.subtitle',
      icon: Icons.refresh_outlined,
      colors: [Color(0xFF355C7D), Color(0xFF6C5B7B)],
      sectionKey: 'general',
    ),
    CategoryInfo(
      key: 'salawat_on_prophet',
      titleKey: 'categories.salawat_on_prophet.title',
      subtitleKey: 'categories.salawat_on_prophet.subtitle',
      icon: Icons.favorite_outline,
      colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
      sectionKey: 'general',
    ),
    CategoryInfo(
      key: 'duas_from_quran',
      titleKey: 'categories.duas_from_quran.title',
      subtitleKey: 'categories.duas_from_quran.subtitle',
      icon: Icons.menu_book_outlined,
      colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
      sectionKey: 'quran',
    ),
    CategoryInfo(
      key: 'entering_home',
      titleKey: 'categories.entering_home.title',
      subtitleKey: 'categories.entering_home.subtitle',
      icon: Icons.home_outlined,
      colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'leaving_home',
      titleKey: 'categories.leaving_home.title',
      subtitleKey: 'categories.leaving_home.subtitle',
      icon: Icons.logout_outlined,
      colors: [Color(0xFF1FA2FF), Color(0xFF12D8FA)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'entering_mosque',
      titleKey: 'categories.entering_mosque.title',
      subtitleKey: 'categories.entering_mosque.subtitle',
      icon: Icons.account_balance_outlined,
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'leaving_mosque',
      titleKey: 'categories.leaving_mosque.title',
      subtitleKey: 'categories.leaving_mosque.subtitle',
      icon: Icons.directions_walk_outlined,
      colors: [Color(0xFF4B79A1), Color(0xFF283E51)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'travel',
      titleKey: 'categories.travel.title',
      subtitleKey: 'categories.travel.subtitle',
      icon: Icons.airplanemode_active_outlined,
      colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'rain',
      titleKey: 'categories.rain.title',
      subtitleKey: 'categories.rain.subtitle',
      icon: Icons.cloud_outlined,
      colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'illness',
      titleKey: 'categories.illness.title',
      subtitleKey: 'categories.illness.subtitle',
      icon: Icons.healing_outlined,
      colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'distress',
      titleKey: 'categories.distress.title',
      subtitleKey: 'categories.distress.subtitle',
      icon: Icons.self_improvement_outlined,
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      sectionKey: 'life',
    ),
    CategoryInfo(
      key: 'gratitude',
      titleKey: 'categories.gratitude.title',
      subtitleKey: 'categories.gratitude.subtitle',
      icon: Icons.volunteer_activism_outlined,
      colors: [Color(0xFFF09819), Color(0xFFEDDE5D)],
      sectionKey: 'life',
    ),
  ];

  static List<CategoryInfo> itemsBySection(String sectionKey) {
    return items.where((item) => item.sectionKey == sectionKey).toList();
  }

  static CategoryInfo byKey(String key) {
    for (final item in items) {
      if (item.key == key) {
        return item;
      }
    }

    return CategoryInfo.fallback(key);
  }
}
