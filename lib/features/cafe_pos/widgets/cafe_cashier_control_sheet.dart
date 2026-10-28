import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../screens/cafe_order_queue_screen.dart';
import 'cafe_menu_catalog_sheet.dart';
import 'cafe_staff_pin_dialog.dart';

/// Modal Bottom Sheet for Cafe Cashier Controls & Settings.
/// Centralizes sign language model toggles, queue management, staff PIN authentication,
/// and transaction reset in a responsive, accessible bottom sheet.
class CafeCashierControlSheet extends StatelessWidget {
  final CafeCashierController controller;

  const CafeCashierControlSheet({
    super.key,
    required this.controller,
  });

  /// Displays the control bottom sheet with responsive width constraints.
  static Future<void> show({
    required BuildContext context,
    required CafeCashierController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CafeCashierControlSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.90;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: maxSheetHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.cafeControlSheetTitle.tr,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              AppStrings.cafeControlSheetSubtitle.tr,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.muted,
                        tooltip: 'Tutup',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(height: 1, thickness: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  // ── SECTION 1: Model Bahasa Isyarat ────────────────────────
                  _buildSignModelSection(context),

                  const SizedBox(height: 14),

                  // ── SECTION 2: Antrean Pesanan Kafe ────────────────────────
                  _buildQueueSection(context),

                  const SizedBox(height: 10),

                  // ── SECTION 2B: Akses Katalog Menu Kafe ────────────────────
                  _buildMenuCatalogTile(context),

                  const SizedBox(height: 14),

                  // ── SECTION 3: Keamanan & PIN Staf ─────────────────────────
                  _buildStaffSecuritySection(context),

                  const SizedBox(height: 14),

                  // ── SECTION 4: Reset Sesi Transaksi ────────────────────────
                  _buildResetSessionSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignModelSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sign_language_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.cafeControlSignModelTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.cafeControlSignModelDesc.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final active = controller.activeSignModel;
            return Row(
              children: [
                Expanded(
                  child: _buildModelChoiceCard(
                    model: SignLanguageModel.bisindo,
                    label: 'BISINDO',
                    description: AppStrings.cafeControlBisindoDesc.tr,
                    isSelected: active == SignLanguageModel.bisindo,
                    onTap: () {
                      controller.switchSignLanguageModel(SignLanguageModel.bisindo);
                      AppSnackbar.show(
                        title: 'Model Bahasa Isyarat',
                        message: AppStrings.cafeSignModelChanged.trParams({'model': 'BISINDO'}),
                        variant: SnackbarVariant.info,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModelChoiceCard(
                    model: SignLanguageModel.sibi,
                    label: 'SIBI',
                    description: AppStrings.cafeControlSibiDesc.tr,
                    isSelected: active == SignLanguageModel.sibi,
                    onTap: () {
                      controller.switchSignLanguageModel(SignLanguageModel.sibi);
                      AppSnackbar.show(
                        title: 'Model Bahasa Isyarat',
                        message: AppStrings.cafeSignModelChanged.trParams({'model': 'SIBI'}),
                        variant: SnackbarVariant.info,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModelChoiceCard({
    required SignLanguageModel model,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? AppColors.matcha : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.muted,
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSection(BuildContext context) {
    return Obx(() {
      final queueCount = controller.activeOrdersQueue.length;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: queueCount > 0
                    ? AppColors.matcha.withValues(alpha: 0.15)
                    : AppColors.paleMist,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: queueCount > 0 ? AppColors.matcha : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: queueCount > 0 ? AppColors.matcha : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cafeControlQueueTitle.tr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    AppStrings.cafeControlQueueDesc.trParams({'count': '$queueCount'}),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                CafeOrderQueueScreen.showAsDialog(
                  context,
                  controller: controller,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.cafeControlQueueOpen.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuCatalogTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cafeModeMenuCatalog.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Lihat menu kopi, teh, & camilan kafe',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              CafeMenuCatalogSheet.show(
                context: context,
                catalog: CoffeeMenuItem.standardCatalog,
                onSelectItem: (item) {
                  controller.addRecommendedItemToTicket(item);
                  controller.onTranscriptReceived(
                    'pesan ${item.nameId}',
                    triggerSign: true,
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buka',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSecuritySection(BuildContext context) {
    return Obx(() {
      final isAuthenticated = controller.staffPinAuthenticated.value;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? AppColors.matcha.withValues(alpha: 0.15)
                    : AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAuthenticated ? AppColors.matcha : AppColors.amber,
                ),
              ),
              child: Icon(
                isAuthenticated ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 20,
                color: isAuthenticated ? AppColors.matcha : AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cafeControlStaffTitle.tr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    isAuthenticated
                        ? AppStrings.cafeControlStaffLoggedIn.tr
                        : AppStrings.cafeControlStaffLocked.tr,
                    style: AppTypography.bodySmall.copyWith(
                      color: isAuthenticated ? AppColors.matcha : AppColors.muted,
                      fontWeight: isAuthenticated ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                if (isAuthenticated) {
                  controller.logoutStaff();
                } else {
                  Navigator.of(context).pop();
                  await CafeStaffPinDialog.show(
                    context,
                    onVerify: controller.verifyStaffPin,
                    title: 'PIN Staf Kasir',
                    subtitle: 'Masukkan PIN untuk melanjutkan',
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAuthenticated ? AppColors.paleMist : AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAuthenticated
                      ? AppStrings.cafeControlStaffLogout.tr
                      : AppStrings.cafeControlStaffLogin.tr,
                  style: AppTypography.labelSmall.copyWith(
                    color: isAuthenticated ? AppColors.ink : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResetSessionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cafeControlResetTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  AppStrings.cafeControlResetDesc.tr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              _showConfirmResetDialog(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Reset Meja',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmResetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          AppStrings.cafeControlResetTitle.tr,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppStrings.cafeControlResetConfirm.tr,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cafeControlResetCancel.tr,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              controller.resetToIdle();
              AppSnackbar.show(
                title: 'Meja Direset',
                message: 'Meja kasir telah dikosongkan dan siap untuk pelanggan berikutnya.',
                variant: SnackbarVariant.success,
              );
            },
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );
  }
}
