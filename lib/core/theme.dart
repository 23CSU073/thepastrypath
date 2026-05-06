import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PastryTheme {
  static const Color softPink = Color(0xFFF8C8DC);
  static const Color lavender = Color(0xFFE6E6FA);
  static const Color deepPurple = Color(0xFF967BB6);
  static const Color cream = Color(0xFFFFF5F8);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(seedColor: softPink),
    textTheme: GoogleFonts.quicksandTextTheme(),
  );
}