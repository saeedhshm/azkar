import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PrayerTimeTile extends StatefulWidget {
  const PrayerTimeTile({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    required this.isCurrent,
    required this.isNext,
    required this.isPast,
  });

  final String name;
  final String time;
  final IconData icon;
  final bool isCurrent;
  final bool isNext;
  final bool isPast;

  @override
  State<PrayerTimeTile> createState() => _PrayerTimeTileState();
}

class _PrayerTimeTileState extends State<PrayerTimeTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighlighted = widget.isCurrent || widget.isNext;
    final opacity = widget.isPast && !isHighlighted ? 0.72 : 1.0;

    // Current prayer: dark olive green bg in light, darker olive in dark
    final currentBg =
        colors.currentPrayerBg ??
        Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
          colors.cardSurface,
        );
    final currentFg = colors.currentPrayerFg ?? theme.colorScheme.onSurface;
    final nextBg = Color.alphaBlend(
      (colors.accentColor ?? colors.countdownText).withValues(
        alpha: isDark ? 0.18 : 0.2,
      ),
      colors.cardSurface,
    );
    final nextFg = isDark ? theme.colorScheme.onSurface : colors.secondaryText;

    final badgeBg = widget.isCurrent
        ? (colors.accentColor ?? colors.countdownText)
        : (colors.accentColor ?? colors.countdownText).withValues(
            alpha: isDark ? 0.24 : 0.18,
          );
    final badgeFg = widget.isCurrent
        ? (isDark ? const Color(0xFF1A1F15) : const Color(0xFF3B2A12))
        : (colors.accentColor ?? colors.countdownText);
    final foreground = widget.isCurrent
        ? currentFg
        : widget.isNext
        ? nextFg
        : theme.colorScheme.onSurface;

    return Semantics(
      label: '${widget.name}, ${widget.time}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.98 : 1,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: opacity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isCurrent
                    ? currentBg
                    : widget.isNext
                    ? nextBg
                    : colors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHighlighted
                      ? (colors.accentColor ?? theme.colorScheme.primary)
                            .withValues(alpha: isDark ? 0.58 : 0.46)
                      : colors.softBorder,
                  width: isHighlighted ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHighlighted
                        ? (colors.accentColor ?? theme.colorScheme.primary)
                              .withValues(alpha: isDark ? 0.28 : 0.18)
                        : Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
                    blurRadius: isHighlighted ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (isHighlighted)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.isCurrent
                              ? 'common.now'.tr()
                              : 'common.next'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: badgeFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          size: 24,
                          color: isHighlighted ? foreground : colors.prayerIcon,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isHighlighted ? foreground : null,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isHighlighted
                                ? foreground.withValues(alpha: 0.92)
                                : colors.mutedText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
