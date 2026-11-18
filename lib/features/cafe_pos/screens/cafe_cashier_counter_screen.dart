import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';
import 'package:speech2sign/core/widgets/responsive_layout.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../widgets/auto_order_slot_tray.dart';
import '../widgets/cafe_order_stage_stepper.dart';
import '../widgets/cafe_order_ticket_card.dart';
import '../widgets/cafe_menu_catalog_sheet.dart';
import '../widgets/cafe_staff_pin_dialog.dart';
import '../widgets/cashier_order_deck_card.dart';
import '../widgets/coffee_recommendation_card.dart';
import '../widgets/cup_name_spelling_card.dart';
import '../widgets/dual_mode_queue_pager.dart';
import '../widgets/order_ready_banner.dart';
import '../widgets/waiting_sign_challenge_card.dart';
import '../widgets/cafe_cashier_sign_video_card.dart';
import '../widgets/customer_voice_order_card.dart';
import '../widgets/cafe_cashier_control_sheet.dart';
import 'cafe_order_queue_screen.dart';


class CafeCashierCounterScreen extends StatefulWidget {
  const CafeCashierCounterScreen({super.key});

  @override
  State<CafeCashierCounterScreen> createState() =>
      _CafeCashierCounterScreenState();
}

class _CafeCashierCounterScreenState extends State<CafeCashierCounterScreen> {
  late final CafeCashierController controller;
  Worker? _orderCompletedWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CafeCashierController>();
    _orderCompletedWorker = ever<bool>(controller.isOrderCompleted, (completed) {
      if (completed && mounted) {
        _showOrderCompletedQueueDialog();
      }
    });
  }

  @override
  void dispose() {
    _orderCompletedWorker?.dispose();
    super.dispose();
  }

  void _showMenuCatalogSheet() {
    CafeMenuCatalogSheet.show(
      context: context,
      catalog: controller.menuCatalog,
      onSelectItem: (CoffeeMenuItem item) {
        controller.addRecommendedItemToTicket(item);
        controller.onTranscriptReceived('pesan ${item.nameId}', triggerSign: true);
      },
    );
  }

  void _showCashierControlSheet() {
    CafeCashierControlSheet.show(
      context: context,
      controller: controller,
    );
  }

  void _showOrderCompletedQueueDialog() {
    final ticket = controller.currentTicket.value;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.matcha.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 42,
                    color: AppColors.matcha,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.cafePaymentSuccessQueued.trParams({'queue': ticket.queueNumber}),
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesanan telah berhasil dibayar (${ticket.paymentMethod == OrderPaymentMethod.qris ? 'QRIS' : 'Tunai'}) dan otomatis masuk ke antrean pembuatan.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.customerName.isEmpty
                                ? 'Pelanggan Walk-In'
                                : 'Nama: ${ticket.customerName}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${ticket.items.length} item • ${ticket.orderId}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatRupiah(ticket.grandTotal),
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.startNextCustomerOrder();
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: Text(
                      AppStrings.cafeStartNextOrder.tr,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      CafeOrderQueueScreen.showAsDialog(
                        context,
                        controller: controller,
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text(
                      AppStrings.cafeViewQueue.trParams(
                        {'count': '${controller.activeOrdersQueue.length}'},
                      ),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.goToStage(CafeOrderStage.pickup);
                    },
                    icon: const Icon(Icons.coffee_rounded, size: 18),
                    label: Text(
                      'Lanjut ke Pengambilan Kopi (Tahap 3)',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      final double bottomHeight = isDual
          ? (isIdle ? 0.0 : 66.0)
          : (isIdle ? 58.0 : 124.0);
      final ticket = controller.currentTicket.value;
      final isCashier = controller.isCashierView.value;
      final isFlipped = controller.isFlipped.value;

      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            color: AppColors.ink,
            tooltip: AppStrings.cafeBackTooltip.tr,
            onPressed: () => Get.back(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      AppStrings.cafeCashierBaristaAiTitle.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                AppStrings.cafeQueueNumberPrefix.trParams({'queue': ticket.queueNumber}),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
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
            // Responsive Adaptive Actions:
            // On Tablet / Large Screens (>= 600dp), show full controls directly in AppBar
            if (isLargeScreen) ...[
              _buildAppBarSignModelToggle(controller),
              _buildStaffPinButton(),
              _buildQueueBadgeButton(),
              _buildResetButton(),
            ],

            // On Mobile/Compact (< 600dp), show Queue Badge for immediate glanceability
            if (!isLargeScreen)
              _buildQueueBadgeButton(),

            // 180° Screen Flip Button (hanya tampil jika opsi 1-tablet)
            if (!isDual)
              IconButton(
                icon: AnimatedRotation(
                  turns: isFlipped ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.screen_rotation_rounded,
                    color: isFlipped ? AppColors.secondary : AppColors.ink,
                  ),
                ),
                tooltip: AppStrings.cafeFlipScreen.tr,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  controller.toggleFlip();
                  AppSnackbar.info(
                    title: AppStrings.cafeFlipScreen.tr,
                    message: controller.isFlipped.value
                        ? AppStrings.cafeFlipActive.tr
                        : AppStrings.cafeFlipInactive.tr,
                    icon: Icons.screen_rotation_rounded,
                    duration: const Duration(milliseconds: 1500),
                  );
                },
              ),

            // More Options Menu Button (Titik Tiga ⋮) - Opens CafeCashierControlSheet
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.ink,
              tooltip: AppStrings.cafeMenuMoreTooltip.tr,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: _showCashierControlSheet,
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
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                          color: AppColors.canvas,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.paleMist,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.borderSoft,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSegmentButton(
                                    label: AppStrings.cafeDualViewCashier.tr,
                                    icon: Icons.point_of_sale_rounded,
                                    isSelected: isCashier,
                                    onTap: () =>
                                        controller.isCashierView.value = true,
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
        child: RotatedBox(
          quarterTurns: isFlipped ? 2 : 0,
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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

          ],
        ),
        ),
      ),
      bottomNavigationBar: _buildStageBottomActionBar(stage),
    );
    });
  }

  // ── DOCKED STAGE ADVANCE BOTTOM ACTION BAR ──────────────────────────────────
  Widget? _buildStageBottomActionBar(CafeOrderStage stage) {
    if (stage == CafeOrderStage.idle) return null;
    if (controller.isFlipped.value) return null;
    if (!controller.isCashierView.value) return null;
    if (controller.isSpellingCustomerName.value) return null;

    final ticket = controller.currentTicket.value;
    final isPaid = ticket.isPaid;
    final (label, icon, color) = switch (stage) {
      CafeOrderStage.ordering => (
          ticket.items.isNotEmpty
              ? AppStrings.cafeStageAdvanceNamingWithCount.trParams({
                  'count': ticket.items.length.toString(),
                })
              : AppStrings.cafeStageAdvanceNaming.tr,
          Icons.arrow_forward_rounded,
          AppColors.secondary,
        ),
      CafeOrderStage.naming => isPaid
          ? (
              AppStrings.cafeStageAdvancePickup.tr,
              Icons.coffee_rounded,
              AppColors.matcha,
            )
          : (
              AppStrings.cafeStageWaitingPayment.tr,
              Icons.payments_outlined,
              AppColors.amber,
            ),
      CafeOrderStage.pickup => (
          AppStrings.cafeStageOrderCompleted.tr,
          Icons.check_rounded,
          AppColors.matcha,
        ),
      CafeOrderStage.idle => ('', Icons.add, AppColors.secondary),
    };

    if (label.isEmpty) return null;

    final Color buttonFg = color == AppColors.primary
        ? AppColors.onPrimary
        : (AppColors.isDark ? AppColors.darkCanvas : AppColors.textOnDark);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          top: BorderSide(color: AppColors.borderSoft, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
      child: SafeArea(
        top: false,
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
          heightFactor: 1.0,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('cafe_stage_advance_button'),
              onPressed: controller.advanceStage,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: buttonFg,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: buttonFg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      controller.goToStage(CafeOrderStage.ordering),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    'Mulai Terima Pesanan',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                ),
              ),
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.onPrimary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.muted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }

  /// Responsive, high-contrast segmented model switch in the AppBar [ BISINDO | SIBI ]
  Widget _buildAppBarSignModelToggle(CafeCashierController controller) {
    final activeModel = controller.activeSignModel;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.paleMist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAppBarModelTab(
            controller: controller,
            targetModel: SignLanguageModel.bisindo,
            label: 'BISINDO',
            isSelected: activeModel == SignLanguageModel.bisindo,
          ),
          const SizedBox(width: 2),
          _buildAppBarModelTab(
            controller: controller,
            targetModel: SignLanguageModel.sibi,
            label: 'SIBI',
            isSelected: activeModel == SignLanguageModel.sibi,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarModelTab({
    required CafeCashierController controller,
    required SignLanguageModel targetModel,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelected
            ? null
            : () {
                controller.switchSignLanguageModel(targetModel);
                AppSnackbar.show(
                  title: 'Model Bahasa Isyarat',
                  message: AppStrings.cafeSignModelChanged
                      .trParams({'model': targetModel.displayName}),
                  variant: SnackbarVariant.info,
                );
              },
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: AppColors.matcha,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.muted,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffPinButton() {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
    );
  }

  Widget _buildQueueBadgeButton() {
    return Obx(() {
      final queueCount = controller.activeOrdersQueue.length;
      return Tooltip(
        message: AppStrings.cafeOrderQueueTitle.tr,
        child: InkWell(
          onTap: () => CafeOrderQueueScreen.showAsDialog(
            context,
            controller: controller,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: queueCount > 0
                  ? AppColors.matcha.withValues(alpha: 0.15)
                  : AppColors.paleMist,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: queueCount > 0
                    ? AppColors.matcha
                    : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: queueCount > 0
                      ? AppColors.matcha
                      : AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$queueCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: queueCount > 0
                        ? AppColors.matcha
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResetButton() {
    return IconButton(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.refresh_rounded, size: 20),
      color: AppColors.muted,
      tooltip: AppStrings.cafeClearTicketTooltip.tr,
      onPressed: () {
        controller.resetToIdle();
      },
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
        onStartNextOrder: controller.startNextCustomerOrder,
        onViewQueue: () => CafeOrderQueueScreen.showAsDialog(
          context,
          controller: controller,
        ),
        isQrisProcessing: controller.isQrisProcessing.value,
        onSubstituteMilk: controller.substituteMilkInTicket,
        onRemoveItem: controller.removeItemFromTicket,
      );
    });
  }

  Widget _buildCustomerMenuCatalogBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cafeCustomerMenuBannerTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppStrings.cafeCustomerMenuBannerSubtitle.tr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showMenuCatalogSheet,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(AppStrings.cafeCustomerMenuBannerButton.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(48, 44),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6 MODULAR STAGE BUILDERS (V2 ARCHITECTURE) ─────────────────────────────

  /// Stage 1: Kasir - Menerima Pesanan & Konfirmasi Slot (Unified 3-Tab Deck: Isyarat, 1-Tap, Mic)
  Widget _buildCashierOrderingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Real-time Speech-to-Sign: Video Bahasa Isyarat Kasir
        CafeCashierSignVideoCard(
          cashierController: controller,
        ),
        const SizedBox(height: 20),
        _buildCustomerReplyAlertBanner(),
        Obx(() => AutoOrderSlotTray(
          slot: controller.activeParsedSlot.value,
          onConfirm: controller.confirmParsedSlotToTicket,
        )),
        const SizedBox(height: 20),
        // Unified 3-Tab Interaction Deck: Bahasa Isyarat (default), 1-Tap, Mic
        CashierOrderDeckCard(
          controller: controller,
          onOpenMenuCatalog: _showMenuCatalogSheet,
        ),
      ],
    );
  }

  /// Stage 1: Pembeli - Pesan Lewat Suara & Editor Teks, Nota Live, Balasan Cepat, & Rekomendasi Menu
  Widget _buildCustomerOrderingStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sisi Pembeli: Mikrofon & Kamera Isyarat (Speech to Sign)
        CustomerVoiceOrderCard(
          controller: controller,
          onOpenMenuCatalog: _showMenuCatalogSheet,
        ),
        const SizedBox(height: 20),
        _buildCustomerMenuCatalogBanner(),
        const SizedBox(height: 20),
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

      final Color statusColor = ticket.status == OrderStatus.completed
          ? AppColors.matcha
          : (ticket.status == OrderStatus.preparing
              ? AppColors.amber
              : AppColors.muted);

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.28 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editorial Eyebrow: Status dot + label & loyalty star
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.status.labelId,
                  style: AppTypography.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (stamps > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        size: 15,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sahabat Tuli ($stamps⭐)',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Antrean ${ticket.queueNumber}',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
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
                Expanded(
                  child: Text(
                    'Total Tagihan:',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
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
      final isPaid = ticket.isPaid && ticket.grandTotal > 0;
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => controller.goToStage(CafeOrderStage.pickup),
                  icon: const Icon(Icons.coffee_rounded, size: 20),
                  label: Text(
                    'Lihat Antrean & Tantangan Isyarat ☕',
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
              // Customer Payment Method Selection
              Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton(
                        label: AppStrings.cafePaymentQris.tr,
                        icon: Icons.qr_code_scanner,
                        isSelected: isQris,
                        onTap: () => controller.setPaymentMethod(OrderPaymentMethod.qris),
                      ),
                    ),
                    Expanded(
                      child: _buildSegmentButton(
                        label: AppStrings.cafePaymentCash.tr,
                        icon: Icons.payments_outlined,
                        isSelected: !isQris,
                        onTap: () => controller.setPaymentMethod(OrderPaymentMethod.cash),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isQris) ...[
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
        ],
      ),
    );
  });
}
}


