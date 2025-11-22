import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp edges
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.white, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp edges
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp edges
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp edges
          side: BorderSide(color: AppColors.tertiary, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tertiary,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, // Sharp edges
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, // Sharp edges
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, // Sharp edges
          borderSide: BorderSide(color: AppColors.white, width: 1),
        ),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate),
      ),
    );
  }

  static ThemeData get lightTheme {
    // We are focusing on dark mode for the military aesthetic, 
    // but let's keep light mode consistent just in case.
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.primary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.primary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkSlate),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkSlate),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.darkSlate),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.slate, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.slate),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.slate),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate),
      ),
    );
  }
}
