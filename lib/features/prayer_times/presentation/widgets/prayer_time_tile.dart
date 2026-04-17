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
    required this.isPast,
  });

  final String name;
  final String time;
  final IconData icon;
  final bool isCurrent;
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
    final opacity = widget.isPast && !widget.isCurrent ? 0.72 : 1.0;
    // New design: current prayer has olive green background with golden accent
    final currentBg = colors.currentPrayerBg ??
        Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
          colors.cardSurface,
        );
    final currentFg = colors.currentPrayerFg ?? theme.colorScheme.onSurface;
    final badgeFg = isDark ? Colors.white : (colors.accentColor ?? theme.colorScheme.primary);

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
                color: widget.isCurrent ? currentBg : colors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isCurrent
                      ? (colors.accentColor ?? theme.colorScheme.primary).withValues(
                          alpha: isDark ? 0.5 : 0.4,
                        )
                      : colors.softBorder,
                  width: widget.isCurrent ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isCurrent
                        ? (colors.accentColor ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.3 : 0.2)
                        : Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
                    blurRadius: widget.isCurrent ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (widget.isCurrent)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.25) : colors.accentColor?.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.4) : (colors.accentColor ?? badgeFg).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'common.now'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? Colors.white : (colors.accentColor ?? badgeFg),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
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
                          color: widget.isCurrent
                              ? currentFg
                              : colors.prayerIcon,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: widget.isCurrent ? currentFg : null,
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
                            color: widget.isCurrent
                                ? currentFg.withValues(alpha: 0.92)
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
