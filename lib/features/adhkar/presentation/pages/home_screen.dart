import 'dart:math';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/app_categories.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Map<String, int>> _countsFuture;

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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              labelColor: accentColor,
              unselectedLabelColor: unselectedColor,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: accentColor, width: 3),
                insets: const EdgeInsets.symmetric(horizontal: 24),
              ),
              tabs: [
                Tab(text: 'home.tabs.prayer_times'.tr()),
                Tab(text: 'home.tabs.adhkar'.tr()),
                Tab(text: 'home.tabs.quran'.tr()),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            _HomeBackground(isDark: isDark),
            SafeArea(
              child: TabBarView(
                children: [
                  _PlaceholderTab(
                    title: 'home.tabs.prayer_times'.tr(),
                    icon: Icons.access_time_rounded,
                    isDark: isDark,
                  ),
                  _AdhkarTab(countsFuture: _countsFuture),
                  _PlaceholderTab(
                    title: 'home.tabs.quran'.tr(),
                    icon: Icons.menu_book_rounded,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFBFA272).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 26,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 42, color: accentColor),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'home.placeholder'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
