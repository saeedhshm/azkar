import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_categories.dart';
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

    return BlocProvider<AdhkarCubit>(
      create: (_) => getIt<AdhkarCubit>()..loadCategory(widget.categoryKey),
      child: Builder(
        builder: (context) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: _isSearching
                ? _SearchField(
                    controller: _searchController,
                    onChanged: (value) =>
                        context.read<AdhkarCubit>().search(value),
                  )
                : Text(category.titleKey.tr()),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() => _isSearching = !_isSearching);

                  if (!_isSearching) {
                    _searchController.clear();
                    context.read<AdhkarCubit>().search('');
                  }
                },
              ),
              IconButton(
                tooltip: 'common.reset_progress'.tr(),
                icon: const Icon(Icons.restart_alt),
                onPressed: () async {
                  await context.read<AdhkarCubit>().resetProgress();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('common.progress_reset'.tr())),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              _ListBackground(
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              SafeArea(
                child: BlocBuilder<AdhkarCubit, AdhkarState>(
                  builder: (context, state) {
                    if (state.status == AdhkarStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == AdhkarStatus.failure) {
                      return Center(
                        child: Text(
                          state.errorMessage ??
                              'common.failed_load_adhkar'.tr(),
                        ),
                      );
                    }

                    if (state.items.isEmpty) {
                      return Center(
                        child: Text('common.no_adhkar_in_category'.tr()),
                      );
                    }

                    final accent = Theme.of(context).colorScheme.primary;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        final isFavorite = state.favoriteIds.contains(item.id);
                        final remainingCount =
                            state.remainingByAdhkarId[item.id] ?? item.count;

                        return _AdhkarGlassTile(
                          adhkar: item,
                          accent: accent,
                          isFavorite: isFavorite,
                          remainingCount: remainingCount,
                          onTap: () async {
                            final cubit = context.read<AdhkarCubit>();
                            await context.push(
                              '/reader/${widget.categoryKey}?id=${item.id}&index=$index',
                            );

                            if (!mounted) {
                              return;
                            }

                            await cubit.loadCategory(widget.categoryKey);
                          },
                          onFavoriteTap: () {
                            context.read<AdhkarCubit>().toggleFavorite(item.id);
                          },
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return TextField(
      controller: controller,
      autofocus: true,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'common.search_adhkar'.tr(),
        hintStyle: TextStyle(color: colors.mutedText),
        border: InputBorder.none,
      ),
      onChanged: onChanged,
    );
  }
}

class _ListBackground extends StatelessWidget {
  const _ListBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.scaffoldBackgroundColor,
        Color.alphaBlend(
          colors.heroCardBackground.withValues(alpha: isDark ? 0.08 : 0.35),
          theme.scaffoldBackgroundColor,
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: CustomPaint(
        painter: _SoftDustPainter(isDark: isDark),
        child: Container(),
      ),
    );
  }
}

class _SoftDustPainter extends CustomPainter {
  _SoftDustPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(9);
    final count = isDark ? 80 : 50;
    final baseOpacity = isDark ? 0.4 : 0.2;

    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.2;
      final opacity = baseOpacity + random.nextDouble() * 0.4;
      final paint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFF5D4037)).withValues(
          alpha: opacity * 0.45,
        );
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdhkarGlassTile extends StatelessWidget {
  const _AdhkarGlassTile({
    required this.adhkar,
    required this.accent,
    required this.isFavorite,
    required this.remainingCount,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Adhkar adhkar;
  final Color accent;
  final bool isFavorite;
  final int remainingCount;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final normalizedRemaining = remainingCount.clamp(0, adhkar.count);
    final isCompleted = normalizedRemaining == 0;
    final progressValue = adhkar.count == 0
        ? 0.0
        : (adhkar.count - normalizedRemaining) / adhkar.count;

    return ClipRRect(
      borderRadius: BorderRadius.circular(colors.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(colors.cardRadius),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius: BorderRadius.circular(colors.cardRadius),
                border: Border.all(color: colors.softBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.05,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
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
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: onFavoriteTap,
                        icon: Icon(
                          isFavorite
                              ? Icons.bookmark
                              : Icons.bookmark_border_outlined,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                        text: '${'common.count'.tr()}: ${adhkar.count}',
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        text: isCompleted
                            ? 'common.completed'.tr()
                            : '${'reader.remaining'.tr()}: $normalizedRemaining',
                        color: isCompleted ? colors.countdownText : accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: colors.softBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  if (adhkar.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        adhkar.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
