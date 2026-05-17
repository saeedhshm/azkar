import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../prayer_times/presentation/pages/prayer_times_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeAppBar(),
            const Expanded(child: PrayerTimesTab()),
          ],
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
      child: Row(
        children: [
          // App branding
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'app.name'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                _getGreeting(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Action buttons row
          _AppBarAction(
            icon: Icons.bookmark_rounded,
            tooltip: 'common.favorites'.tr(),
            onTap: () => context.push('/favorites'),
          ),
          const SizedBox(width: 6),
          _AppBarAction(
            icon: Icons.touch_app_rounded,
            tooltip: 'common.tasbeeh_counter'.tr(),
            onTap: () => context.push('/tasbeeh'),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'home.greetings.night'.tr();
    if (hour < 12) return 'home.greetings.morning'.tr();
    if (hour < 17) return 'home.greetings.afternoon'.tr();
    if (hour < 20) return 'home.greetings.evening'.tr();
    return 'home.greetings.late_night'.tr();
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
