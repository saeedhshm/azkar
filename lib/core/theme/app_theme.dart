import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── Olive Green / Golden Palette ────────────────────────────────────────────
  // Light mode primaries
  static const _lightBackground = Color(0xFFF5F0E6);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightPrimary = Color(0xFF4A5D23);
  static const _lightPrimaryContainer = Color(0xFFD4DBC4);
  static const _lightSecondary = Color(0xFF5D4E37);
  static const _lightAccent = Color(0xFFD4AF37);
  static const _lightCountdown = Color(0xFFB8860B);

  // Dark mode primaries
  static const _darkBackground = Color(0xFF1A1F15);
  static const _darkSurface = Color(0xFF1A1A1A);
  static const _darkPrimary = Color(0xFF8FBC8F);
  static const _darkPrimaryContainer = Color(0xFF2D3B1F);
  static const _darkSecondary = Color(0xFFD4C4B0);
  static const _darkAccent = Color(0xFFDAA520);

  // ─── Light Theme ─────────────────────────────────────────────────────────────
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: _lightPrimaryContainer,
      onPrimaryContainer: _lightPrimary,
      secondary: _lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1E8E4),
      onSecondaryContainer: _lightSecondary,
      tertiary: _lightAccent,
      onTertiary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFFDE8E8),
      onErrorContainer: Color(0xFFB3261E),
      surface: _lightSurface,
      onSurface: Color(0xFF1F1F1F),
      surfaceContainerHighest: Color(0xFFF0F2F1),
      outline: Color(0xFFE1E5E2),
      outlineVariant: Color(0xFFD9D4C5),
      shadow: Colors.black,
      inverseSurface: Color(0xFF1F1F1F),
      onInverseSurface: Colors.white,
      inversePrimary: _darkPrimary,
    ),
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: _lightBackground,
    extensions: const [
      AppThemeColors(
        // Backgrounds
        heroCardBackground: _lightPrimaryContainer,
        cardSurface: Color(0xFFFAF8F3),
        cardSurfaceTint: Color(0xFF6B7B4C),
        inputSurface: Colors.white,
        navBarBg: Colors.white,
        pillBg: Color(0xFFF0EDE4),
        shimmerBase: Color(0xFFE8E3D8),
        shimmerHighlight: Color(0xFFFAF8F3),
        // Text
        secondaryText: _lightSecondary,
        mutedText: Color(0xFF7A6F5B),
        countdownText: _lightCountdown,
        // Borders
        softBorder: Color(0xFFD9D4C5),
        // Icons
        prayerIcon: _lightSecondary,
        // Accents
        accentColor: _lightAccent,
        successColor: Color(0xFF4A7C59),
        // Prayer specific
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
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 64,
      indicatorColor: _lightPrimary.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? _lightPrimary
              : const Color(0xFF5F6368),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 11,
          fontFamily: 'Cairo',
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? _lightPrimary
              : const Color(0xFF5F6368),
          size: 22,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: const Color(0xFFFAF8F3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD9D4C5), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimary,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        side: BorderSide(color: _lightPrimary.withValues(alpha: 0.42)),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimary,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE1E5E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE1E5E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontFamily: 'Cairo',
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _lightSecondary,
      textColor: Color(0xFF1F1F1F),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minLeadingWidth: 24,
    ),
    iconTheme: const IconThemeData(color: _lightSecondary),
    dividerTheme: DividerThemeData(
      color: const Color(0xFF1F1F1F).withValues(alpha: 0.07),
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C1C1E),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Cairo',
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: _lightAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _lightPrimary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _lightPrimaryContainer.withValues(alpha: 0.5),
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _lightPrimary,
      linearTrackColor: Color(0xFFD9D4C5),
    ),
  );

  // ─── Dark Theme ──────────────────────────────────────────────────────────────
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: Color(0xFF061407),
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: _darkAccent,
      secondary: _darkSecondary,
      onSecondary: Color(0xFF1F1F1F),
      secondaryContainer: Color(0xFF2D2421),
      onSecondaryContainer: _darkSecondary,
      tertiary: _darkAccent,
      onTertiary: Color(0xFF1F1F1F),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF3B1412),
      onErrorContainer: Color(0xFFF2B8B5),
      surface: _darkSurface,
      onSurface: Color(0xFFF5F5F5),
      surfaceContainerHighest: Color(0xFF232323),
      outline: Color(0xFF2D3730),
      outlineVariant: Color(0xFF3D4A35),
      shadow: Colors.black,
      inverseSurface: Color(0xFFF5F5F5),
      onInverseSurface: Color(0xFF1F1F1F),
      inversePrimary: _lightPrimary,
    ),
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: _darkBackground,
    extensions: const [
      AppThemeColors(
        // Backgrounds
        heroCardBackground: _darkPrimaryContainer,
        cardSurface: Color(0xFF1E2618),
        cardSurfaceTint: Color(0xFF2A3A1F),
        inputSurface: Color(0xFF242424),
        navBarBg: Color(0xFF181818),
        pillBg: Color(0xFF252B1E),
        shimmerBase: Color(0xFF232323),
        shimmerHighlight: Color(0xFF2E2E2E),
        // Text
        secondaryText: _darkSecondary,
        mutedText: Color(0xFFC4B8A5),
        countdownText: _darkAccent,
        // Borders
        softBorder: Color(0xFF3D4A35),
        // Icons
        prayerIcon: _darkSecondary,
        // Accents
        accentColor: _darkAccent,
        successColor: Color(0xFF6EAB7D),
        // Prayer specific
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
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF5F5F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF181818),
      elevation: 0,
      height: 64,
      indicatorColor: _darkPrimary.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? _darkPrimary
              : const Color(0xFFBDBDBD),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 11,
          fontFamily: 'Cairo',
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? _darkPrimary
              : const Color(0xFFBDBDBD),
          size: 22,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E2618),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF3D4A35), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF061407),
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF061407),
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        side: BorderSide(color: _darkPrimary.withValues(alpha: 0.48)),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF242424),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2D3730)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2D3730)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF2B8B5)),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF666666),
        fontFamily: 'Cairo',
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _darkSecondary,
      textColor: Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minLeadingWidth: 24,
    ),
    iconTheme: const IconThemeData(color: _darkSecondary),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.07),
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E2618),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2C2C2E),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Cairo',
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: _darkAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _darkPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _darkPrimary.withValues(alpha: 0.3)
            : null,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _darkPrimary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkPrimaryContainer.withValues(alpha: 0.7),
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Color(0xFFF5F5F5),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _darkPrimary,
      linearTrackColor: Color(0xFF3D4A35),
    ),
  );

  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;
}

