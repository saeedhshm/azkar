import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// خلفية موحّدة لجميع الشاشات
/// تستبدل _DustPainter, _SoftDustPainter, _StarFieldPainter المكررة
class AppScaffoldBackground extends StatelessWidget {
  const AppScaffoldBackground({
    super.key,
    this.particleCount = 70,
    this.particleSeed = 7,
    this.showRadialGlow = false,
    this.glowCenter = const Alignment(0, 0.5),
    this.gradientEnd = Alignment.bottomCenter,
  });

  final int particleCount;
  final int particleSeed;
  final bool showRadialGlow;
  final Alignment glowCenter;
  final Alignment gradientEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: gradientEnd,
          colors: [
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              colors.heroCardBackground.withValues(alpha: isDark ? 0.06 : 0.28),
              theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _UnifiedDustPainter(
          isDark: isDark,
          particleColor: isDark
              ? const Color(0xFFDAA520)
              : const Color(0xFF4A5D23),
          glowColor: isDark ? colors.countdownText : colors.heroCardBackground,
          particleCount: particleCount,
          seed: particleSeed,
          showRadialGlow: showRadialGlow,
          glowCenter: glowCenter,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _UnifiedDustPainter extends CustomPainter {
  _UnifiedDustPainter({
    required this.isDark,
    required this.particleColor,
    required this.glowColor,
    required this.particleCount,
    required this.seed,
    required this.showRadialGlow,
    required this.glowCenter,
  });

  final bool isDark;
  final Color particleColor;
  final Color glowColor;
  final int particleCount;
  final int seed;
  final bool showRadialGlow;
  final Alignment glowCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint();

    for (var i = 0; i < particleCount; i++) {
      final opacity = (isDark ? 0.18 : 0.07) + random.nextDouble() * 0.12;
      paint.color = particleColor.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.4 + 0.3,
        paint,
      );
    }

    if (showRadialGlow) {
      final cx = size.width * ((glowCenter.x + 1) / 2);
      final cy = size.height * ((glowCenter.y + 1) / 2);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor.withValues(alpha: isDark ? 0.16 : 0.48),
            Colors.transparent,
          ],
          radius: 0.6,
        ).createShader(
          Rect.fromCircle(
            center: Offset(cx, cy),
            radius: size.width * 0.8,
          ),
        );
      canvas.drawRect(Offset.zero & size, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UnifiedDustPainter old) =>
      old.isDark != isDark || old.particleCount != particleCount;
}
