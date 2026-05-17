import 'package:flutter/material.dart';

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
      child: const SizedBox.expand(),
    );
  }
}