// ─── AppThemeColors Extension ─────────────────────────────────────────────────
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
    required this.inputSurface,
    required this.navBarBg,
    required this.pillBg,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.successColor,
    this.cardRadius = 20,
    this.accentColor,
    this.currentPrayerBg,
    this.currentPrayerFg,
  });

  // Backgrounds
  final Color heroCardBackground;
  final Color cardSurface;
  final Color cardSurfaceTint;
  final Color inputSurface;
  final Color navBarBg;
  final Color pillBg;

  // Shimmer
  final Color shimmerBase;
  final Color shimmerHighlight;

  // Text
  final Color secondaryText;
  final Color mutedText;
  final Color countdownText;

  // Borders & Icons
  final Color softBorder;
  final Color prayerIcon;

  // Accents
  final Color? accentColor;
  final Color successColor;

  // Radii & Prayer
  final double cardRadius;
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
    Color? inputSurface,
    Color? navBarBg,
    Color? pillBg,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? successColor,
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
      inputSurface: inputSurface ?? this.inputSurface,
      navBarBg: navBarBg ?? this.navBarBg,
      pillBg: pillBg ?? this.pillBg,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      successColor: successColor ?? this.successColor,
      cardRadius: cardRadius ?? this.cardRadius,
      accentColor: accentColor ?? this.accentColor,
      currentPrayerBg: currentPrayerBg ?? this.currentPrayerBg,
      currentPrayerFg: currentPrayerFg ?? this.currentPrayerFg,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      heroCardBackground:
          Color.lerp(heroCardBackground, other.heroCardBackground, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      countdownText: Color.lerp(countdownText, other.countdownText, t)!,
      prayerIcon: Color.lerp(prayerIcon, other.prayerIcon, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardSurfaceTint: Color.lerp(cardSurfaceTint, other.cardSurfaceTint, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      softBorder: Color.lerp(softBorder, other.softBorder, t)!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      navBarBg: Color.lerp(navBarBg, other.navBarBg, t)!,
      pillBg: Color.lerp(pillBg, other.pillBg, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      currentPrayerBg:
          Color.lerp(currentPrayerBg, other.currentPrayerBg, t),
      currentPrayerFg:
          Color.lerp(currentPrayerFg, other.currentPrayerFg, t),
    );
  }
}
