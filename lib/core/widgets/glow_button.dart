import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// زر Primary موحّد مع Glow effect
class AppGlowButton extends StatelessWidget {
  const AppGlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.height = 68,
    this.radius = 44,
  });

  final Widget label;
  final VoidCallback? onTap;
  final bool enabled;
  final double height;
  final double radius;

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
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow shadow
          if (enabled)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          // Main button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: enabled
                    ? glowColor.withValues(alpha: 0.8)
                    : Colors.grey.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 2),
              child: Stack(
                children: [
                  // Metallic gradient
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
                  // Top highlight
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(
                              alpha: enabled ? (isDark ? 0.28 : 0.38) : 0.12,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius - 7),
                      border: Border.all(
                        color: enabled
                            ? glowColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  // Touch surface
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius - 2),
                      onTap: enabled ? onTap : null,
                      child: Center(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: enabled
                                ? theme.colorScheme.onPrimary
                                : colors.mutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            fontFamily: 'Cairo',
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

/// زر Outline موحّد مع Glow effect
class AppOutlineGlowButton extends StatelessWidget {
  const AppOutlineGlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 48,
    this.radius = 24,
  });

  final Widget label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final glowColor = theme.colorScheme.primary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        color: colors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: glowColor, size: 18),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: TextStyle(
                    color: glowColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// زر دائري للـ Action Icons في شاشة القارئ
class AppActionCircle extends StatelessWidget {
  const AppActionCircle({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.tooltip,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;
  final bool isActive;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final effective = activeColor ?? primary;

    Widget circle = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: effective.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? effective
                    : effective.withValues(alpha: 0.7),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    colors.countdownText.withValues(alpha: isDark ? 0.16 : 0.06),
                    primary,
                  ),
                  primary,
                  Color.alphaBlend(
                    Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
                    primary,
                  ),
                ],
              ),
            ),
            child: ClipOval(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      size: size * 0.42,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      circle = Tooltip(message: tooltip!, child: circle);
    }

    return circle;
  }
}
