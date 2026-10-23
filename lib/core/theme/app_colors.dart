import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single Source of Truth for Design System Colors.
/// Supports both:
/// 1. Warm Oat Milk / Cafe Espresso (Light Mode)
/// 2. Instagram AMOLED Minimalist Dark Mode (Dark Mode)
class AppColors {
  AppColors._();

  // ── Light Mode Token Constants ───────────────────────────────────────────
  static const Color lightCanvas = Color(0xFFFDFBF7);
  static const Color lightBgSurface = Color(0xFFF4EFE6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6DCD2);
  static const Color lightBorderSoft = Color(0xFFE6DCD2);
  static const Color lightBorderDashed = Color(0xFFD5C7B8);
  static const Color lightPrimary = Color(0xFF2C1E18);
  static const Color lightSecondary = Color(0xFF8C5A3C);
  static const Color lightMatcha = Color(0xFF4A6B53);
  static const Color lightAmber = Color(0xFFD97724);
  static const Color lightInk = Color(0xFF2C1E18);
  static const Color lightMuted = Color(0xFF6E5A4F);
  static const Color lightTextMuted = Color(0xFF9A8679);
  static const Color lightOnPrimary = Color(0xFFFDFBF7);

  // ── Instagram AMOLED Dark Mode Token Constants ───────────────────────────
  /// Pure True AMOLED Black
  static const Color darkCanvas = Color(0xFF000000);
  /// Elevated Container / Chip Surface (#1E1E1E)
  static const Color darkBgSurface = Color(0xFF1E1E1E);
  /// Instagram Card Surface (#121212)
  static const Color darkSurface = Color(0xFF121212);
  /// Subtle Dark Outline (#262626)
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkBorderSoft = Color(0xFF2E2E2E);
  static const Color darkBorderDashed = Color(0xFF333333);
  /// Instagram Action White (#F5F5F5)
  static const Color darkPrimary = Color(0xFFF5F5F5);
  /// Warm Cinnamon Caramel for Dark Mode Contrast (>= 7:1)
  static const Color darkSecondary = Color(0xFFD49B78);
  /// Luminous Matcha Sage for Dark Mode
  static const Color darkMatcha = Color(0xFF5E9E70);
  /// Luminous Amber Gold for Dark Mode
  static const Color darkAmber = Color(0xFFF59E0B);
  /// Crisp White Typography
  static const Color darkInk = Color(0xFFF5F5F5);
  /// Instagram Secondary Body Grey (#A8A8A8)
  static const Color darkMuted = Color(0xFFA8A8A8);
  /// Instagram Placeholder Grey (#737373)
  static const Color darkTextMuted = Color(0xFF737373);
  /// Deep Charcoal for text on white primary button
  static const Color darkOnPrimary = Color(0xFF121212);

  // ── Active Theme Mode Detector ───────────────────────────────────────────
  static bool? isDarkModeOverride;

  static bool get isDark {
    if (isDarkModeOverride != null) {
      return isDarkModeOverride!;
    }
    try {
      if (Get.context != null) {
        return Theme.of(Get.context!).brightness == Brightness.dark;
      }
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } catch (_) {
      return false;
    }
  }

  // ── Dynamic Responsive Getters (Switch dynamically with theme) ────────────
  /// Main Scaffold Background (Light: #FDFBF7, Dark: #000000)
  static Color get canvas => isDark ? darkCanvas : lightCanvas;
  static Color get bgPrimary => canvas;

  /// Secondary Surface / Foam / Chips (Light: #F4EFE6, Dark: #1E1E1E)
  static Color get bgSurface => isDark ? darkBgSurface : lightBgSurface;
  static Color get paleMist => bgSurface;
  static Color get softFjord => bgSurface;
  static Color get surfaceHigh => bgSurface;

  /// Card Surfaces (Light: #FFFFFF, Dark: #121212)
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get bgCard => surface;

  /// Outlines & Dividers (Light: #E6DCD2, Dark: #262626)
  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get borderSubtle => border;
  static Color get borderSoft => isDark ? darkBorderSoft : lightBorderSoft;
  static Color get borderDashed => isDark ? darkBorderDashed : lightBorderDashed;

  /// Primary Brand Accent
  static Color get primary => isDark ? darkPrimary : lightPrimary;
  static Color get primaryEspresso => lightPrimary;

  /// Secondary Warm Caramel
  static Color get secondary => isDark ? darkSecondary : lightSecondary;
  static Color get secondaryCaramel => lightSecondary;

  /// Semantic Accents
  static Color get matcha => isDark ? darkMatcha : lightMatcha;
  static Color get accentMatcha => matcha;
  static Color get amber => isDark ? darkAmber : lightAmber;
  static Color get accentAmber => amber;

  /// Typography
  static Color get ink => isDark ? darkInk : lightInk;
  static Color get textPrimary => ink;
  static Color get muted => isDark ? darkMuted : lightMuted;
  static Color get textSecondary => muted;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get onPrimary => isDark ? darkOnPrimary : lightOnPrimary;
  static const Color textOnDark = Color(0xFFFDFBF7);

  /// Status Feedback
  static Color get success => matcha;
  static Color get warning => amber;
  static Color get error => isDark ? const Color(0xFFCF6679) : const Color(0xFFBA1A1A);

  /// Camera Viewports
  static const Color cameraDark = Color(0xFF191210);
  static const Color cameraDarkElevated = Color(0xFF231B17);
}
