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
  });

  final Color background;
  final Color nextPrayerCard;
  final Color countdown;
  final Color primaryButton;
  final Color prayerIcon;
  final Color cardSurface;
  final Color cardBorder;
  final Color mutedText;

  static PrayerHomeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  static const light = PrayerHomeColors(
    background: Color(0xFFF8F9FA),
    nextPrayerCard: Color(0xFFE8F5E9),
    countdown: Color(0xFF2E7D32),
    primaryButton: Color(0xFF1B5E20),
    prayerIcon: Color(0xFF5D4037),
    cardSurface: Colors.white,
    cardBorder: Color(0xFFE0E5E2),
    mutedText: Color(0xFF66706A),
  );

  static const dark = PrayerHomeColors(
    background: Color(0xFF121212),
    nextPrayerCard: Color(0xFF1E2A1E),
    countdown: Color(0xFF81C784),
    primaryButton: Color(0xFF4CAF50),
    prayerIcon: Color(0xFFD7CCC8),
    cardSurface: Color(0xFF1A1A1A),
    cardBorder: Color(0xFF2C332C),
    mutedText: Color(0xFFB8C2BA),
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
    );
  }
}
