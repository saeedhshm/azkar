import 'dart:math' as math;
import 'package:flutter/material.dart';

enum IslamicIconType { quran, tasbeeh }

/// Original line-art icons that scale cleanly without image assets.
class IslamicIcon extends StatelessWidget {
  const IslamicIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.color,
  });
  final IslamicIconType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _IslamicIconPainter(
        type,
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _IslamicIconPainter extends CustomPainter {
  const _IslamicIconPainter(this.type, this.color);
  final IslamicIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (type == IslamicIconType.tasbeeh) {
      for (var i = 0; i < 11; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 12;
        canvas.drawCircle(
          Offset(12 + 7.6 * math.cos(angle), 10 + 7.6 * math.sin(angle)),
          1.65,
          pen,
        );
      }
      canvas.drawLine(const Offset(12, 18), const Offset(12, 23), pen);
      canvas.drawLine(const Offset(12, 20), const Offset(9.5, 23), pen);
      canvas.drawLine(const Offset(12, 20), const Offset(14.5, 23), pen);
    } else {
      final book = Path()
        ..moveTo(12, 6)
        ..quadraticBezierTo(7, 2, 2, 4)
        ..lineTo(2, 18)
        ..quadraticBezierTo(7, 16, 12, 20)
        ..quadraticBezierTo(17, 16, 22, 18)
        ..lineTo(22, 4)
        ..quadraticBezierTo(17, 2, 12, 6)
        ..lineTo(12, 20);
      canvas.drawPath(book, pen);
      for (final x in [5.0, 15.0]) {
        canvas.drawLine(Offset(x, 9), Offset(x + 4, 10), pen);
        canvas.drawLine(Offset(x, 12), Offset(x + 4, 13), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_IslamicIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
