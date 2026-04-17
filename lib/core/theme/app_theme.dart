import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // New Olive Green / Golden Theme Colors
  static const _lightBackground = Color(0xFFF5F0E6);
  static const _lightPrimary = Color(0xFF4A5D23);
  static const _lightPrimaryContainer = Color(0xFFD4DBC4);
  static const _lightSecondaryText = Color(0xFF5D4E37);
  static const _lightCountdownText = Color(0xFFB8860B);
  static const _lightAccent = Color(0xFFD4AF37);
  static const _darkBackground = Color(0xFF1A1F15);
  static const _darkPrimary = Color(0xFF8FBC8F);
  static const _darkPrimaryContainer = Color(0xFF2D3B1F);
  static const _darkSecondaryText = Color(0xFFD4C4B0);
  static const _darkCountdownText = Color(0xFFDAA520);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: _lightPrimaryContainer,
      onPrimaryContainer: _lightPrimary,
      secondary: _lightSecondaryText,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1E8E4),
      onSecondaryContainer: _lightSecondaryText,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF0F2F1),
      onSurface: Color(0xFF1F1F1F),
      outline: Color(0xFFE1E5E2),
    ),
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: _lightBackground,
    extensions: const [
      AppThemeColors(
        heroCardBackground: _lightPrimaryContainer,
        secondaryText: _lightSecondaryText,
        countdownText: _lightCountdownText,
        prayerIcon: _lightSecondaryText,
        cardSurface: Color(0xFFFAF8F3),
        cardSurfaceTint: Color(0xFF6B7B4C),
        mutedText: Color(0xFF7A6F5B),
        softBorder: Color(0xFFD9D4C5),
        accentColor: _lightAccent,
        currentPrayerBg: Color(0xFFE7C75A),
        currentPrayerFg: Color(0xFF3B2A12),
      ),
    ],
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Cairo',
      bodyColor: const Color(0xFF1F1F1F),
      displayColor: const Color(0xFF1F1F1F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 3,
      indicatorColor: _lightPrimary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? _lightPrimary
              : const Color(0xFF5F6368),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? _lightPrimary
              : const Color(0xFF5F6368),
          size: 24,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 44),
        shape: const StadiumBorder(),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        minimumSize: const Size(64, 44),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimary,
        minimumSize: const Size(64, 44),
        side: BorderSide(color: _lightPrimary.withValues(alpha: 0.42)),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _lightPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE1E5E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE1E5E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _lightPrimary, width: 1.4),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _lightSecondaryText,
      textColor: Color(0xFF1F1F1F),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    iconTheme: const IconThemeData(color: _lightSecondaryText),
    dividerTheme: DividerThemeData(
      color: const Color(0xFF1F1F1F).withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1F1F1F),
      contentTextStyle: ThemeData.light().textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontFamily: 'Cairo',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _lightPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _lightPrimary.withValues(alpha: 0.28)
            : null,
      ),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: Color(0xFF061407),
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: _darkCountdownText,
      secondary: _darkSecondaryText,
      onSecondary: Color(0xFF1F1F1F),
      secondaryContainer: Color(0xFF2D2421),
      onSecondaryContainer: _darkSecondaryText,
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: Color(0xFF1A1A1A),
      surfaceContainerHighest: Color(0xFF232323),
      onSurface: Color(0xFFF5F5F5),
      outline: Color(0xFF2D3730),
    ),
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: _darkBackground,
    extensions: const [
      AppThemeColors(
        heroCardBackground: _darkPrimaryContainer,
        secondaryText: _darkSecondaryText,
        countdownText: _darkCountdownText,
        prayerIcon: _darkSecondaryText,
        cardSurface: Color(0xFF1E2618),
        cardSurfaceTint: Color(0xFF2A3A1F),
        mutedText: Color(0xFFC4B8A5),
        softBorder: Color(0xFF3D4A35),
        accentColor: _darkCountdownText,
        currentPrayerBg: Color(0xFF3D4A2A),
        currentPrayerFg: Colors.white,
      ),
    ],
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Cairo',
      bodyColor: const Color(0xFFF5F5F5),
      displayColor: const Color(0xFFF5F5F5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: Color(0xFFF5F5F5),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF181818),
      elevation: 3,
      indicatorColor: _darkPrimary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? _darkPrimary
              : const Color(0xFFBDBDBD),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? _darkPrimary
              : const Color(0xFFBDBDBD),
          size: 24,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF1A1A1A),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF061407),
        minimumSize: const Size(64, 44),
        shape: const StadiumBorder(),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF061407),
        elevation: 2,
        minimumSize: const Size(64, 44),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        minimumSize: const Size(64, 44),
        side: BorderSide(color: _darkPrimary.withValues(alpha: 0.48)),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _darkPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2D3730)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2D3730)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _darkPrimary, width: 1.4),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _darkSecondaryText,
      textColor: Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    iconTheme: const IconThemeData(color: _darkSecondaryText),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF232323),
      contentTextStyle: ThemeData.dark().textTheme.bodyMedium?.copyWith(
        color: const Color(0xFFF5F5F5),
        fontFamily: 'Cairo',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? _darkPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _darkPrimary.withValues(alpha: 0.3)
            : null,
      ),
    ),
  );

  static ThemeData get lightTheme => light;

  static ThemeData get darkTheme => dark;
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.heroCardBackground,
    required this.secondaryText,
    required this.countdownText,
    required this.prayerIcon,
    required this.cardSurface,
    required this.cardSurfaceTint,
    required this.mutedText,
    required this.softBorder,
    this.cardRadius = 24,
    this.accentColor,
    this.currentPrayerBg,
    this.currentPrayerFg,
  });

  final Color heroCardBackground;
  final Color secondaryText;
  final Color countdownText;
  final Color prayerIcon;
  final Color cardSurface;
  final Color cardSurfaceTint;
  final Color mutedText;
  final Color softBorder;
  final double cardRadius;
  final Color? accentColor;
  final Color? currentPrayerBg;
  final Color? currentPrayerFg;

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>()!;
  }

  @override
  AppThemeColors copyWith({
    Color? heroCardBackground,
    Color? secondaryText,
    Color? countdownText,
    Color? prayerIcon,
    Color? cardSurface,
    Color? cardSurfaceTint,
    Color? mutedText,
    Color? softBorder,
    double? cardRadius,
    Color? accentColor,
    Color? currentPrayerBg,
    Color? currentPrayerFg,
  }) {
    return AppThemeColors(
      heroCardBackground: heroCardBackground ?? this.heroCardBackground,
      secondaryText: secondaryText ?? this.secondaryText,
      countdownText: countdownText ?? this.countdownText,
      prayerIcon: prayerIcon ?? this.prayerIcon,
      cardSurface: cardSurface ?? this.cardSurface,
      cardSurfaceTint: cardSurfaceTint ?? this.cardSurfaceTint,
      mutedText: mutedText ?? this.mutedText,
      softBorder: softBorder ?? this.softBorder,
      cardRadius: cardRadius ?? this.cardRadius,
      accentColor: accentColor ?? this.accentColor,
      currentPrayerBg: currentPrayerBg ?? this.currentPrayerBg,
      currentPrayerFg: currentPrayerFg ?? this.currentPrayerFg,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      heroCardBackground: Color.lerp(
        heroCardBackground,
        other.heroCardBackground,
        t,
      )!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      countdownText: Color.lerp(countdownText, other.countdownText, t)!,
      prayerIcon: Color.lerp(prayerIcon, other.prayerIcon, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardSurfaceTint: Color.lerp(cardSurfaceTint, other.cardSurfaceTint, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      softBorder: Color.lerp(softBorder, other.softBorder, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      currentPrayerBg: Color.lerp(currentPrayerBg, other.currentPrayerBg, t),
      currentPrayerFg: Color.lerp(currentPrayerFg, other.currentPrayerFg, t),
    );
  }
}
