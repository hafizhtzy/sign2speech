import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core Surfaces & Backgrounds ──────────────────────────────────────────
  /// Background Utama: Warm Oat Milk / Cream (#FDFBF7)
  static const Color canvas = Color(0xFFFDFBF7);
  static const Color bgPrimary = Color(0xFFFDFBF7);

  /// Surface / Card Sekunder: Soft Latte Foam (#F4EFE6)
  static const Color bgSurface = Color(0xFFF4EFE6);
  static const Color paleMist = Color(0xFFF4EFE6); // Backward-compat alias
  static const Color softFjord = Color(0xFFF4EFE6); // Backward-compat alias
  static const Color surfaceHigh = Color(0xFFF4EFE6); // Backward-compat alias

  /// Elevated Card Surface: Pure Warm White (#FFFFFF)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFFFFFFF);

  /// Card & Input Borders: Warm Sand Border (#E6DCD2)
  static const Color border = Color(0xFFE6DCD2);
  static const Color borderSubtle = Color(0xFFE6DCD2);
  static const Color borderSoft = Color(0xFFE6DCD2);

  /// Cafe Ticket Divider: Dashed Divider Line (#D5C7B8)
  static const Color borderDashed = Color(0xFFD5C7B8);

  // ── Brand & Interactive Accents ──────────────────────────────────────────
  /// Primary Espresso: Rich Espresso Brown (#2C1E18)
  static const Color primary = Color(0xFF2C1E18);
  static const Color primaryEspresso = Color(0xFF2C1E18);

  /// Secondary Caramel: Warm Caramel / Cinnamon (#8C5A3C)
  static const Color secondary = Color(0xFF8C5A3C);
  static const Color secondaryCaramel = Color(0xFF8C5A3C);

  /// Accent Matcha: Matcha Sage (#4A6B53) - Offline Status & Success
  static const Color matcha = Color(0xFF4A6B53);
  static const Color accentMatcha = Color(0xFF4A6B53);

  /// Accent Amber: Amber Gold (#D97724) - Highlights & Badges
  static const Color amber = Color(0xFFD97724);
  static const Color accentAmber = Color(0xFFD97724);

  // ── Typography Colors ────────────────────────────────────────────────────
  /// Headings & Main Titles: Rich Espresso Brown (#2C1E18)
  static const Color ink = Color(0xFF2C1E18);
  static const Color textPrimary = Color(0xFF2C1E18);

  /// Body Copy & Subtitles: Muted Roasted Mocha (#6E5A4F)
  static const Color muted = Color(0xFF6E5A4F);
  static const Color textSecondary = Color(0xFF6E5A4F);

  /// Placeholders & Captions: Warm Taupe (#9A8679)
  static const Color textMuted = Color(0xFF9A8679);

  /// Text on Dark Cards & Buttons: Warm Oat Milk White (#FDFBF7)
  static const Color textOnDark = Color(0xFFFDFBF7);

  // ── Semantic Feedback ────────────────────────────────────────────────────
  static const Color success = Color(0xFF4A6B53); // Matcha Sage
  static const Color warning = Color(0xFFD97724); // Amber Gold
  static const Color error = Color(0xFFBA1A1A);
}
