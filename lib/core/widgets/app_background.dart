import 'package:flutter/material.dart';
import 'islamic_ornament.dart';

/// خلفية موحّدة لجميع الشاشات — نظيفة وبسيطة
class AppScaffoldBackground extends StatelessWidget {
  const AppScaffoldBackground({
    super.key,
    this.gradientEnd = Alignment.bottomCenter,
  });

  final Alignment gradientEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surfaceContainerHighest;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: gradientEnd,
          colors: [
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(
              surface.withValues(alpha: isDark ? 0.06 : 0.28),
              theme.scaffoldBackgroundColor,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          const SizedBox.expand(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: IslamicOrnament(
                color: theme.colorScheme.tertiary.withValues(
                  alpha: isDark ? 0.08 : 0.045,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
