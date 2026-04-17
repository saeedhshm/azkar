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
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: Colors.transparent,
        title: Text(
          'app.name'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'common.favorites'.tr(),
            icon: const Icon(Icons.bookmark_border_rounded, size: 22),
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            tooltip: 'common.tasbeeh_counter'.tr(),
            icon: const Icon(Icons.touch_app_outlined, size: 22),
            onPressed: () => context.push('/tasbeeh'),
          ),
          IconButton(
            tooltip: 'common.settings'.tr(),
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      body: const SafeArea(top: false, child: PrayerTimesTab()),
    );
  }
}
