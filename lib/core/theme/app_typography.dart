import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme lightTextTheme = _buildTextTheme(AppColors.textPrimaryLight);
  static TextTheme darkTextTheme = _buildTextTheme(AppColors.textPrimaryDark);

  static TextTheme _buildTextTheme(Color textColor) {
    final secondary = textColor.withOpacity(0.6);
    return TextTheme(
      // Headings — Poppins
      displayLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700, color: textColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w700, color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600, color: textColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w600, color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: textColor,
      ),
      // Body — Inter
      titleLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w500, color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400, color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, color: secondary,
      ),
    );
  }
}
