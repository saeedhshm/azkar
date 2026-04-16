import 'dart:math';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/app_categories.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../widgets/category_card.dart';
import '../../../prayer_times/presentation/pages/prayer_times_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Map<String, int>> _countsFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCategoryCounts();
  }

  Future<Map<String, int>> _loadCategoryCounts() async {
    final repository = getIt<AdhkarRepository>();
    final all = await repository.getAllAdhkar();
    final counts = <String, int>{};

    for (final item in all) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF7A5A35);
    final barColor = isDark ? const Color(0xFF0B1322) : const Color(0xFFF3E7D2);
    final barBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFC9A77A).withValues(alpha: 0.5);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('app.name'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'common.favorites'.tr(),
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.bookmark_outline),
          ),
          IconButton(
            tooltip: 'common.tasbeeh_counter'.tr(),
            onPressed: () => context.push('/tasbeeh'),
            icon: const Icon(Icons.touch_app_outlined),
          ),
          IconButton(
            tooltip: 'common.settings'.tr(),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _QuranFab(
        isDark: isDark,
        onTap: () => context.push('/quran'),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BottomAppBar(
          color: barColor,
          elevation: 10,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: barBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BottomNavItem(
                  label: 'home.tabs.prayer_times'.tr(),
                  icon: Icons.access_time_rounded,
                  isSelected: _currentIndex == 0,
                  selectedColor: accentColor,
                  unselectedColor: unselectedColor,
                  showLabel: false,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                const SizedBox(width: 72),
                _BottomNavItem(
                  label: 'home.tabs.adhkar'.tr(),
                  icon: Icons.auto_awesome_rounded,
                  isSelected: _currentIndex == 1,
                  selectedColor: accentColor,
                  unselectedColor: unselectedColor,
                  showLabel: false,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _HomeBackground(isDark: isDark),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const PrayerTimesTab(),
                _AdhkarTab(countsFuture: _countsFuture),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranFab extends StatelessWidget {
  const _QuranFab({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);
    final baseColor = isDark ? const Color(0xFF10243A) : const Color(0xFFF9EFE0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onTap,
          elevation: 8,
          backgroundColor: baseColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Icon(
            Icons.menu_book_rounded,
            color: accentColor,
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'home.tabs.quran'.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accentColor,
              ),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        height: 1.0,
                        fontSize: 10,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdhkarTab extends StatelessWidget {
  const _AdhkarTab({required this.countsFuture});

  final Future<Map<String, int>> countsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: countsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final counts = snapshot.data ?? <String, int>{};

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          itemCount: AppCategories.sections.length,
          itemBuilder: (context, sectionIndex) {
            final section = AppCategories.sections[sectionIndex];
            final sectionItems = AppCategories.itemsBySection(section.key);

            if (sectionItems.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.titleKey.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          section.subtitleKey.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount =
                          width >= 1000 ? 4 : width >= 700 ? 3 : 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sectionItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, itemIndex) {
                          final category = sectionItems[itemIndex];

                          return CategoryCard(
                            category: category,
                            index: itemIndex,
                            itemCount: counts[category.key] ?? 0,
                            onTap: () {
                              context.push('/adhkar/${category.key}');
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1220), Color(0xFF0F1C2E), Color(0xFF071A1B)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E7D2), Color(0xFFECD9BF), Color(0xFFE3C9A6)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: CustomPaint(
        painter: _SoftDustPainter(isDark: isDark),
        child: Container(),
      ),
    );
  }
}

class _SoftDustPainter extends CustomPainter {
  _SoftDustPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(6);
    final count = isDark ? 90 : 60;
    final baseOpacity = isDark ? 0.4 : 0.2;

    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.3 + 0.2;
      final opacity = baseOpacity + random.nextDouble() * 0.4;
      final paint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFFB48A45)).withValues(
          alpha: opacity,
        );
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
