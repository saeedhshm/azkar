import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    required this.progressStartTime,
    required this.progressEndTime,
    required this.progress,
    required this.location,
    required this.hijriDate,
    required this.gregorianDate,
    this.onLocationTap,
  });

  final String label;
  final String prayerName;
  final String countdown;
  final String currentContext;
  final String nextPrayerTimeLine;
  final String progressStartLabel;
  final String progressEndLabel;
  final String progressStartTime;
  final String progressEndTime;
  final double progress;
  final String location;
  final String hijriDate;
  final String gregorianDate;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              theme.colorScheme.surfaceContainerHighest,
              Color.alphaBlend(
                theme.colorScheme.primary
                    .withValues(alpha: isDark ? 0.15 : 0.12),
                theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary
                .withValues(alpha: isDark ? 0.3 : 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary
                  .withValues(alpha: isDark ? 0.25 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radial glow behind countdown
            Positioned(
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary
                          .withValues(alpha: isDark ? 0.35 : 0.22),
                      theme.colorScheme.primary
                          .withValues(alpha: 0),
                    ],
                    radius: 0.6,
                  ),
                ),
                child: const SizedBox(width: 250, height: 90),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: hijri date | 📍 location
                _HeroMetaRow(
                  location: location,
                  hijriDate: hijriDate,
                  onLocationTap: onLocationTap,
                ),
                // Row 2: gregorian date
                if (gregorianDate.isNotEmpty) ...[
                  const SizedBox(height: 3),
                Text(
                  gregorianDate,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                ],
                const SizedBox(height: 14),
                // "You're in Asr time"
                Text(
                  currentContext,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                // Countdown timer
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: FittedBox(
                    key: ValueKey(countdown),
                    fit: BoxFit.scaleDown,
                    child: Text(
                      countdown,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // "Maghrib at 6:12 PM"
                Text(
                  nextPrayerTimeLine,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 13),
                // Progress bar with start/end labels and times
                ProgressPrayerBar(
                  startLabel: progressStartLabel,
                  endLabel: progressEndLabel,
                  startTime: progressStartTime,
                  endTime: progressEndTime,
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

/// Row 1: "28 Shawwal 1447 | 📍 Cairo, Egypt"
class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.location,
    required this.hijriDate,
    required this.onLocationTap,
  });

  final String location;
  final String hijriDate;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
              if (hijriDate.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    hijriDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('|', style: style),
                ),
              ],
              Icon(
                Icons.location_on,
                size: 11,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 3),
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
