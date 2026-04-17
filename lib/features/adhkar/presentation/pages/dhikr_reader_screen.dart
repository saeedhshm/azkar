import 'dart:math';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/reader_cubit.dart';
import '../cubit/reader_state.dart';

class DhikrReaderScreen extends StatefulWidget {
  const DhikrReaderScreen({
    super.key,
    required this.categoryKey,
    required this.startIndex,
    this.initialAdhkarId,
  });

  final String categoryKey;
  final int startIndex;
  final int? initialAdhkarId;

  @override
  State<DhikrReaderScreen> createState() => _DhikrReaderScreenState();
}

class _DhikrReaderScreenState extends State<DhikrReaderScreen> {
  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('reader.copied'.tr())));
    }
  }

  Future<void> _shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appColors = AppThemeColors.of(context);

    return BlocProvider<ReaderCubit>(
      create: (_) => getIt<ReaderCubit>()
        ..initialize(
          categoryKey: widget.categoryKey,
          startIndex: widget.startIndex,
          initialAdhkarId: widget.initialAdhkarId,
        ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('reader.title'.tr()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            _ReaderBackground(isDark: isDark, colors: appColors),
            SafeArea(
              child: BlocBuilder<ReaderCubit, ReaderState>(
                builder: (context, state) {
                  if (state.status == ReaderStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == ReaderStatus.failure) {
                    return Center(
                      child: Text(
                        state.errorMessage ?? 'reader.failed_open'.tr(),
                      ),
                    );
                  }

                  final current = state.currentAdhkar;
                  if (current == null) {
                    return Center(child: Text('reader.no_dhikr'.tr()));
                  }

                  final isFavorite = state.favoriteIds.contains(current.id);
                  final total = current.count;
                  final done = (total - state.remainingCount).clamp(0, total);
                  final progress = total == 0 ? 0.0 : done / total;
                  final percent = (progress * 100).clamp(0, 100).round();

                  final accent = theme.colorScheme.primary;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 390;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 36,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _GlassCard(
                                child: Column(
                                  children: [
                                    Text(
                                      '${state.currentIndex + 1} / ${state.items.length}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            letterSpacing: 1.2,
                                            color: appColors.mutedText,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      child: Text(
                                        current.text,
                                        key: ValueKey<int>(current.id),
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              height: 1.8,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'reader.repeat_label'.tr(
                                        namedArgs: {'count': total.toString()},
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: appColors.mutedText,
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    _ProgressBar(
                                      progress: progress,
                                      accent: accent,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$percent%',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: appColors.mutedText,
                                          ),
                                    ),
                                    if (current.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                          current.description,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: appColors.mutedText,
                                              ),
                                        ),
                                      ),
                                    if (current.reference.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          current.reference,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: appColors.mutedText,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _GlowButton(
                                enabled: state.remainingCount > 0,
                                onTap: state.remainingCount > 0
                                    ? () => context
                                          .read<ReaderCubit>()
                                          .decrementCounter()
                                    : null,
                                label: Text(
                                  'reader.tasbeeh_button'.tr(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.remainingCount > 0
                                    ? '${'reader.remaining'.tr()}: ${state.remainingCount}'
                                    : 'reader.completed'.tr(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: appColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ActionCircle(
                                    onTap: null,
                                    icon: Icons.volume_up_rounded,
                                    isDark: isDark,
                                  ),
                                  _ActionCircle(
                                    onTap: () {
                                      context
                                          .read<ReaderCubit>()
                                          .toggleFavorite();
                                    },
                                    icon: isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    isDark: isDark,
                                  ),
                                  _ActionCircle(
                                    onTap: () =>
                                        _copyText(context, current.text),
                                    icon: Icons.copy_all_rounded,
                                    isDark: isDark,
                                  ),
                                  _ActionCircle(
                                    onTap: () => _shareText(current.text),
                                    icon: Icons.share_rounded,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _NavigationPill(
                                isDark: isDark,
                                onPrevious: state.currentIndex > 0
                                    ? () =>
                                          context.read<ReaderCubit>().previous()
                                    : null,
                                onNext:
                                    state.currentIndex < state.items.length - 1
                                    ? () => context.read<ReaderCubit>().next()
                                    : null,
                                isCompact: isCompact,
                              ),
                              const SizedBox(height: 16),
                            ],
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

class _ReaderBackground extends StatelessWidget {
  const _ReaderBackground({required this.isDark, required this.colors});

  final bool isDark;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        painter: _StarFieldPainter(
          isDark: isDark,
          glowColor: isDark ? colors.countdownText : colors.heroCardBackground,
        ),
        child: Container(),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.isDark, required this.glowColor});

  final bool isDark;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final starCount = isDark ? 120 : 60;
    final baseOpacity = isDark ? 0.45 : 0.2;

    for (var i = 0; i < starCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.4 + 0.3;
      final opacity = baseOpacity + random.nextDouble() * 0.4;
      final paint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFF5D4037)).withValues(
          alpha: opacity * 0.45,
        );
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: isDark
                ? [glowColor.withValues(alpha: 0.16), Colors.transparent]
                : [glowColor.withValues(alpha: 0.55), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.7),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final borderColor = colors.softBorder;
    final background = colors.cardSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(colors.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(colors.cardRadius),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final background = AppThemeColors.of(context).softBorder;
    final gradient = LinearGradient(
      colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.6)],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: background),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glowColor = theme.colorScheme.primary;
    final metallicStart = Color.alphaBlend(
      colors.countdownText.withValues(alpha: isDark ? 0.18 : 0.08),
      theme.colorScheme.primary,
    );
    final metallicMid = theme.colorScheme.primary;
    final metallicEnd = Color.alphaBlend(
      Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
      theme.colorScheme.primary,
    );

    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing outer shadow
          if (enabled)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          // Main metallic button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: enabled
                    ? glowColor.withValues(alpha: 0.8)
                    : Colors.grey.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(42),
              child: Stack(
                children: [
                  // Metallic gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: enabled
                            ? [metallicStart, metallicMid, metallicEnd]
                            : [
                                Colors.grey.shade400.withValues(alpha: 0.8),
                                Colors.grey.shade500.withValues(alpha: 0.85),
                                Colors.grey.shade600.withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                  ),
                  // Metallic highlight effect
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      height: 25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(
                              alpha: enabled ? (isDark ? 0.3 : 0.4) : 0.15,
                            ),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Subtle texture overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: enabled
                            ? glowColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  // Touch area
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(42),
                      onTap: enabled ? onTap : null,
                      child: Center(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: enabled
                                ? theme.colorScheme.onPrimary
                                : colors.mutedText,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          child: label,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.onTap,
    required this.icon,
    required this.isDark,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final glowColor = theme.colorScheme.primary;
    final metallicStart = Color.alphaBlend(
      colors.countdownText.withValues(alpha: isDark ? 0.18 : 0.08),
      theme.colorScheme.primary,
    );
    final metallicMid = theme.colorScheme.primary;
    final metallicEnd = Color.alphaBlend(
      Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
      theme.colorScheme.primary,
    );

    return SizedBox(
      height: 56,
      width: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing outer shadow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          // Main metallic button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: glowColor.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  // Metallic gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [metallicStart, metallicMid, metallicEnd],
                      ),
                    ),
                  ),
                  // Metallic highlight effect
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.3 : 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Subtle texture overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: glowColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  // Touch area
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      customBorder: const CircleBorder(),
                      child: Center(
                        child: Icon(
                          icon,
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationPill extends StatelessWidget {
  const _NavigationPill({
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
    required this.isCompact,
  });

  final bool isDark;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final glowColor = theme.colorScheme.primary;
    final metallicStart = colors.cardSurface;
    final metallicMid = Color.alphaBlend(
      colors.cardSurfaceTint.withValues(alpha: isDark ? 0.28 : 0.1),
      colors.cardSurface,
    );
    final metallicEnd = colors.cardSurface;

    return SizedBox(
      height: isCompact ? 54 : 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing outer shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          // Main metallic pill
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Metallic gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [metallicStart, metallicMid, metallicEnd],
                      ),
                    ),
                  ),
                  // Metallic highlight effect
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(
                              alpha: isDark ? 0.25 : 0.35,
                            ),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Subtle texture overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: glowColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onPrevious,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              bottomLeft: Radius.circular(28),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: glowColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'common.previous'.tr(),
                                    style: TextStyle(
                                      color: glowColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isCompact ? 14 : 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: isCompact ? 30 : 34,
                        color: glowColor.withValues(alpha: 0.4),
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onNext,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'common.next'.tr(),
                                    style: TextStyle(
                                      color: glowColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isCompact ? 14 : 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: glowColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
