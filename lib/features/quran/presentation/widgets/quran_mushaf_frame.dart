import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class QuranMushafFrame extends StatelessWidget {
  const QuranMushafFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gold = colors.accentColor ?? colors.countdownText;
    final pageColor = isDark
        ? const Color(0xFF141C13)
        : const Color(0xFFFFFCF2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pageColor,
            Color.alphaBlend(
              gold.withValues(alpha: isDark ? 0.08 : 0.06),
              pageColor,
            ),
          ],
        ),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.5 : 0.38),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MushafBorderPainter(gold: gold, isDark: isDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MushafBorderPainter extends CustomPainter {
  const _MushafBorderPainter({required this.gold, required this.isDark});

  final Color gold;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      rect.deflate(8),
      const Radius.circular(22),
    );
    final inner = RRect.fromRectAndRadius(
      rect.deflate(15),
      const Radius.circular(18),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gold.withValues(alpha: isDark ? 0.22 : 0.24);
    canvas.drawRRect(outer, paint);
    paint.color = gold.withValues(alpha: isDark ? 0.15 : 0.18);
    canvas.drawRRect(inner, paint);

    final ornamentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = gold.withValues(alpha: isDark ? 0.34 : 0.3);
    const inset = 26.0;
    const length = 26.0;
    for (final corner in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawCircle(corner, 3.2, ornamentPaint);
      canvas.drawCircle(corner, 7.8, ornamentPaint);
    }
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + length, inset),
      ornamentPaint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset, inset + length),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - length, inset),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + length),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + length, size.height - inset),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset, size.height - inset - length),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - length, size.height - inset),
      ornamentPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - length),
      ornamentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MushafBorderPainter oldDelegate) {
    return oldDelegate.gold != gold || oldDelegate.isDark != isDark;
  }
}
