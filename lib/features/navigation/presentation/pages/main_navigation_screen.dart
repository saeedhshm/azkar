import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../adhkar/presentation/pages/adhkar_categories_screen.dart';
import '../../../adhkar/presentation/pages/home_screen.dart';
import '../../../prayer_times/presentation/pages/qibla_screen.dart';
import '../../../quran/presentation/pages/quran_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const _AppShellBackground(),
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              QiblaScreen(),
              QuranScreen(),
              AdhkarCategoriesScreen(),
              SettingsScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _ShellNavigationBar(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navColor = colors.cardSurface;
    final shadowColor = theme.colorScheme.shadow;
    final items = [
      _NavItemData(Icons.home_rounded, 'home.tabs.home'.tr()),
      _NavItemData(Icons.explore_rounded, 'home.tabs.qibla'.tr()),
      _NavItemData(Icons.menu_book_rounded, 'home.tabs.quran'.tr()),
      _NavItemData(Icons.auto_stories_rounded, 'home.tabs.adhkar'.tr()),
      _NavItemData(Icons.settings_rounded, 'home.tabs.settings'.tr()),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: SizedBox(
        height: 74,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: navColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              top: 12,
              child: Row(
                children: [
                  _NavItem(
                    item: items[0],
                    index: 0,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                  ),
                  _NavItem(
                    item: items[1],
                    index: 1,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                  ),
                  const Expanded(child: SizedBox()),
                  _NavItem(
                    item: items[3],
                    index: 3,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                  ),
                  _NavItem(
                    item: items[4],
                    index: 4,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -2,
              child: _CenterNavButton(
                item: items[2],
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  const _CenterNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.9);
    final fg = theme.colorScheme.onPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(item.icon, color: fg, size: 25),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? theme.colorScheme.primary : colors.mutedText,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
  });

  final _NavItemData item;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final selected = index == selectedIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 21,
                  color: selected
                      ? theme.colorScheme.primary
                      : colors.mutedText.withValues(alpha: 0.78),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : colors.mutedText.withValues(alpha: 0.85),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _AppShellBackground extends StatelessWidget {
  const _AppShellBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              colors.heroCardBackground.withValues(alpha: isDark ? 0.06 : 0.3),
              theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _DustPainter(isDark: isDark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  _DustPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(19);
    final paint = Paint();
    final color = isDark ? Colors.white : const Color(0xFF5D4037);

    for (var i = 0; i < 80; i++) {
      paint.color = color.withValues(alpha: isDark ? 0.16 : 0.08);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.2 + 0.25,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
