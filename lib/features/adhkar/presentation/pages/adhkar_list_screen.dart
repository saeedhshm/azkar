import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/app_categories.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../domain/entities/adhkar.dart';
import '../cubit/adhkar_cubit.dart';
import '../cubit/adhkar_state.dart';

class AdhkarListScreen extends StatefulWidget {
  const AdhkarListScreen({super.key, required this.categoryKey});

  final String categoryKey;

  @override
  State<AdhkarListScreen> createState() => _AdhkarListScreenState();
}

class _AdhkarListScreenState extends State<AdhkarListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.byKey(widget.categoryKey);
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return BlocProvider<AdhkarCubit>(
      create: (_) => getIt<AdhkarCubit>()..loadCategory(widget.categoryKey),
      child: Builder(
        builder: (context) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.pillBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.softBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: _isSearching
                ? _SearchField(
                    controller: _searchController,
                    onChanged: (v) => context.read<AdhkarCubit>().search(v),
                  )
                : Text(
                    category.titleKey.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            actions: [
              _AppBarIconBtn(
                icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                colors: colors,
                onTap: () {
                  setState(() => _isSearching = !_isSearching);
                  if (!_isSearching) {
                    _searchController.clear();
                    context.read<AdhkarCubit>().search('');
                  }
                },
              ),
              const SizedBox(width: 4),
              _AppBarIconBtn(
                icon: Icons.restart_alt_rounded,
                tooltip: 'common.reset_progress'.tr(),
                colors: colors,
                onTap: () async {
                  await context.read<AdhkarCubit>().resetProgress();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('common.progress_reset'.tr())),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              const AppScaffoldBackground(particleCount: 60, particleSeed: 9),
              SafeArea(
                child: BlocBuilder<AdhkarCubit, AdhkarState>(
                  builder: (context, state) {
                    if (state.status == AdhkarStatus.loading) {
                      return const AppListShimmer();
                    }

                    if (state.status == AdhkarStatus.failure) {
                      return AppErrorState(
                        message: state.errorMessage ??
                            'common.failed_load_adhkar'.tr(),
                        onRetry: () => context
                            .read<AdhkarCubit>()
                            .loadCategory(widget.categoryKey),
                        retryLabel: 'common.retry'.tr(),
                      );
                    }

                    if (state.items.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: 'common.no_adhkar_in_category'.tr(),
                      );
                    }

                    final accent = theme.colorScheme.primary;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        final isFav =
                            state.favoriteIds.contains(item.id);
                        final remaining =
                            state.remainingByAdhkarId[item.id] ??
                                item.count;

                        return _AdhkarTile(
                          adhkar: item,
                          accent: accent,
                          isFavorite: isFav,
                          remainingCount: remaining,
                          animationIndex: index,
                          onTap: () async {
                            final cubit = context.read<AdhkarCubit>();
                            await context.push(
                              '/reader/${widget.categoryKey}'
                              '?id=${item.id}&index=$index',
                            );
                            if (!mounted) return;
                            await cubit.loadCategory(widget.categoryKey);
                          },
                          onFavoriteTap: () => context
                              .read<AdhkarCubit>()
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
      ),
    );
  }
}

// ─── Search Field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return TextField(
      controller: controller,
      autofocus: true,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'common.search_adhkar'.tr(),
        hintStyle: TextStyle(color: colors.mutedText),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: onChanged,
    );
  }
}

// ─── AppBar Icon Button ───────────────────────────────────────────────────────

class _AppBarIconBtn extends StatelessWidget {
  const _AppBarIconBtn({
    required this.icon,
    required this.colors,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final AppThemeColors colors;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.pillBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.softBorder),
        ),
        child: Icon(icon, size: 18, color: colors.accentColor),
      ),
    );
    if (tooltip != null) btn = Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

// ─── Adhkar Tile ──────────────────────────────────────────────────────────────

class _AdhkarTile extends StatelessWidget {
  const _AdhkarTile({
    required this.adhkar,
    required this.accent,
    required this.isFavorite,
    required this.remainingCount,
    required this.animationIndex,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Adhkar adhkar;
  final Color accent;
  final bool isFavorite;
  final int remainingCount;
  final int animationIndex;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final normalizedRemaining = remainingCount.clamp(0, adhkar.count);
    final isCompleted = normalizedRemaining == 0;
    final progress = adhkar.count == 0
        ? 0.0
        : (adhkar.count - normalizedRemaining) / adhkar.count;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (animationIndex * 30).clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? colors.successColor.withValues(alpha: 0.06)
                      : colors.cardSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isCompleted
                        ? colors.successColor.withValues(alpha: 0.3)
                        : colors.softBorder,
                    width: isCompleted ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha:
                              theme.brightness == Brightness.dark
                                  ? 0.14
                                  : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            adhkar.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.titleMedium?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Favorite button
                        GestureDetector(
                          onTap: onFavoriteTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? accent.withValues(alpha: 0.15)
                                  : colors.pillBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isFavorite
                                    ? accent.withValues(alpha: 0.4)
                                    : colors.softBorder,
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 17,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AppBadge(
                          label: '${'common.count'.tr()}: ${adhkar.count}',
                          color: accent,
                        ),
                        AppBadge(
                          label: isCompleted
                              ? '✓ ${'common.completed'.tr()}'
                              : '${'reader.remaining'.tr()}: $normalizedRemaining',
                          color: isCompleted ? colors.successColor : accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: colors.softBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? colors.successColor : accent,
                        ),
                      ),
                    ),
                    if (adhkar.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        adhkar.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
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
