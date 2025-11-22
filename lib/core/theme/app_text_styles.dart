import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 64,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 52,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 44,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontFamily: 'Syne',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.slate,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.slate,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.slate,
      );

  static TextStyle get labelLarge => GoogleFonts.firaCode(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.secondary,
      );

  static TextStyle get labelMedium => GoogleFonts.firaCode(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.secondary,
      );

  static TextStyle get labelSmall => GoogleFonts.firaCode(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.secondary,
      );
}
