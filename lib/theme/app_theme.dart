import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF0D3B1E);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF5E6B8);
  static const Color cream = Color(0xFFFFF8E7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
        surface: cream,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: accentGold,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
