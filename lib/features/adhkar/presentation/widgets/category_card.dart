import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/app_categories.dart';

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
    final accent = theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 24, end: 0),
      duration: Duration(milliseconds: 280 + (index * 38)),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) =>
          Transform.translate(offset: Offset(0, offset), child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + (index * 38)),
        curve: Curves.easeOut,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerLow,
                    Color.alphaBlend(
                      theme.colorScheme.primary.withValues(
                          alpha: isDark ? 0.35 : 0.1),
                      theme.colorScheme.surfaceContainerLow,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            category.icon,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        // Count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: isDark ? 0.16 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$itemCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
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
                    Text(
                      category.subtitleKey.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
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
