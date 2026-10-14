import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A restrained eight-point geometric motif, drawn locally at any resolution.
class IslamicOrnament extends StatelessWidget {
  const IslamicOrnament({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _OrnamentPainter(color),
      child: const SizedBox.expand(),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const step = 64.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        final center = Offset(x, y);
        final path = Path();
        for (var i = 0; i < 16; i++) {
          final angle = i * math.pi / 8;
          final radius = i.isEven ? 27.0 : 16.0;
          final point =
              center + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(path..close(), paint);
        canvas.drawCircle(center, 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_OrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Reusable editorial header for the app's main collections.
class IslamicCollectionHeader extends StatelessWidget {
  const IslamicCollectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: .3),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerLow,
                    theme.colorScheme.surfaceContainer,
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: -20,
            end: -30,
            width: 160,
            height: 220,
            child: IslamicOrnament(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 2,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                HeritageIcon(icon: icon, size: 66),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A double-line medallion inspired by illuminated manuscript seals.
class HeritageIcon extends StatelessWidget {
  const HeritageIcon({super.key, required this.icon, this.size = 48});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: size * .73,
              height: size * .73,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold.withValues(alpha: .35)),
              ),
            ),
          ),
          Container(
            width: size * .76,
            height: size * .76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold.withValues(alpha: .22)),
            ),
          ),
          Icon(icon, color: gold, size: size * .44),
        ],
      ),
    );
  }
}
