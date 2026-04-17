import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_categories.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesCubit>(
      create: (_) => getIt<FavoritesCubit>()..loadFavorites(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('common.favorites'.tr()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            _FavoritesBackground(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            SafeArea(
              child: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, state) {
                  if (state.status == FavoritesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == FavoritesStatus.failure) {
                    return Center(
                      child: Text(
                        state.errorMessage ??
                            'common.failed_load_favorites'.tr(),
                      ),
                    );
                  }

                  if (state.items.isEmpty) {
                    return Center(child: Text('common.no_favorites'.tr()));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final category = AppCategories.byKey(item.category);
                      final theme = Theme.of(context);
                      final colors = AppThemeColors.of(context);
                      final accent = theme.colorScheme.primary;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(colors.cardRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Card(
                            elevation: 2,
                            shadowColor: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.2
                                  : 0.06,
                            ),
                            color: colors.cardSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                colors.cardRadius,
                              ),
                              side: BorderSide(color: colors.softBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                item.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      height: 1.5,
                                      color: theme.colorScheme.onSurface,
                                    ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  category.titleKey.tr(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.mutedText,
                                  ),
                                ),
                              ),
                              onTap: () => context.push(
                                '/reader/${item.category}?id=${item.id}',
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: accent),
                                onPressed: () {
                                  context.read<FavoritesCubit>().toggleFavorite(
                                    item.id,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
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

class _FavoritesBackground extends StatelessWidget {
  const _FavoritesBackground({required this.isDark});

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
    final random = Random(8);
    final count = isDark ? 70 : 50;
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
