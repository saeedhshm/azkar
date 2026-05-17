import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/quran_juz_data.dart';

class QuranQuickNavBar extends StatelessWidget {
  const QuranQuickNavBar({
    super.key,
    required this.currentPage,
    required this.currentSurahName,
    required this.currentSurahNumber,
    required this.onSurahTap,
    required this.onJuzTap,
    required this.onPageTap,
  });

  final int currentPage;
  final String currentSurahName;
  final int currentSurahNumber;
  final VoidCallback onSurahTap;
  final VoidCallback onJuzTap;
  final VoidCallback onPageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerLow;
    final outline = theme.colorScheme.outlineVariant;
    final muted = onSurface.withValues(alpha: 0.5);

    final currentJuz = QuranJuzData.juzForPage(currentPage);
    final juzProgress = QuranJuzData.juzProgress(currentPage);

    return GestureDetector(
      onTap: onPageTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavChip(
              label: currentSurahName,
              icon: Icons.article_rounded,
              onTap: onSurahTap,
              color: muted,
            ),
            Container(
              width: 1,
              height: 18,
              color: outline,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            _NavChip(
              label: '${'quran.juz'.tr()} $currentJuz',
              icon: Icons.auto_stories_rounded,
              onTap: onJuzTap,
              color: muted,
              suffix: juzProgress > 0 && juzProgress < 1
                  ? _buildJuzProgress(juzProgress, primary, outline)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJuzProgress(double progress, Color primary, Color outline) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 20,
        height: 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: outline.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(primary),
            minHeight: 3,
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    this.suffix,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 11,
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ),
    );
  }
}
