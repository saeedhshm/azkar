import 'package:flutter/material.dart';

class QuranMushafFrame extends StatelessWidget {
  const QuranMushafFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gold = theme.colorScheme.secondary;
    final ivory = isDark ? const Color(0xFF10170F) : const Color(0xFFFFFBF0);
    final mint = isDark ? const Color(0xFF16221B) : const Color(0xFFE9F5E5);
    final blush = isDark ? const Color(0xFF1A1812) : const Color(0xFFF7EFD9);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(gold.withValues(alpha: 0.03), ivory),
            ivory,
            Color.alphaBlend(
              (isDark ? mint : blush).withValues(alpha: 0.45),
              ivory,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  gold.withValues(alpha: isDark ? 0.16 : 0.1),
                  mint,
                ),
                ivory,
                Color.alphaBlend(
                  gold.withValues(alpha: isDark ? 0.08 : 0.06),
                  blush,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _MushafBorderPainter(gold: gold, isDark: isDark),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: ivory.withValues(alpha: 0.92),
                ),
                child: Padding(padding: const EdgeInsets.all(10), child: child),
              ),
            ),
          ),
        ),
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
    final outerRect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      outerRect.deflate(5),
      const Radius.circular(28),
    );
    final inner = RRect.fromRectAndRadius(
      outerRect.deflate(14),
      const Radius.circular(24),
    );
    final core = RRect.fromRectAndRadius(
      outerRect.deflate(24),
      const Radius.circular(20),
    );
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..color = gold.withValues(alpha: isDark ? 0.34 : 0.3);
    canvas.drawRRect(outer, linePaint);
    linePaint.color = gold.withValues(alpha: isDark ? 0.22 : 0.24);
    canvas.drawRRect(inner, linePaint);
    linePaint.color = gold.withValues(alpha: isDark ? 0.14 : 0.16);
    canvas.drawRRect(core, linePaint);

    final ornamentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = gold.withValues(alpha: isDark ? 0.44 : 0.34);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = gold.withValues(alpha: isDark ? 0.09 : 0.08);
    const inset = 28.0;
    const length = 28.0;
    for (final corner in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawCircle(corner, 9, fillPaint);
      canvas.drawCircle(corner, 4.2, ornamentPaint);
      canvas.drawCircle(corner, 9.6, ornamentPaint);
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

    _drawSideMedallion(
      canvas,
      center: Offset(size.width / 2, 17),
      gold: gold,
      isDark: isDark,
      horizontal: true,
    );
    _drawSideMedallion(
      canvas,
      center: Offset(size.width / 2, size.height - 17),
      gold: gold,
      isDark: isDark,
      horizontal: true,
    );
    _drawSideMedallion(
      canvas,
      center: Offset(17, size.height / 2),
      gold: gold,
      isDark: isDark,
      horizontal: false,
    );
    _drawSideMedallion(
      canvas,
      center: Offset(size.width - 17, size.height / 2),
      gold: gold,
      isDark: isDark,
      horizontal: false,
    );

    _drawTopArchBand(canvas, size, gold, isDark);
  }

  void _drawSideMedallion(
    Canvas canvas, {
    required Offset center,
    required Color gold,
    required bool isDark,
    required bool horizontal,
  }) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gold.withValues(alpha: isDark ? 0.34 : 0.28);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = gold.withValues(alpha: isDark ? 0.12 : 0.1);
    final rect = Rect.fromCenter(
      center: center,
      width: horizontal ? 34 : 18,
      height: horizontal ? 18 : 34,
    );
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, stroke);
    canvas.drawCircle(center, 2.8, stroke);
  }

  void _drawTopArchBand(Canvas canvas, Size size, Color gold, bool isDark) {
    final centerX = size.width / 2;
    final path = Path();
    path.moveTo(centerX - 44, 30);
    path.quadraticBezierTo(centerX - 28, 8, centerX, 18);
    path.quadraticBezierTo(centerX + 28, 8, centerX + 44, 30);
    path.lineTo(centerX + 28, 30);
    path.quadraticBezierTo(centerX + 18, 18, centerX, 24);
    path.quadraticBezierTo(centerX - 18, 18, centerX - 28, 30);
    path.close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = gold.withValues(alpha: isDark ? 0.14 : 0.12);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = gold.withValues(alpha: isDark ? 0.38 : 0.3);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(Offset(centerX, 24), 3.4, stroke);
  }

  @override
  bool shouldRepaint(covariant _MushafBorderPainter oldDelegate) {
    return oldDelegate.gold != gold || oldDelegate.isDark != isDark;
  }
}
