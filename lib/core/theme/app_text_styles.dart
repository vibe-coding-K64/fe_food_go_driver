import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme lightTextTheme = GoogleFonts.robotoTextTheme().copyWith(
    displayLarge: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF000000),
    ),
    displayMedium: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF000000),
    ),
    displaySmall: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF000000),
    ),
    headlineLarge: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF000000),
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF000000),
    ),
    headlineSmall: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF000000),
    ),
    titleLarge: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF000000),
    ),
    titleMedium: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF000000),
    ),
    titleSmall: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF000000),
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      color: const Color(0xFF1C1C1C),
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: const Color(0xFF1C1C1C),
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: const Color(0xFF616161),
    ),
    labelLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF000000),
    ),
    labelMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF000000),
    ),
    labelSmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF616161),
    ),
  );

  static TextTheme darkTextTheme = GoogleFonts.robotoTextTheme().copyWith(
    displayLarge: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFFFFF),
    ),
    displayMedium: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFFFFF),
    ),
    displaySmall: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFFFFF),
    ),
    headlineLarge: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFFFFFF),
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFFFFFF),
    ),
    headlineSmall: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFFFFFF),
    ),
    titleLarge: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFFFFFF),
    ),
    titleMedium: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFFFFFF),
    ),
    titleSmall: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFFFFFF),
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      color: const Color(0xFFE0E0E0),
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: const Color(0xFFE0E0E0),
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: const Color(0xFF9E9E9E),
    ),
    labelLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFFFFFF),
    ),
    labelMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFFFFFF),
    ),
    labelSmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF9E9E9E),
    ),
  );
}
