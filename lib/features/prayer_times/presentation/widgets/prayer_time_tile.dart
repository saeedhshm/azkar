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
    final currentBg = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
      colors.cardSurface,
    );
    final currentFg = theme.colorScheme.onSurface;
    final badgeBg = theme.colorScheme.primary.withValues(alpha: 0.14);
    final badgeFg = theme.colorScheme.primary;

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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isCurrent
                      ? theme.colorScheme.primary.withValues(
                          alpha: isDark ? 0.72 : 0.42,
                        )
                      : colors.softBorder,
                  width: widget.isCurrent ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
                    blurRadius: widget.isCurrent ? 14 : 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (widget.isCurrent)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'common.now'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: badgeFg,
                            fontWeight: FontWeight.w900,
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
