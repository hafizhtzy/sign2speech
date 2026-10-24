import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';
import 'package:speech2sign/core/widgets/responsive_layout.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../widgets/auto_order_slot_tray.dart';
import '../widgets/cafe_mini_camera_viewport.dart';
import '../widgets/cafe_order_stage_stepper.dart';
import '../widgets/cafe_order_ticket_card.dart';
import '../widgets/cafe_staff_pin_dialog.dart';
import '../widgets/cashier_quick_deck.dart';
import '../widgets/coffee_recommendation_card.dart';
import '../widgets/cup_name_spelling_card.dart';
import '../widgets/dual_mode_queue_pager.dart';
import '../widgets/order_ready_banner.dart';
import '../widgets/waiting_sign_challenge_card.dart';


class CafeCashierCounterScreen extends StatefulWidget {
  const CafeCashierCounterScreen({super.key});

  @override
  State<CafeCashierCounterScreen> createState() =>
      _CafeCashierCounterScreenState();
}

class _CafeCashierCounterScreenState extends State<CafeCashierCounterScreen> {
  late final TextEditingController _textEditController;
  late final CafeCashierController controller;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    controller = Get.find<CafeCashierController>();
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  void _showMenuCatalogSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      color: AppColors.secondary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Katalog Menu Kafe',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: CoffeeMenuItem.standardCatalog.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = CoffeeMenuItem.standardCatalog[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nameId,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.descriptionId,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRupiah(item.basePrice),
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.addRecommendedItemToTicket(item);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(AppStrings.cafeSelect.tr),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AppTranslations.ensureLoaded();
    final isLargeScreen = context.isLargeScreen;

