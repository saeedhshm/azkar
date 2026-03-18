import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7C7B),
      brightness: Brightness.light,
    ),
    fontFamily: 'Cairo',
    textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Cairo'),
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4FB0AE),
      brightness: Brightness.dark,
    ),
    fontFamily: 'Cairo',
    textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Cairo'),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E2530),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
  );
}
