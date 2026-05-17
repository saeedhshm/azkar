import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/app_categories.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/glass_card.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<FavoritesCubit>(
      create: (_) => getIt<FavoritesCubit>()..loadFavorites(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'common.favorites'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        body: Stack(
          children: [
            const AppScaffoldBackground(),
            SafeArea(
              child: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, state) {
                  if (state.status == FavoritesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == FavoritesStatus.failure) {
                    return AppErrorState(
                      message: state.errorMessage ??
                          'common.failed_load_favorites'.tr(),
                      onRetry: () =>
                          context.read<FavoritesCubit>().loadFavorites(),
                      retryLabel: 'common.retry'.tr(),
                    );
                  }

                  if (state.items.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: 'common.no_favorites'.tr(),
                      subtitle: 'favorites.empty_subtitle'.tr(),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final category = AppCategories.byKey(item.category);

                      return _FavoriteTile(
                        item: item,
                        categoryTitle: category.titleKey.tr(),
                        animationIndex: index,
                        onTap: () => context
                            .push('/reader/${item.category}?id=${item.id}'),
                        onDelete: () => context
                            .read<FavoritesCubit>()
                            .toggleFavorite(item.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Favorite Tile ────────────────────────────────────────────────────────────

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.item,
    required this.categoryTitle,
    required this.animationIndex,
    required this.onTap,
    required this.onDelete,
  });

  final dynamic item;
  final String categoryTitle;
  final int animationIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Duration(milliseconds: 200 + (animationIndex * 35).clamp(0, 280)),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.delete_outline_rounded,
              color: theme.colorScheme.error, size: 22),
        ),
        onDismissed: (_) => onDelete(),
        child: AppGlassCard(
          onTap: onTap,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category_outlined,
                                  size: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                categoryTitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Delete button
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            theme.colorScheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 17, color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
