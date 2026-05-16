import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../adhkar/presentation/pages/adhkar_categories_screen.dart';
import '../../../adhkar/presentation/pages/home_screen.dart';
import '../../../prayer_times/presentation/pages/qibla_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _index = 0;
  late final List<AnimationController> _iconControllers;

  static const _pageCount = 5;

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _pageCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
        lowerBound: 1.0,
        upperBound: 1.22,
      ),
    );
    // Trigger bounce for initial selection
    _iconControllers[0].forward().then((_) => _iconControllers[0].reverse());
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _index) return;
    HapticFeedback.lightImpact();
    setState(() => _index = index);
    _iconControllers[index]
        .forward()
        .then((_) => _iconControllers[index].reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const AppScaffoldBackground(particleCount: 80, particleSeed: 19),
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              QiblaScreen(),
              SizedBox.shrink(), // placeholder for center Quran tab
              AdhkarCategoriesScreen(),
              SettingsScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _ShellNavigationBar(
        selectedIndex: _index,
        iconControllers: _iconControllers,
        onSelected: _onTabSelected,
      ),
    );
  }
}

// ─── Navigation Bar ───────────────────────────────────────────────────────────

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.selectedIndex,
    required this.iconControllers,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<AnimationController> iconControllers;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = colors.accentColor ?? Theme.of(context).colorScheme.primary;

    final items = [
      _NavItemData(Icons.home_rounded, Icons.home_outlined, 'home.tabs.home'.tr()),
      _NavItemData(Icons.explore_rounded, Icons.explore_outlined, 'home.tabs.qibla'.tr()),
      _NavItemData(Icons.menu_book_rounded, Icons.menu_book_outlined, 'home.tabs.quran'.tr()),
      _NavItemData(Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'home.tabs.adhkar'.tr()),
      _NavItemData(Icons.settings_rounded, Icons.settings_outlined, 'home.tabs.settings'.tr()),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: SizedBox(
        height: 78,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Nav bar background
            Positioned.fill(
              top: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.navBarBg,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(color: colors.softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.22 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            // Nav items
            Positioned.fill(
              top: 10,
              child: Row(
                children: [
                  _NavItem(
                    item: items[0], index: 0,
                    selectedIndex: selectedIndex,
                    controller: iconControllers[0],
                    onSelected: onSelected,
                  ),
                  _NavItem(
                    item: items[1], index: 1,
                    selectedIndex: selectedIndex,
                    controller: iconControllers[1],
                    onSelected: onSelected,
                  ),
                  const Expanded(child: SizedBox()),
                  _NavItem(
                    item: items[3], index: 3,
                    selectedIndex: selectedIndex,
                    controller: iconControllers[3],
                    onSelected: onSelected,
                  ),
                  _NavItem(
                    item: items[4], index: 4,
                    selectedIndex: selectedIndex,
                    controller: iconControllers[4],
                    onSelected: onSelected,
                  ),
                ],
              ),
            ),
            // Center elevated Quran button
            Positioned(
              top: -4,
              child: _CenterNavButton(
                item: items[2],
                selected: selectedIndex == 2,
                controller: iconControllers[2],
                accentColor: accentColor,
                onTap: () => context.push('/quran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Center Elevated Button (Quran) ──────────────────────────────────────────

class _CenterNavButton extends StatelessWidget {
  const _CenterNavButton({
    required this.item,
    required this.selected,
    required this.controller,
    required this.accentColor,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final AnimationController controller;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          controller.forward().then((_) => controller.reverse());
          onTap();
        },
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, child) => Transform.scale(
            scale: controller.value,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.15),
                        accentColor,
                      ),
                      accentColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.5 : 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? accentColor
                      : AppThemeColors.of(context).mutedText,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Regular Nav Item ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.index,
    required this.selectedIndex,
    required this.controller,
    required this.onSelected,
  });

  final _NavItemData item;
  final int index;
  final int selectedIndex;
  final AnimationController controller;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final accentColor = colors.accentColor ?? theme.colorScheme.primary;
    final selected = index == selectedIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, child) => Transform.scale(
              scale: selected ? controller.value : 1.0,
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      key: ValueKey(selected),
                      size: 22,
                      color: selected
                          ? accentColor
                          : colors.mutedText.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                      color: selected
                          ? accentColor
                          : colors.mutedText.withValues(alpha: 0.82),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 9.5,
                    ),
                    child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _NavItemData {
  const _NavItemData(this.selectedIcon, this.icon, this.label);

  final IconData selectedIcon;
  final IconData icon;
  final String label;
}
