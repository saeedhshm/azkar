import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProgressPrayerBar extends StatelessWidget {
  const ProgressPrayerBar({
    super.key,
    required this.startLabel,
    required this.endLabel,
    required this.progress,
  });

  final String startLabel;
  final String endLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final activeColor = colors.countdownText;

    return Directionality(
      // Prayer progress is time-based, so it should fill in the same visual
      // direction regardless of the app language.
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clampedProgress),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final knobX = (width * value).clamp(4.0, width - 4);

                  return SizedBox(
                    height: 14,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: colors.mutedText.withValues(alpha: 0.22),
                          ),
                        ),
                        Container(
                          width: knobX,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                activeColor.withValues(alpha: 0.16),
                                activeColor,
                                activeColor.withValues(alpha: 0.65),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.7),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: knobX - 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor,
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.85),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Expanded(
                child: Text(
                  startLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  endLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
