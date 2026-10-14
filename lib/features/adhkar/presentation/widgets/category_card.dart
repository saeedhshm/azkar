import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/utils/app_categories.dart';
import '../../../../core/widgets/islamic_ornament.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.index,
    required this.itemCount,
  });

  final CategoryInfo category;
  final VoidCallback onTap;
  final int index;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        category.sectionKey == 'daily' || category.sectionKey == 'life'
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 24, end: 0),
      duration: Duration(milliseconds: 280 + (index % 6 * 35)),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) =>
          Transform.translate(offset: Offset(0, offset), child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + (index % 6 * 35)),
        curve: Curves.easeOut,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerLow,
                    Color.alphaBlend(
                      accent.withValues(alpha: isDark ? 0.12 : 0.065),
                      theme.colorScheme.surfaceContainerLow,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      top: -14,
                      end: -28,
                      width: 100,
                      height: 95,
                      child: IslamicOrnament(
                        color: accent.withValues(alpha: .075),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              HeritageIcon(icon: category.icon),
                              const SizedBox(width: 8),
                              // Count badge
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.topEnd,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: isDark ? 0.16 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$itemCount',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: accent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            category.titleKey.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.subtitleKey.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: accent,
                              ),
                            ],
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
      ),
    );
  }
}
