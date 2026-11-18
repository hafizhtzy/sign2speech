import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Semantic variants for application snackbars.
enum SnackbarVariant {
  info,
  success,
  warning,
  error,
}

/// Centralized, high-contrast accessible Snackbar utility for Sign2Speech.
///
/// Complies with WCAG 2.1 AA (contrast ratio >= 7:1) across both Light
/// ("Cafe Warm Oat Milk") and Dark ("Instagram AMOLED Minimalist") themes.
class AppSnackbar {
  AppSnackbar._();

  /// Displays a customized, accessible snackbar that dynamically responds
  /// to the active theme with guaranteed text readability.
  static void show({
    required String title,
    required String message,
    SnackbarVariant variant = SnackbarVariant.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    final isDark = AppColors.isDark;

    final (
      Color bgColor,
      Color borderColor,
      Color textColor,
      Color subtextColor,
      Color iconColor,
      IconData defaultIcon,
    ) = switch (variant) {
      SnackbarVariant.success => isDark
          ? (
              const Color(0xFF132618),
              const Color(0xFF4E8A5C),
              const Color(0xFFFFFFFF),
              const Color(0xFFDCF5E0),
              const Color(0xFF81C784),
              Icons.check_circle_rounded,
            )
          : (
              const Color(0xFF233628),
              const Color(0xFF4A6B53),
              const Color(0xFFFFFFFF),
              const Color(0xFFE6F4E9),
              const Color(0xFF88D89C),
              Icons.check_circle_rounded,
            ),
      SnackbarVariant.warning => isDark
          ? (
              const Color(0xFF2A1A0A),
              const Color(0xFFE88B35),
              const Color(0xFFFFFFFF),
              const Color(0xFFFFE8C2),
              const Color(0xFFFFB74D),
              Icons.warning_amber_rounded,
            )
          : (
              const Color(0xFF382310),
              const Color(0xFFD97724),
              const Color(0xFFFFFFFF),
              const Color(0xFFFFE8C8),
              const Color(0xFFFFB74D),
              Icons.warning_amber_rounded,
            ),
      SnackbarVariant.error => isDark
          ? (
              const Color(0xFF2E1014),
              const Color(0xFFE06C7E),
              const Color(0xFFFFFFFF),
              const Color(0xFFFFE0E3),
              const Color(0xFFFF8A9A),
              Icons.error_outline_rounded,
            )
          : (
              const Color(0xFF3A1212),
              const Color(0xFFBA1A1A),
              const Color(0xFFFFFFFF),
              const Color(0xFFFFE0E3),
              const Color(0xFFFF8A80),
              Icons.error_outline_rounded,
            ),
      SnackbarVariant.info => isDark
          ? (
              const Color(0xFF222222),
              const Color(0xFF3E3E3E),
              const Color(0xFFFFFFFF),
              const Color(0xFFE5E5E5),
              AppColors.darkSecondary,
              Icons.info_outline_rounded,
            )
          : (
              AppColors.lightPrimary,
              AppColors.lightSecondary.withValues(alpha: 0.35),
              const Color(0xFFFDFBF7),
              const Color(0xFFEFE6DC),
              AppColors.darkSecondary,
              Icons.info_outline_rounded,
            ),
    };

    final chosenIcon = icon ?? defaultIcon;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      duration: duration,
      backgroundColor: bgColor,
      colorText: textColor,
      borderColor: borderColor,
      borderWidth: 1.2,
      borderRadius: 14,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.18),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Icon(
        chosenIcon,
        color: iconColor,
        size: 22,
      ),
      titleText: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: subtextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Convenience shortcut for success feedback (e.g. saved, downloaded, finished).
  static void success({
    required String title,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      variant: SnackbarVariant.success,
      icon: icon,
      duration: duration,
      position: position,
    );
  }

  /// Convenience shortcut for general informational feedback.
  static void info({
    required String title,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      variant: SnackbarVariant.info,
      icon: icon,
      duration: duration,
      position: position,
    );
  }

  /// Convenience shortcut for warning alerts.
  static void warning({
    required String title,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      variant: SnackbarVariant.warning,
      icon: icon,
      duration: duration,
      position: position,
    );
  }

  /// Convenience shortcut for error and failure alerts.
  static void error({
    required String title,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      variant: SnackbarVariant.error,
      icon: icon,
      duration: duration,
      position: position,
    );
  }
}