    return Obx(() {
      final stage = controller.currentStage.value;
      final mode = controller.deviceMode.value;
      final isDual = mode == CounterDeviceMode.dualTabletLocked;
      final isIdle = stage == CafeOrderStage.idle;
      final double bottomHeight = isDual ? (isIdle ? 0.0 : 56.0) : (isIdle ? 56.0 : 112.0);
      final ticket = controller.currentTicket.value;
      final isCashier = controller.isCashierView.value;

      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.primary,
            tooltip: AppStrings.cafeBackTooltip.tr,
            onPressed: () => Get.back(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.cafeCashierBaristaAiTitle.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                AppStrings.cafeQueueNumberPrefix.trParams({'queue': ticket.queueNumber}),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            // Dairy allergy auto-switch icon badge
            if (controller.dairyAllergyAutoSwitched.value)
              Tooltip(
                message: 'Susu diganti ke Oat Milk (alergi terdeteksi)',
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: AppColors.amber,
                  ),
                ),
              ),
            // Compact Sign Language Model Badge
            Builder(builder: (context) {
              final activeModel = controller.activeSignModel;
              final isSibi = activeModel == SignLanguageModel.sibi;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.paleMist,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () {
                    final nextModel = isSibi
                        ? SignLanguageModel.bisindo
                        : SignLanguageModel.sibi;
                    controller.switchSignLanguageModel(nextModel);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sign_language_rounded,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activeModel.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            // Staff PIN lock/unlock button
            IconButton(
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
              icon: Icon(
                controller.staffPinAuthenticated.value
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                size: 18,
              ),
              color: controller.staffPinAuthenticated.value
                  ? AppColors.matcha
                  : AppColors.muted,
              tooltip: controller.staffPinAuthenticated.value
                  ? 'Keluar Staff'
                  : 'Masuk PIN Staff',
              onPressed: () async {
                if (controller.staffPinAuthenticated.value) {
                  controller.logoutStaff();
                } else {
                  await CafeStaffPinDialog.show(
                    context,
                    onVerify: controller.verifyStaffPin,
                    title: 'PIN Staf Kasir',
                    subtitle: 'Masukkan PIN untuk melanjutkan',
                  );
                }
              },
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: AppColors.muted,
              tooltip: AppStrings.cafeClearTicketTooltip.tr,
              onPressed: () {
                controller.resetToIdle();
                _textEditController.clear();
              },
            ),
            const SizedBox(width: 4),
          ],
          bottom: bottomHeight > 0
              ? PreferredSize(
                  preferredSize: Size.fromHeight(bottomHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // V2: 3-Stage Stepper (shown when not idle)
                      if (!isIdle)
                        CafeOrderStageStepper(
                          currentStage: stage,
                        ),
                      // Cashier / Customer tab toggle (only in singleTabletSwitch mode)
                      if (!isDual)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              bottom:
                                  BorderSide(color: AppColors.border, width: 1),
                            ),
                          ),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.paleMist,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSegmentButton(
                                    label: AppStrings.cafeDualViewCashier.tr,
                                    icon: Icons.point_of_sale_rounded,
                                    isSelected: isCashier,
                                    onTap: () => controller.isCashierView.value = true,
                                  ),
                                ),
                                Expanded(
                                  child: _buildSegmentButton(
                                    label: AppStrings.cafeDualViewCustomer.tr,
                                    icon: Icons.person_pin_rounded,
                                    isSelected: !isCashier,
                                    onTap: () =>
                                        controller.isCashierView.value = false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : null,
        ),

      body: SafeArea(
        child: Stack(
          children: [
            // V2: Stage-aware body content
            Obx(() {
              final stage = controller.currentStage.value;
              if (stage == CafeOrderStage.idle) {
                return _buildIdleLandingView();
              }
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: ResponsiveContentWrapper(
                  maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
                  child: isLargeScreen
                      ? _buildTabletLandscapeLayout(stage)
                      : _buildStageAwareMobileLayout(stage),
                ),
              );
            }),

            // V2: Dairy allergy auto-switch banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Obx(() {
                final msg = controller.dairyAllergyBannerMessage.value;
                if (msg.isEmpty) return const SizedBox.shrink();
                return AnimatedSlide(
                  offset: msg.isEmpty ? const Offset(0, -1) : Offset.zero,
                  duration: const Duration(milliseconds: 300),
                  child: Material(
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppColors.amber.withValues(alpha: 0.95),
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              color: AppColors.surface, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller
                                .dairyAllergyBannerMessage.value = '',
                            child: Icon(Icons.close_rounded,
                                color: AppColors.surface, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            // High-Contrast Visual Call Modal for Deaf Customer
            Positioned.fill(
              child: Obx(() {
                final isDeafActive = controller.isDeafCallActive.value;
                return IgnorePointer(
                  ignoring: !isDeafActive,
                  child: AnimatedOpacity(
                    opacity: isDeafActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: isDeafActive
                        ? Container(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: ResponsiveContentWrapper(
                              maxWidth: 500,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: OrderReadyBanner(
                                  queueNumber:
                                      controller.currentTicket.value.queueNumber,
                                  customerName:
                                      controller.currentTicket.value.customerName,
                                  onDismiss: controller.dismissDeafCall,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),

            // Celebratory Trophy Dialog on Challenge Completion
            Positioned.fill(
              child: Obx(() {
                final showTrophy = controller.showTrophyDialog.value;
                return IgnorePointer(
                  ignoring: !showTrophy,
                  child: AnimatedOpacity(
                    opacity: showTrophy ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: showTrophy
                        ? Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: ResponsiveContentWrapper(
                              maxWidth: 400,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.amber.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.military_tech_rounded,
                                          size: 48,
                                          color: AppColors.amber,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        AppStrings.cafeTrophyTitle.tr,
                                        style: AppTypography.titleMedium.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppStrings.cafeTrophyDesc.trParams({'sign': controller.activeChallengeSign.value}),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: controller.dismissTrophyDialog,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: AppColors.surface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(AppStrings.cafeTrophyAction.tr),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),

            // V2: Floating Action — Next Stage button
            Positioned(
              bottom: 16,
              right: 16,
              child: Obx(() {
                final stage = controller.currentStage.value;
                if (stage == CafeOrderStage.idle) return const SizedBox.shrink();
                // Only cashier view has controls to advance stage
                if (!controller.isCashierView.value) return const SizedBox.shrink();
                // When actively spelling customer name, hide FAB so it doesn't overlap keys
                if (controller.isSpellingCustomerName.value) return const SizedBox.shrink();
                final (label, icon) = switch (stage) {
                  CafeOrderStage.ordering => (
                      'Lanjut: Nama & Bayar',
                      Icons.arrow_forward_rounded
                    ),
                  CafeOrderStage.naming => (
                      'Lanjut: Ambil Kopi',
                      Icons.coffee_rounded
                    ),
                  CafeOrderStage.pickup => (
                      'Selesai & Order Baru',
                      Icons.check_rounded
                    ),
                  CafeOrderStage.idle => ('', Icons.add),
                };
                if (label.isEmpty) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  heroTag: 'cafe_stage_advance',
                  onPressed: controller.advanceStage,
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                  icon: Icon(icon, size: 18),
                  label: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
    });
  }

  // ── V2: IDLE LANDING VIEW ──────────────────────────────────────────────────
  Widget _buildIdleLandingView() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: ResponsiveContentWrapper(
          maxWidth: 520,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.coffee_rounded,
                  size: 56,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Meja Kasir & Barista AI',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan kamera bahasa isyarat atau mikrofon untuk menerima pesanan.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      controller.goToStage(CafeOrderStage.ordering),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    'Mulai Terima Pesanan',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.devices_rounded,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${controller.deviceMode.value.labelId} • Counter #${controller.counterId.value}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── V2: STAGE-AWARE MOBILE LAYOUT ─────────────────────────────────────────
  Widget _buildStageAwareMobileLayout(CafeOrderStage stage) {
    return Obx(() {
      final isCashier = controller.isCashierView.value;
      switch (stage) {
        case CafeOrderStage.ordering:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCashier) ...[
                _buildCashierOrderingStage(),
                const SizedBox(height: 16),
                _buildOrderTicketWidget(showPayment: false),
              ] else ...[
                _buildCustomerOrderingStage(),
              ],
            ],
          );

        case CafeOrderStage.naming:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCashier) ...[
                _buildCashierNamingStage(),
                const SizedBox(height: 16),
                _buildOrderTicketWidget(showPayment: true),
              ] else ...[
                _buildCustomerNamingStage(),
              ],
            ],
          );

        case CafeOrderStage.pickup:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCashier) ...[
                _buildCashierPickupStage(),
                const SizedBox(height: 16),
                _buildOrderTicketWidget(showPayment: true),
              ] else ...[
                _buildCustomerPickupStage(),
              ],
            ],
          );

        case CafeOrderStage.idle:
          return const SizedBox.shrink();
      }
    });
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.surface : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.muted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }

  /// Tablet / Landscape 2-column side-by-side POS layout
  Widget _buildTabletLandscapeLayout(CafeOrderStage stage) {
    return Obx(() {
      final isCashier = controller.isCashierView.value;
      switch (stage) {
        case CafeOrderStage.ordering:
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Controls & Decks)
              Expanded(
                flex: 11,
                child: isCashier
                    ? _buildCashierOrderingStage()
                    : _buildCustomerOrderingStage(),
              ),
              const SizedBox(width: 20),
              // Right Column (Order Ticket / Bill)
              Expanded(
                flex: 9,
                child: isCashier
                    ? _buildOrderTicketWidget(showPayment: false)
                    : _buildCustomerBillDisplay(),
              ),
            ],
          );

        case CafeOrderStage.naming:
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 11,
                child: isCashier
                    ? _buildCashierNamingStage()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildCustomerCupNamingDisplay(),
                            const SizedBox(height: 14),
                            _buildCustomerPaymentCard(),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              // Right Column
              Expanded(
                flex: 9,
                child: isCashier
                    ? _buildOrderTicketWidget(showPayment: true)
                    : _buildCustomerBillDisplay(),
              ),
            ],
          );

        case CafeOrderStage.pickup:
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 11,
                child: isCashier
                    ? _buildCashierPickupStage()
                    : _buildCustomerPickupWaitingBanner(),
              ),
              const SizedBox(width: 20),
              // Right Column
              Expanded(
                flex: 9,
                child: isCashier
                    ? _buildOrderTicketWidget(showPayment: true)
                    : _buildWaitingSignChallengeWidget(),
              ),
            ],
          );

        case CafeOrderStage.idle:
          return const SizedBox.shrink();
      }
    });
  }

  Widget _buildOrderTicketWidget({bool showPayment = true}) {
    return Obx(() {
      final ticket = controller.currentTicket.value;
      return CafeOrderTicketCard(
        ticket: ticket,
        showPayment: showPayment,
        onPaymentMethodChanged: controller.setPaymentMethod,
        onAddCash: controller.addCashNominal,
        onTranslateBill: controller.translateBillToSignAndSpeech,
        onClearTicket: controller.clearTicket,
        onProcessQris: controller.processQrisPayment,
        onCompleteCash: controller.completeCashPayment,
        onSetExactCash: controller.setExactCash,
        isQrisProcessing: controller.isQrisProcessing.value,
        onSubstituteMilk: controller.substituteMilkInTicket,
        onRemoveItem: controller.removeItemFromTicket,
      );
    });
  }

  Widget _buildTranscriptInputBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Obx(() {
                final isListening = controller.isListening.value;
                final isLiveCamera = controller.activeCameraFeature.value ==
                    CafeCameraActiveFeature.liveOrder;
                return Icon(
                  isLiveCamera
                      ? Icons.videocam_rounded
                      : (isListening ? Icons.mic : Icons.camera_alt_outlined),
                  size: 20,
                  color: isLiveCamera
                      ? AppColors.matcha
                      : (isListening ? AppColors.amber : AppColors.secondary),
                );
              }),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() {
                  final isListening = controller.isListening.value;
                  final isLiveCamera = controller.activeCameraFeature.value ==
                      CafeCameraActiveFeature.liveOrder;
                  return Text(
                    isLiveCamera
                        ? AppStrings.cafeCameraListeningGestures.tr
                        : (isListening
                            ? AppStrings.cafeListeningVoiceNow.tr
                            : AppStrings.cafeLiveOrderCameraTitle.tr),
                    style: AppTypography.labelSmall.copyWith(
                      color: isLiveCamera
                          ? AppColors.matcha
                          : (isListening
                              ? AppColors.amber
                              : AppColors.secondary),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  );
                }),
              ),
              // Toggle Live Order Camera Button
              Obx(() {
                final isLiveCamera = controller.activeCameraFeature.value ==
                    CafeCameraActiveFeature.liveOrder;
                return IconButton(
                  icon: Icon(
                    isLiveCamera
                        ? Icons.videocam_off_outlined
                        : Icons.videocam_outlined,
                    size: 20,
                  ),
                  color: isLiveCamera ? AppColors.matcha : AppColors.secondary,
                  tooltip: isLiveCamera
                      ? AppStrings.cafeCloseLiveCamera.tr
                      : AppStrings.cafeOpenLiveCamera.tr,
                  onPressed: () {
                    if (isLiveCamera) {
                      controller.closeCamera();
                    } else {
                      controller.openCameraFor(
                        CafeCameraActiveFeature.liveOrder,
                      );
                    }
                  },
                );
              }),
              // Catalog Drawer Button
              IconButton(
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                color: AppColors.secondary,
                tooltip: AppStrings.cafeOpenMenuCatalog.tr,
                onPressed: _showMenuCatalogSheet,
              ),
            ],
          ),

          // Embedded Live Order Mini-Camera Viewport (Fitur 1 & 6)
          Obx(() {
            if (controller.activeCameraFeature.value !=
                CafeCameraActiveFeature.liveOrder) {
              return const SizedBox.shrink();
            }
            final isShort = MediaQuery.sizeOf(context).height < 500;
            final cameraHeight = isShort ? 220.0 : 260.0;
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: CafeMiniCameraViewport(
                title: AppStrings.cafeLiveOrderCameraTitle.tr,
                subtitle: AppStrings.cafeLiveOrderCameraHint.tr,
                height: cameraHeight,
                onClose: controller.closeCamera,
                onSwitchCamera: controller.switchCameraLens,
                cameraService: controller.cameraFeedService,
                modelBadge: controller.activeSignModel.displayName,
                bottomBanner: Obx(() {
                  final text = controller.liveTranscript.value;
                  if (text.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.matcha.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sign_language_rounded,
                          size: 14,
                          color: AppColors.matcha,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.cafeDetectedPrefix.trParams({'text': text}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          }),

          const SizedBox(height: 10),
          Row(
            children: [
              // Live Camera Toggle Quick Button (Touch Target >= 48x48)
              Obx(() {
                final isLiveCamera = controller.activeCameraFeature.value ==
                    CafeCameraActiveFeature.liveOrder;
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLiveCamera) {
                        controller.closeCamera();
                      } else {
                        controller.openCameraFor(
                          CafeCameraActiveFeature.liveOrder,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: isLiveCamera
                          ? AppColors.matcha
                          : AppColors.bgSurface,
                      foregroundColor: isLiveCamera
                          ? AppColors.surface
                          : AppColors.secondary,
                      side: BorderSide(
                        color: isLiveCamera
                            ? AppColors.matcha
                            : AppColors.secondary,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Icon(
                      isLiveCamera
                          ? Icons.videocam_rounded
                          : Icons.videocam_outlined,
                      size: 22,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),

              // Live Microphone STT Button (Touch Target >= 48x48)
              Obx(() {
                final isListening = controller.isListening.value;
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.toggleListening,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: isListening
                          ? AppColors.amber
                          : AppColors.secondary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none_rounded,
                      size: 22,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textEditController,
                  decoration: InputDecoration(
                    hintText: AppStrings.cafeTranscriptInputHint.tr,
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                  ),
                  onSubmitted: (val) {
                    controller.onTranscriptReceived(val);
                    _textEditController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.onTranscriptReceived(_textEditController.text);
                    _textEditController.clear();
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(AppStrings.cafeProcessOrder.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    minimumSize: const Size(80, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sample quick chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildSampleChip(
                'Es Karamel Latte Extra Shot',
                () => controller.onTranscriptReceived(
                  'pesan es karamel latte large less sweet extra shot',
                ),
              ),
              _buildSampleChip(
                'Alergi Kacang & Susu',
                () => controller.onTranscriptReceived(
                  'saya ada alergi kacang dan alergi susu sapi',
                ),
              ),
              _buildSampleChip(
                'Maag Kambuh',
                () => controller.onTranscriptReceived(
                  'saya lagi sakit maag lambung',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleChip(String label, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      label: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
      backgroundColor: AppColors.paleMist,
      side: BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ── 6 MODULAR STAGE BUILDERS (V2 ARCHITECTURE) ─────────────────────────────

  /// Stage 1: Kasir - Menerima Pesanan & Konfirmasi Slot
  Widget _buildCashierOrderingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTranscriptInputBar(),
        const SizedBox(height: 14),
        _buildCustomerReplyAlertBanner(),
        Obx(() => AutoOrderSlotTray(
          slot: controller.activeParsedSlot.value,
          onConfirm: controller.confirmParsedSlotToTicket,
        )),
        const SizedBox(height: 14),
        Obx(() => CashierQuickDeck(
          activeIndex: controller.activeQuickDeckIndex.value,
          onExecute: controller.executeQuickDeck,
        )),
      ],
    );
  }

  /// Stage 1: Pembeli - Melihat Nota Live, Balasan Cepat, & Rekomendasi Menu
  Widget _buildCustomerOrderingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCustomerBillDisplay(),
        _buildCustomerQuickRepliesSection(),
        _buildCoffeeRecommendationWidget(),
      ],
    );
  }

  /// Stage 2: Kasir - Mengeja Nama Cup (Fokus & Bebas Gangguan)
  Widget _buildCashierNamingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCupNameSpellingCardWidget(),
      ],
    );
  }

  /// Stage 2: Pembeli - Tampilan Cup dengan Nama yang Dieja & Total Bayar & QRIS
  Widget _buildCustomerNamingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCustomerCupNamingDisplay(),
        const SizedBox(height: 14),
        _buildCustomerBillDisplay(),
        const SizedBox(height: 14),
        _buildCustomerPaymentCard(),
      ],
    );
  }

  /// Stage 3: Kasir - Dual Mode Queue Pager & Serahkan Pesanan
  Widget _buildCashierPickupStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDualModeQueuePagerWidget(),
        const SizedBox(height: 14),
        _buildCashierOrderReadyActionCard(),
      ],
    );
  }

  /// Stage 3: Pembeli - Banner Menunggu Diracik & Tantangan Isyarat
  Widget _buildCustomerPickupStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCustomerPickupWaitingBanner(),
        const SizedBox(height: 14),
        _buildWaitingSignChallengeWidget(),
      ],
    );
  }

  // ── REUSABLE STAGE COMPONENTS ──────────────────────────────────────────────

  Widget _buildCupNameSpellingCardWidget() {
    return Obx(() => CupNameSpellingCard(
      isSpelling: controller.isSpellingCustomerName.value,
      currentName: controller.currentTicket.value.customerName,
      buffer: controller.customerCupNameBuffer.value,
      remainingMs: controller.spellingRemainingMs.value,
      onStartSpelling: controller.startCustomerNameSpelling,
      onFinishSpelling: controller.finishCustomerNameSpelling,
      onAddLetter: controller.addSpellingLetter,
      onDeleteLetter: controller.deleteSpellingLetter,
      onClearBuffer: controller.clearSpellingBuffer,
      onCancelSpelling: controller.closeCamera,
      onSwitchCamera: controller.switchCameraLens,
      detectedLetter: controller.detectedSpellingLetter.value,
      letterHoldProgress: controller.letterHoldProgress.value,
      cameraService: controller.cameraFeedService,
      modelBadge: controller.activeSignModel.displayName,
    ));
  }

  Widget _buildDualModeQueuePagerWidget() {
    return Obx(() => DualModeQueuePager(
      queueNumber: controller.currentTicket.value.queueNumber,
      customerName: controller.currentTicket.value.customerName,
      onCallHearing: controller.callHearingCustomer,
      onCallDeaf: controller.callDeafCustomer,
    ));
  }

  Widget _buildWaitingSignChallengeWidget() {
    return Obx(() => WaitingSignChallengeCard(
      signWord: controller.activeChallengeSign.value,
      progress: controller.challengeProgress.value,
      isCompleted: controller.isChallengeCompleted.value,
      onProgressChanged: controller.updateChallengeProgress,
      onNextWord: controller.cycleNextChallengeWord,
      onStartCamera: () => controller
          .openCameraFor(CafeCameraActiveFeature.waitingChallenge),
      onCloseCamera: controller.closeCamera,
      onSwitchCamera: controller.switchCameraLens,
      isCameraActive: controller.activeCameraFeature.value ==
          CafeCameraActiveFeature.waitingChallenge,
      cameraService: controller.cameraFeedService,
      modelBadge: controller.activeSignModel.displayName,
    ));
  }

  Widget _buildCoffeeRecommendationWidget() {
    return Obx(() => CoffeeRecommendationCard(
      recommendation: controller.activeRecommendation.value,
      selectedTag: controller.selectedSommelierTag.value,
      onTagSelected: controller.filterSommelierByTag,
      onAddDirectly: controller.addRecommendedItemToTicket,
      onSelect: () {
        final rec = controller.activeRecommendation.value;
        if (rec != null) {
          Get.toNamed(
            AppRoutes.coffeeDetail,
            arguments: rec.item,
          );
        }
      },
    ));
  }

  Widget _buildCustomerQuickRepliesSection() {
    return Obx(() {
      if (controller.activeCustomerQuickReplies.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.question_answer_outlined,
                    size: 20, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pertanyaan dari Barista:',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              controller.activeQuickDeckIndex.value >= 0 &&
                      controller.activeQuickDeckIndex.value <
                          CafeCashierController.quickDeckTextsId.length
                  ? CafeCashierController.quickDeckTextsId[
                      controller.activeQuickDeckIndex.value]
                  : '',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: controller.activeCustomerQuickReplies.map((reply) {
                final isSelected =
                    controller.lastCustomerReply.value == reply;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(reply),
                  labelStyle: AppTypography.labelMedium.copyWith(
                    color:
                        isSelected ? AppColors.surface : AppColors.primary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  selectedColor: AppColors.secondary,
                  backgroundColor: AppColors.paleMist,
                  onSelected: (_) =>
                      controller.onCustomerSelectReply(reply),
                );
              }).toList(),
            ),
            Obx(() {
              final feedback = controller.lastCustomerActionFeedback.value;
              if (feedback.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.matcha, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.matcha, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        feedback,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.matcha,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildCustomerCupNamingDisplay() {
    return Obx(() {
      final name = controller.currentTicket.value.customerName;
      final buffer = controller.customerCupNameBuffer.value;
      final displayName = name.isNotEmpty ? name : (buffer.isNotEmpty ? buffer : '');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.secondary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.coffee_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName.isNotEmpty
                  ? 'Halo, Kak $displayName!'
                  : 'Nama di Gelas Kopi Kamu',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName.isNotEmpty
                  ? 'Nama ini akan ditulis barista di cup kopimu ☕'
                  : 'Barista sedang menulis namamu di gelas kopi...',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.muted,
              ),
            ),
            if (buffer.isNotEmpty && name.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mengeja: $buffer',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCustomerPickupWaitingBanner() {
    return Obx(() {
      final ticket = controller.currentTicket.value;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.amber, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      color: AppColors.amber, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan Sedang Dibuat Barista ☕',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Antrean #${ticket.queueNumber} • ${ticket.customerName.isNotEmpty ? ticket.customerName : "Pelanggan"}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Sambil menunggu pesananmu selesai, yuk coba tantangan bahasa isyarat di bawah untuk mengumpulkan stempel Sahabat Tuli! 🏆',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCashierOrderReadyActionCard() {
    return Obx(() {
      final ticket = controller.currentTicket.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.matcha, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.matcha.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.matcha.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.matcha, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan Siap Diserahkan',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Antrean ${ticket.queueNumber} • ${ticket.customerName.isNotEmpty ? ticket.customerName : "Pelanggan"}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => controller.advanceStage(),
                icon: const Icon(Icons.done_all_rounded, size: 20),
                label: Text(
                  'Pesanan Telah Diambil (Selesai)',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.matcha,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCustomerReplyAlertBanner() {
    return Obx(() {
      final reply = controller.lastCustomerReply.value;
      if (reply.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.matcha.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.matcha, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.matcha,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilihan Pelanggan Terverifikasi:',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.matcha,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '"$reply"',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.muted,
              tooltip: 'Tutup Notifikasi',
              onPressed: controller.dismissCustomerReply,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCustomerBillDisplay() {
    return Obx(() {
      final ticket = controller.currentTicket.value;
      final stamps = controller.loyaltyStampsCount.value;
      final allDietaryAlerts = ticket.items
          .expand((item) => item.dietaryAlerts)
          .map((a) => a.defaultMessageId)
          .toSet()
          .toList();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title & Queue Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Antrean ${ticket.queueNumber}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (stamps > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_rounded,
                            size: 14, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Sahabat Tuli ($stamps⭐)',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.status == OrderStatus.completed
                        ? AppColors.matcha.withValues(alpha: 0.15)
                        : (ticket.status == OrderStatus.preparing
                            ? AppColors.amber.withValues(alpha: 0.15)
                            : AppColors.bgSurface),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.status.labelId,
                    style: AppTypography.labelSmall.copyWith(
                      color: ticket.status == OrderStatus.completed
                          ? AppColors.matcha
                          : (ticket.status == OrderStatus.preparing
                              ? AppColors.amber
                              : AppColors.muted),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (ticket.customerName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_pin_rounded,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Atas Nama: ${ticket.customerName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Item summary
            if (ticket.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada minuman di struk. Pesan melalui suara/isyarat atau minta rekomendasi barista!',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: ticket.items.map((slot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${slot.quantity}x ${slot.drinkNameId}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${slot.cupSize.labelId} • ${slot.milkType.labelId} • ${slot.sweetnessLevel.labelId}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(slot.totalPrice),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            // Dietary & Food Safety Banner
            if (allDietaryAlerts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.matcha, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: AppColors.matcha, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keamanan Terverifikasi: ${allDietaryAlerts.join(", ")} telah dicatat Barista ✓',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.matcha,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Tagihan:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatRupiah(ticket.grandTotal),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCustomerPaymentCard() {
    return Obx(() {
      final ticket = controller.currentTicket.value;
      final isPaid = ticket.status == OrderStatus.completed;
      final isQris = ticket.paymentMethod == OrderPaymentMethod.qris;
      final isProcessing = controller.isQrisProcessing.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPaid ? AppColors.matcha : AppColors.secondary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPaid ? AppColors.matcha : AppColors.secondary)
                  .withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isPaid) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.matcha, size: 36),
              ),
              const SizedBox(height: 10),
              Text(
                'Pembayaran Berhasil! (LUNAS)',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.matcha,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Terima kasih! Barista segera meracik pesanan kopimu ☕',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ] else if (isQris) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'QRIS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pindai QRIS untuk Membayar',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // QR Code Graphic container
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: CustomPaint(
                  painter: QrisMatrixPainter(seed: ticket.orderId),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.coffee_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nominal: ${formatRupiah(ticket.grandTotal)}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Buka aplikasi BCA, GoPay, OVO, ShopeePay, atau m-Banking kamu',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed:
                      isProcessing ? null : controller.processQrisPayment,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_rounded, size: 20),
                  label: Text(
                    isProcessing
                        ? 'Memproses Verifikasi...'
                        : 'Simulasi Bayar QRIS (Pelanggan)',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.matcha,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined,
                      color: AppColors.secondary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Metode Tunai Dipilih',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan serahkan uang tunai sebesar ${formatRupiah(ticket.grandTotal)} ke kasir',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}


