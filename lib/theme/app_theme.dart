import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF3978F6);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F8FA),
      foregroundColor: Color(0xFF202938),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9ECF1)),
      ),
    ),
    dividerColor: const Color(0xFFE9ECF1),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D9EFF),
      brightness: Brightness.dark,
      surface: const Color(0xFF1B2333),
    ),
    scaffoldBackgroundColor: const Color(0xFF101522),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF101522),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1B2333),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF30394A)),
      ),
    ),
    dividerColor: const Color(0xFF30394A),
  );
}
