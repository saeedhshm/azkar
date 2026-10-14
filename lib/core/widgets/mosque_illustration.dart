import 'package:flutter/material.dart';

/// An original architectural illustration, with layered domes and a crescent.
class MosqueIllustration extends StatelessWidget {
  const MosqueIllustration({super.key, this.color = const Color(0xFFE6C894)});
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _MosquePainter(color),
      child: const SizedBox.expand(),
    ),
  );
}

class _MosquePainter extends CustomPainter {
  const _MosquePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 200);
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final line = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // The tall pointed arch frames the architecture.
    final arch = Path()
      ..moveTo(16, 200)
      ..lineTo(16, 80)
      ..cubicTo(16, 46, 58, 26, 90, 5)
      ..cubicTo(122, 26, 164, 46, 164, 80)
      ..lineTo(164, 200);
    canvas.drawPath(arch, line);
    canvas.drawPath(
      Path()
        ..addOval(const Rect.fromLTWH(65, 35, 24, 24))
        ..addOval(const Rect.fromLTWH(73, 30, 24, 24))
        ..fillType = PathFillType.evenOdd,
      Paint()..color = color.withValues(alpha: 0.8),
    );

    for (final point in [
      const Offset(114, 48),
      const Offset(49, 73),
      const Offset(132, 83),
    ]) {
      canvas.drawLine(
        point - const Offset(3, 0),
        point + const Offset(3, 0),
        line,
      );
      canvas.drawLine(
        point - const Offset(0, 3),
        point + const Offset(0, 3),
        line,
      );
    }
    void dome(double x, double y, double width) {
      final path = Path()
        ..moveTo(x, y)
        ..cubicTo(
          x,
          y - width * .32,
          x + width * .36,
          y - width * .4,
          x + width / 2,
          y - width * .65,
        )
        ..cubicTo(
          x + width * .64,
          y - width * .4,
          x + width,
          y - width * .32,
          x + width,
          y,
        )
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
      canvas.drawLine(
        Offset(x + width / 2, y - width * .65),
        Offset(x + width / 2, y - width * .65 - 7),
        line,
      );
    }

    // Minarets.
    for (final x in [30.0, 140.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 100, 10, 100),
          const Radius.circular(2),
        ),
        fill,
      );
      canvas.drawRect(Rect.fromLTWH(x, 100, 10, 100), line);
      dome(x - 3, 100, 16);
      canvas.drawLine(Offset(x - 4, 116), Offset(x + 14, 116), line);
    }
    dome(53, 135, 74);
    canvas.drawRect(const Rect.fromLTWH(53, 136, 74, 64), fill);
    canvas.drawLine(const Offset(53, 136), const Offset(53, 200), line);
    canvas.drawLine(const Offset(127, 136), const Offset(127, 200), line);
    // Repeating arched windows.
    for (final x in [64.0, 87.0, 110.0]) {
      final window = Path()
        ..moveTo(x, 182)
        ..lineTo(x, 158)
        ..quadraticBezierTo(x + 5, 148, x + 10, 158)
        ..lineTo(x + 10, 182)
        ..close();
      canvas.drawPath(window, line);
    }
    canvas.drawLine(const Offset(5, 196), const Offset(175, 196), line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MosquePainter oldDelegate) => oldDelegate.color != color;
}
