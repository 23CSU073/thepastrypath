import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const warmBrown = Color(0xFF8B5E3C);
  static const espresso = Color(0xFF3D2A1E);
  static const cream = Color(0xFFFFE6EE);
  static const orange = Color(0xFFF6A6B8);
  static const blush = Color(0xFFFFF5F8);
  static const sage = Color(0xFF8BA17F);
  static const ink = Color(0xFF241A14);
  static const muted = Color(0xFF7B6A5E);
}

class AppTheme {
  static ThemeData light() {
    final base = GoogleFonts.nunitoTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.blush,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.warmBrown,
        primary: AppColors.warmBrown,
        secondary: AppColors.orange,
        surface: Colors.white,
      ),
      textTheme: base.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.nunito(color: AppColors.muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmBrown,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.espresso,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.nunito(color: Colors.white),
      ),
    );
  }
}
