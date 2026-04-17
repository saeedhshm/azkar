import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'progress_prayer_bar.dart';

class NextPrayerHeroCard extends StatelessWidget {
  const NextPrayerHeroCard({
    super.key,
    required this.label,
    required this.prayerName,
    required this.countdown,
    required this.currentContext,
    required this.nextPrayerTimeLine,
    required this.progressStartLabel,
    required this.progressEndLabel,
    required this.progress,
    required this.location,
    required this.dateLine,
    this.onLocationTap,
  });

  final String label;
  final String prayerName;
  final String countdown;
  final String currentContext;
  final String nextPrayerTimeLine;
  final String progressStartLabel;
  final String progressEndLabel;
  final double progress;
  final String location;
  final String dateLine;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScaler = MediaQuery.textScalerOf(context);
    final compact = textScaler.scale(1) > 1.18;

    return Semantics(
      label: '$label $prayerName $countdown. $currentContext.',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: compact ? 210 : 178),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.heroCardBackground,
              Color.alphaBlend(
                colors.cardSurfaceTint.withValues(alpha: isDark ? 0.18 : 0.08),
                colors.heroCardBackground,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.countdownText.withValues(
                        alpha: isDark ? 0.22 : 0.12,
                      ),
                      colors.countdownText.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const SizedBox(width: 230, height: 80),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroMetaRow(
                  location: location,
                  dateLine: dateLine,
                  onLocationTap: onLocationTap,
                ),
                const SizedBox(height: 16),
                Text(
                  currentContext,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: FittedBox(
                    key: ValueKey(countdown),
                    fit: BoxFit.scaleDown,
                    child: Text(
                      countdown,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colors.countdownText,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextPrayerTimeLine,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 13),
                ProgressPrayerBar(
                  startLabel: progressStartLabel,
                  endLabel: progressEndLabel,
                  progress: progress,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.location,
    required this.dateLine,
    required this.onLocationTap,
  });

  final String location;
  final String dateLine;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.mutedText,
      fontWeight: FontWeight.w700,
      fontSize: 10,
      height: 1.2,
    );

    return Column(
      children: [
        InkWell(
          onTap: onLocationTap,
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  dateLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.location_on,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Flexible(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ],
          ),
        ),
        if (onLocationTap != null)
          Tooltip(
            message: 'prayer_times.change_location'.tr(),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
