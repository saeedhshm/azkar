import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/islamic_icon.dart';
import '../../../adhkar/presentation/pages/adhkar_categories_screen.dart';
import '../../../adhkar/presentation/pages/home_screen.dart';
import '../../../prayer_times/presentation/pages/qibla_screen.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, 'home.tabs.home'),
      (Icons.explore_outlined, Icons.explore_rounded, 'home.tabs.qibla'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'home.tabs.quran'),
      (
        Icons.auto_stories_outlined,
        Icons.auto_stories_rounded,
        'home.tabs.adhkar',
      ),
      (Icons.tune_rounded, Icons.tune_rounded, 'home.tabs.settings'),
    ];
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const AppScaffoldBackground(),
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              QiblaScreen(),
              SizedBox.shrink(),
              AdhkarCategoriesScreen(),
              SettingsScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .7),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A332D).withValues(
                  alpha: theme.brightness == Brightness.dark ? .3 : .08,
                ),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == _index,
                    button: true,
                    label: destinations[i].$3.tr(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (i == 2) {
                          context.push('/quran');
                        } else {
                          setState(() => _index = i);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              width: 46,
                              height: 34,
                              decoration: BoxDecoration(
                                color: i == 2
                                    ? scheme.primary
                                    : i == _index
                                    ? scheme.primary.withValues(alpha: .09)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: i == 2
                                    ? IslamicIcon(
                                        type: IslamicIconType.quran,
                                        color: scheme.onPrimary,
                                        size: 23,
                                      )
                                    : Icon(
                                        i == _index
                                            ? destinations[i].$2
                                            : destinations[i].$1,
                                        size: 23,
                                        color: i == _index
                                            ? scheme.primary
                                            : scheme.onSurface.withValues(
                                                alpha: .5,
                                              ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              destinations[i].$3.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: i == _index
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: i == _index
                                    ? scheme.primary
                                    : scheme.onSurface.withValues(alpha: .6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
