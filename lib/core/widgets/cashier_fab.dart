import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../features/customer/screens/customer_checkout_screen.dart';
import '../auth/controllers/auth_controller.dart';
import '../constants/app_routes.dart';
import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_snackbar.dart';

/// Floating Action Button providing role-aware quick access:
/// - Guest (unauthenticated) or `CUSTOMER` -> "Order" (`Icons.local_cafe_rounded`)
/// - `CASHIER` -> "Alat Kasir & Belanja" (`Icons.point_of_sale_rounded`)
/// - `ADMIN` -> hidden
class CashierFab extends StatelessWidget {
  final bool extended;

  const CashierFab({super.key, this.extended = false});

  void _handleTap() {
    HapticFeedback.lightImpact();
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;

    if (auth != null && auth.isAuthenticated) {
      if (auth.isCashier) {
        Get.toNamed(AppRoutes.cafeCashierCounter);
        return;
      }
      if (auth.isAdmin) {
        Get.toNamed(AppRoutes.adminDashboard);
        return;
      }
      if (auth.isCustomer) {
        final hasRoute = Get.routeTree.routes.any(
          (r) => r.name == AppRoutes.customerCheckout,
        );
        if (hasRoute) {
          Get.toNamed(AppRoutes.customerCheckout);
        } else {
          Get.to(
            () => const CustomerCheckoutScreen(),
            routeName: AppRoutes.customerCheckout,
            transition: Transition.rightToLeft,
          );
        }
        return;
      }
      AppSnackbar.error(
        title: AppStrings.appTitle.tr,
        message: AppStrings.authAccessDeniedNotice.tr,
      );
      return;
    }

    // Unauthenticated (Guest): redirect to Login screen to start ordering
    Get.toNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      return Obx(() {
        auth.currentProfile.value;
        auth.sessionState.value;
        if (auth.isAuthenticated && auth.isAdmin) {
          return const SizedBox.shrink();
        }
        final isCashier = auth.isAuthenticated && auth.isCashier;
        return _buildFab(isCashier: isCashier);
      });
    }
    return _buildFab(isCashier: false);
  }

  Widget _buildFab({required bool isCashier}) {
    final label = isCashier
        ? AppStrings.cashierAssistantTitle.tr
        : AppStrings.customerOrderCardTitle.tr;
    final iconData = isCashier
        ? Icons.point_of_sale_rounded
        : Icons.local_cafe_rounded;

    if (extended) {
      return FloatingActionButton.extended(
        onPressed: _handleTap,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(iconData, size: 22),
        label: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: _handleTap,
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 4,
      tooltip: label,
      child: Icon(iconData, size: 24),
    );
  }
}
