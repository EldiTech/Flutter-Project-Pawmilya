import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFFF9554);
  static const Color primaryLight = Color(0xFFFFB584);
  static const Color primaryDark = Color(0xFFE87E3A);
  static const Color warmBg = Color(0xFFFFF8F3);
  static const Color warmAccent = Color(0xFFFFE4C9);
  static const Color textDark = Color(0xFF8B5E34);
  static const Color textMid = Color(0xFFA67C52);
  static const Color textMuted = Color(0xFF8B7355);
  static const Color white = Colors.white;
  static const Color adoptionGreen = Color(0xFF22C55E);
}

class AppTheme {
  static TextStyle get headingStyle => GoogleFonts.quicksand(
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle get bodyStyle =>
      GoogleFonts.quicksand(color: AppColors.textDark);

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: AppColors.warmBg,
    textTheme: GoogleFonts.quicksandTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.warmBg,
    ),
  );
}
