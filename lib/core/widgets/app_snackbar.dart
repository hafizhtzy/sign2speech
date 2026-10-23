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

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color subtextColor;
    Color iconColor;
    IconData defaultIcon;

    switch (variant) {
      case SnackbarVariant.success:
        defaultIcon = Icons.check_circle_rounded;
        if (isDark) {
          bgColor = const Color(0xFF142418);
          borderColor = const Color(0xFF43734D);
          textColor = const Color(0xFFFFFFFF);
          subtextColor = const Color(0xFFA5D6A7);
          iconColor = const Color(0xFF81C784);
        } else {
          bgColor = const Color(0xFF233628);
          borderColor = const Color(0xFF4A6B53);
          textColor = const Color(0xFFFFFFFF);
          subtextColor = const Color(0xFFD2E8D7);
          iconColor = const Color(0xFF88D89C);
        }
        break;

      case SnackbarVariant.warning:
        defaultIcon = Icons.warning_amber_rounded;
        if (isDark) {
          bgColor = const Color(0xFF26190B);
          borderColor = const Color(0xFFD97724);
          textColor = const Color(0xFFFFFFFF);
          subtextColor = const Color(0xFFFFCC80);
          iconColor = const Color(0xFFFFB74D);
        } else {
          bgColor = const Color(0xFF382310);
          borderColor = const Color(0xFFD97724);
          textColor = const Color(0xFFFFFFFF);
          subtextColor = const Color(0xFFFFE0B2);
          iconColor = const Color(0xFFFFB74D);
        }
        break;

      case SnackbarVariant.error:
        defaultIcon = Icons.error_outline_rounded;
        if (isDark) {
          bgColor = const Color(0xFF2A0F0F);
          borderColor = const Color(0xFFCF6679);
          textColor = const Color(0xFFFFFFFF);
          subtextColor = const Color(0xFFFFCDD2);
          iconColor = const Color(0xFFEF9A9A);
        } else {
          bgColor = const Color(0xFF3A1212);
          borderColor = const Color(0xFFBA1A1A);
          textColor = const Color(0xFFFFFFFF);
          subtextColor = const Color(0xFFFFCDD2);
          iconColor = const Color(0xFFFF8A80);
        }
        break;

      case SnackbarVariant.info:
        defaultIcon = Icons.info_outline_rounded;
        if (isDark) {
          bgColor = AppColors.darkBgSurface;
          borderColor = AppColors.darkBorderSoft;
          textColor = AppColors.darkInk;
          subtextColor = AppColors.darkMuted;
          iconColor = const Color(0xFFD49B78);
        } else {
          bgColor = AppColors.lightPrimary;
          borderColor = AppColors.lightSecondary.withValues(alpha: 0.35);
          textColor = const Color(0xFFFDFBF7);
          subtextColor = const Color(0xFFE6DCD2);
          iconColor = const Color(0xFFD49B78);
        }
        break;
    }

    final chosenIcon = icon ?? defaultIcon;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      duration: duration,
      backgroundColor: bgColor,
      borderColor: borderColor,
      borderWidth: 1.2,
      borderRadius: 14,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
          blurRadius: 16,
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
