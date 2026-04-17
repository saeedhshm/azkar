import 'package:flutter/material.dart';

class PrayerHomeColors extends ThemeExtension<PrayerHomeColors> {
  const PrayerHomeColors({
    required this.background,
    required this.nextPrayerCard,
    required this.countdown,
    required this.primaryButton,
    required this.prayerIcon,
    required this.cardSurface,
    required this.cardBorder,
    required this.mutedText,
    required this.nowBadgeBg,
    required this.nowBadgeFg,
  });

  final Color background;
  final Color nextPrayerCard;
  final Color countdown;
  final Color primaryButton;
  final Color prayerIcon;
  final Color cardSurface;
  final Color cardBorder;
  final Color mutedText;
  final Color nowBadgeBg;
  final Color nowBadgeFg;

  static PrayerHomeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  // Olive Green / Golden palette aligned with AppTheme
  static const light = PrayerHomeColors(
    background: Color(0xFFF5F0E6),
    nextPrayerCard: Color(0xFFD4DBC4),
    countdown: Color(0xFFB8860B),
    primaryButton: Color(0xFF4A5D23),
    prayerIcon: Color(0xFF5D4E37),
    cardSurface: Color(0xFFFAF8F3),
    cardBorder: Color(0xFFD9D4C5),
    mutedText: Color(0xFF7A6F5B),
    nowBadgeBg: Color(0xFFD4634A),
    nowBadgeFg: Colors.white,
  );

  static const dark = PrayerHomeColors(
    background: Color(0xFF1A1F15),
    nextPrayerCard: Color(0xFF2D3B1F),
    countdown: Color(0xFFDAA520),
    primaryButton: Color(0xFFDAA520),
    prayerIcon: Color(0xFFD4C4B0),
    cardSurface: Color(0xFF1E2618),
    cardBorder: Color(0xFF3D4A35),
    mutedText: Color(0xFFC4B8A5),
    nowBadgeBg: Color(0xFFDAA520),
    nowBadgeFg: Colors.white,
  );

  @override
  PrayerHomeColors copyWith({
    Color? background,
    Color? nextPrayerCard,
    Color? countdown,
    Color? primaryButton,
    Color? prayerIcon,
    Color? cardSurface,
    Color? cardBorder,
    Color? mutedText,
    Color? nowBadgeBg,
    Color? nowBadgeFg,
  }) {
    return PrayerHomeColors(
      background: background ?? this.background,
      nextPrayerCard: nextPrayerCard ?? this.nextPrayerCard,
      countdown: countdown ?? this.countdown,
      primaryButton: primaryButton ?? this.primaryButton,
      prayerIcon: prayerIcon ?? this.prayerIcon,
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      mutedText: mutedText ?? this.mutedText,
      nowBadgeBg: nowBadgeBg ?? this.nowBadgeBg,
      nowBadgeFg: nowBadgeFg ?? this.nowBadgeFg,
    );
  }

  @override
  PrayerHomeColors lerp(ThemeExtension<PrayerHomeColors>? other, double t) {
    if (other is! PrayerHomeColors) {
      return this;
    }
    return PrayerHomeColors(
      background: Color.lerp(background, other.background, t)!,
      nextPrayerCard: Color.lerp(nextPrayerCard, other.nextPrayerCard, t)!,
      countdown: Color.lerp(countdown, other.countdown, t)!,
      primaryButton: Color.lerp(primaryButton, other.primaryButton, t)!,
      prayerIcon: Color.lerp(prayerIcon, other.prayerIcon, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      nowBadgeBg: Color.lerp(nowBadgeBg, other.nowBadgeBg, t)!,
      nowBadgeFg: Color.lerp(nowBadgeFg, other.nowBadgeFg, t)!,
    );
  }
}
