import 'package:flutter/material.dart';

class TintColors {
  static const charcoal = Color(0xFF353B43);
  static const sand = Color(0xFFC59C8F);
  static const cream = Color(0xFFFDFBF7);
  static const blush = Color(0xFFFFF8F6);
  static const line = Color(0xFFEEF0F2);
  static const textMuted = Color(0xFF8A8F98);
  static const success = Color(0xFF1F9D55);
  static const danger = Color(0xFFE53935);
  static const warning = Color(0xFFFB8C00);
  static const tintOrange = Color(0xFFF97316);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'sans-serif',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TintColors.sand,
        primary: TintColors.sand,
        secondary: TintColors.charcoal,
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      dividerColor: TintColors.line,
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        foregroundColor: TintColors.charcoal,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE7E8EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TintColors.sand),
        ),
        hintStyle: const TextStyle(
          color: TintColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: TintColors.line),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: const TextStyle(
          color: TintColors.charcoal,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: TintColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
