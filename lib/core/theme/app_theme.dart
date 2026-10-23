import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized Theme Configuration for Sign2Speech.
/// Supports:
/// 1. Warm Oat Milk / Espresso (Light Mode)
/// 2. Instagram AMOLED Minimalist Dark Mode (Dark Mode)
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnPrimary,
        tertiary: AppColors.lightMatcha,
        onTertiary: AppColors.lightOnPrimary,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightInk,
        surfaceContainerHighest: AppColors.lightBgSurface,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorderSoft,
      ),
      textTheme: AppTypography.createTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.lightInk, size: 24),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.lightInk,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightInk,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightSecondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBgSurface,
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.lightInk),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFFFDFBF7),
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.lightSecondary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextMuted,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: Color(0xFF121212),
        tertiary: AppColors.darkMatcha,
        onTertiary: Color(0xFF121212),
        error: Color(0xFFCF6679),
        onError: Colors.black,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkInk,
        surfaceContainerHighest: AppColors.darkBgSurface,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderSoft,
      ),
      textTheme: AppTypography.createTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkInk, size: 24),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkInk,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkInk,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkSecondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBgSurface,
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.darkInk),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkBgSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkInk,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: AppColors.darkBorderSoft,
            width: 1.2,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCanvas,
        selectedItemColor: AppColors.darkInk,
        unselectedItemColor: AppColors.darkTextMuted,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
