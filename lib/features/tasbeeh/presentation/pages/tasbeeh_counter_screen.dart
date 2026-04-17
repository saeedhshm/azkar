import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';

class TasbeehCounterScreen extends StatelessWidget {
  const TasbeehCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TasbeehCubit>(
      create: (_) => getIt<TasbeehCubit>()..load(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('common.tasbeeh_counter'.tr()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<TasbeehCubit, TasbeehState>(
          builder: (context, state) {
            if (state.status == TasbeehStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final glowColor = AppThemeColors.of(context).countdownText;

            return Stack(
              children: [
                _TasbeehBackground(isDark: isDark),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final circleSize = maxWidth < 360 ? 200.0 : 240.0;

                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GlassPanel(
                                child: Column(
                                  children: [
                                    Text(
                                      'tasbeeh.default_phrase'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    _CountRing(
                                      size: circleSize,
                                      count: state.count,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: min(maxWidth, 320),
                                child: _GlowButton(
                                  enabled: true,
                                  onTap: () =>
                                      context.read<TasbeehCubit>().increment(),
                                  label: Text('tasbeeh.tap_to_count'.tr()),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: min(maxWidth, 260),
                                child: _OutlineGlowButton(
                                  label: Text('common.reset'.tr()),
                                  icon: Icons.refresh,
                                  onTap: () =>
                                      context.read<TasbeehCubit>().reset(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${'reader.remaining'.tr()}: ${state.count}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: glowColor.withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TasbeehBackground extends StatelessWidget {
  const _TasbeehBackground({required this.isDark});

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
        painter: _SoftDustPainter(
          isDark: isDark,
          glowColor: isDark ? colors.countdownText : colors.heroCardBackground,
        ),
        child: Container(),
      ),
    );
  }
}

class _SoftDustPainter extends CustomPainter {
  _SoftDustPainter({required this.isDark, required this.glowColor});

  final bool isDark;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final borderColor = colors.softBorder;
    final background = colors.cardSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(26),
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

class _CountRing extends StatelessWidget {
  const _CountRing({
    required this.size,
    required this.count,
    required this.isDark,
  });

  final double size;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final glowColor = colors.countdownText;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary,
        Color.alphaBlend(
          colors.countdownText.withValues(alpha: isDark ? 0.45 : 0.18),
          theme.colorScheme.primary,
        ),
      ],
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: isDark ? 0.4 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: isDark ? 0.2 : 0.12),
            blurRadius: 40,
          ),
        ],
        border: Border.all(color: glowColor.withValues(alpha: 0.7), width: 2.2),
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.5),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
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
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      height: 24,
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
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

class _OutlineGlowButton extends StatelessWidget {
  const _OutlineGlowButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Widget label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final glowColor = theme.colorScheme.primary;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glowColor.withValues(alpha: 0.6), width: 1.4),
        color: colors.cardSurface,
        boxShadow: [
          BoxShadow(color: glowColor.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: glowColor, size: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  DefaultTextStyle(
                    style: TextStyle(
                      color: glowColor,
                      fontWeight: FontWeight.w600,
                    ),
                    child: label,
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
