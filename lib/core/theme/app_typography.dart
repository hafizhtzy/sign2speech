import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized dynamic typography tokens based on Plus Jakarta Sans.
/// Adheres strictly to the project design system and supports dynamic scaling.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';

  // ── Display & Hero Styles ──────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: AppColors.ink,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: AppColors.ink,
      );

  // ── Headline Styles ────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.ink,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: AppColors.ink,
      );

  // ── Title Styles ───────────────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.ink,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.ink,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.ink,
      );

  // ── Body Styles ────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.ink,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.muted,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.muted,
      );

  // ── Label Styles ───────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.ink,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textMuted,
      );

  /// Builds a cohesive TextTheme mapped directly to Material 3 text roles.
  /// Pass [isDark] explicitly when constructing ThemeData so darkTheme never
  /// bakes in light-mode ink colors at startup.
  static TextTheme createTextTheme({bool? isDark}) {
    final bool useDark = isDark ?? AppColors.isDark;
    final Color ink = useDark ? AppColors.darkInk : AppColors.lightInk;
    final Color muted = useDark ? AppColors.darkMuted : AppColors.lightMuted;
    final Color textMuted = useDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return TextTheme(
      displayLarge: displayLarge.copyWith(color: ink),
      displayMedium: displayMedium.copyWith(color: ink),
      headlineLarge: headlineLarge.copyWith(color: ink),
      headlineMedium: headlineMedium.copyWith(color: ink),
      titleLarge: titleLarge.copyWith(color: ink),
      titleMedium: titleMedium.copyWith(color: ink),
      titleSmall: titleSmall.copyWith(color: ink),
      bodyLarge: bodyLarge.copyWith(color: ink),
      bodyMedium: bodyMedium.copyWith(color: muted),
      bodySmall: bodySmall.copyWith(color: muted),
      labelLarge: labelLarge.copyWith(color: ink),
      labelMedium: labelMedium.copyWith(color: ink),
      labelSmall: labelSmall.copyWith(color: textMuted),
    );
  }
}

/// Convenience extensions on BuildContext for clean, responsive UI coding.
extension AppThemeContextExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Clamped text scaler to protect layouts from overflowing on large OS accessibility fonts.
  TextScaler get responsiveTextScaler =>
      MediaQuery.textScalerOf(this).clamp(maxScaleFactor: 1.25);
}
