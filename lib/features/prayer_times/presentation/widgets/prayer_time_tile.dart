import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PrayerTimeTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = isNext ? scheme.tertiary : scheme.primary;
    final foreground = isCurrent ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      label:
          '$name, $time${isCurrent
              ? ', ${'common.now'.tr()}'
              : isNext
              ? ', ${'common.next'.tr()}'
              : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent ? scheme.primary : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent
                ? Colors.transparent
                : isNext
                ? accent.withValues(alpha: .45)
                : scheme.outlineVariant.withValues(alpha: .65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isCurrent ? foreground.withValues(alpha: .85) : accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground.withValues(alpha: .85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                time,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 5),
            if (isCurrent || isNext)
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? foreground : accent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isCurrent ? 'common.now'.tr() : 'common.next'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: isCurrent
                            ? foreground.withValues(alpha: .8)
                            : accent,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: 22,
                height: 2,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isPast ? .2 : .5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
