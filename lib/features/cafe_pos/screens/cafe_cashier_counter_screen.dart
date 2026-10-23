import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';
import 'package:speech2sign/core/widgets/responsive_layout.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../widgets/auto_order_slot_tray.dart';
import '../widgets/cafe_mini_camera_viewport.dart';
import '../widgets/cafe_order_ticket_card.dart';
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
        title: Obx(() {
          final ticket = controller.currentTicket.value;
          return Column(
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
                ),
              ),
              Text(
                AppStrings.cafeQueueNumberPrefix.trParams({'queue': ticket.queueNumber}),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.muted,
            tooltip: AppStrings.cafeClearTicketTooltip.tr,
            onPressed: () {
              controller.clearTicket();
              _textEditController.clear();
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Obx(() {
              final isCashier = controller.isCashierView.value;
              return Container(
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
                        onTap: () => controller.isCashierView.value = false,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: ResponsiveContentWrapper(
                maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
                child: isLargeScreen
                    ? _buildTabletLandscapeLayout()
                    : _buildMobilePortraitLayout(),
              ),
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
    );
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

  /// Mobile portrait 1-column layout
  Widget _buildMobilePortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Voice STT & Live Order Input Bar
        _buildTranscriptInputBar(),

        const SizedBox(height: 16),

        // Main Content: Cashier View or Customer View
        Obx(() {
          final isCashier = controller.isCashierView.value;
          return isCashier ? _buildCashierSide() : _buildCustomerSide();
        }),

        const SizedBox(height: 24),

        // Active Order Ticket
        _buildOrderTicketWidget(),
      ],
    );
  }

  /// Tablet / Landscape 2-column side-by-side POS layout
  Widget _buildTabletLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Controls & Decks)
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTranscriptInputBar(),
              const SizedBox(height: 16),
              Obx(() {
                final isCashier = controller.isCashierView.value;
                return isCashier ? _buildCashierSide() : _buildCustomerSide();
              }),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right Column (Sticky Active Order Ticket)
        Expanded(
          flex: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOrderTicketWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTicketWidget() {
    return Obx(() {
      final ticket = controller.currentTicket.value;
      return CafeOrderTicketCard(
        ticket: ticket,
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

  // ── SISI KASIR ─────────────────────────────────────────────────────────────
  Widget _buildCashierSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Customer Feedback Notification Banner
        _buildCustomerReplyAlertBanner(),

        // 1-Tap Cashier Quick Deck (Fitur 5)
        CashierQuickDeck(
          activeIndex: controller.activeQuickDeckIndex.value,
          onExecute: controller.executeQuickDeck,
        ),

        const SizedBox(height: 16),

        // Dual-Mode Queue Pager (Fitur 4)
        DualModeQueuePager(
          queueNumber: controller.currentTicket.value.queueNumber,
          customerName: controller.currentTicket.value.customerName,
          onCallHearing: controller.callHearingCustomer,
          onCallDeaf: controller.callDeafCustomer,
        ),

        const SizedBox(height: 16),

        // Fingerspelling Cup Name Card (Fitur 2)
        CupNameSpellingCard(
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
        ),
      ],
    );
  }

  // ── SISI PEMBELI ───────────────────────────────────────────────────────────
  Widget _buildCustomerSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dedicated Customer-Facing Live Bill & Status Card
        _buildCustomerBillDisplay(),

        // Interactive 2-Way Quick Deck Response Card (Fitur 5)
        if (controller.activeCustomerQuickReplies.isNotEmpty) ...[
          Container(
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
          ),
          const SizedBox(height: 16),
        ],

        // Auto-Order Slot Tray (Fitur 1 & 6)
        AutoOrderSlotTray(
          slot: controller.activeParsedSlot.value,
          onConfirm: controller.confirmParsedSlotToTicket,
        ),

        const SizedBox(height: 16),

        // AI Barista Sommelier (Fitur 3)
        CoffeeRecommendationCard(
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
        ),

        const SizedBox(height: 16),

        // Waiting Sign Challenge (Fitur 8)
        WaitingSignChallengeCard(
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
        ),
      ],
    );
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
}


