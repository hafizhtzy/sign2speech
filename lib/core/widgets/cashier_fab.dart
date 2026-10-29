import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../constants/app_routes.dart';
import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Floating Action Button providing instant, universal access to the Cashier Counter screen.
/// Features high contrast, haptic feedback, and touch target >= 48dp.
class CashierFab extends StatelessWidget {
  final bool extended;

  const CashierFab({
    super.key,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          Get.toNamed(AppRoutes.cafeCashierCounter);
        },
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.point_of_sale_rounded, size: 22),
        label: Text(
          AppStrings.cashierAssistantTitle.tr,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        Get.toNamed(AppRoutes.cafeCashierCounter);
      },
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 4,
      tooltip: AppStrings.cashierAssistantTitle.tr,
      child: const Icon(Icons.point_of_sale_rounded, size: 24),
    );
  }
}
