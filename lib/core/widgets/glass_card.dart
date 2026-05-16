import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_radius.dart';

/// بطاقة زجاجية موحّدة — Glassmorphism Card
/// تُستخدم في جميع الشاشات بدلاً من تكرار نفس الكود
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    this.radius,
    this.applyBlur = true,
    this.blurSigma = 10,
    this.borderWidth = 1.2,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final bool applyBlur;
  final double blurSigma;
  final double borderWidth;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final r = radius ?? colors.cardRadius;

    Widget card = Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: colors.softBorder, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (applyBlur) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: card,
        ),
      );
    }

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

/// بطاقة Hero Card — للبطاقات الرئيسية مثل بطاقة وقت الصلاة
class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = colors.accentColor ?? colors.cardSurfaceTint;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.heroCardBackground,
            Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.15 : 0.12),
              colors.heroCardBackground,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (colors.accentColor ?? colors.softBorder)
              .withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors.accentColor ?? Colors.black)
                .withValues(alpha: isDark ? 0.25 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
