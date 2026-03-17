import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
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

                    final accent = category.colors.isNotEmpty
                        ? category.colors.first
                        : Theme.of(context).colorScheme.primary;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        final isFavorite =
                            state.favoriteIds.contains(item.id);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white60 : Colors.black45;

    return TextField(
      controller: controller,
      autofocus: true,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: 'common.search_adhkar'.tr(),
        hintStyle: TextStyle(color: hintColor),
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
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1220), Color(0xFF0F1C2E), Color(0xFF071A1B)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F0E5), Color(0xFFF2E7D6), Color(0xFFEADCC4)],
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
        ..color = (isDark ? Colors.white : const Color(0xFFB48A45)).withValues(
          alpha: opacity,
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
    final isDark = theme.brightness == Brightness.dark;
    final normalizedRemaining = remainingCount.clamp(0, adhkar.count);
    final isCompleted = normalizedRemaining == 0;
    final progressValue = adhkar.count == 0
        ? 0.0
        : (adhkar.count - normalizedRemaining) / adhkar.count;

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.65);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 1),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1D2530),
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
                        color: isCompleted
                            ? Colors.green
                            : accent.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
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
                          color: isDark ? Colors.white60 : Colors.black45,
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
