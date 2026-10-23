import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/widgets/responsive_layout.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../widgets/auto_order_slot_tray.dart';
import '../widgets/cafe_order_ticket_card.dart';
import '../widgets/cashier_quick_deck.dart';
import '../widgets/cup_name_spelling_card.dart';
import '../widgets/coffee_recommendation_card.dart';
import '../widgets/dual_mode_queue_pager.dart';
import '../widgets/order_ready_banner.dart';
import '../widgets/waiting_sign_challenge_card.dart';

class CafeCashierCounterScreen extends GetView<CafeCashierController> {
  const CafeCashierCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textEditController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primary,
          tooltip: 'Kembali',
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final ticket = controller.currentTicket.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meja Kasir & Barista AI',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Nomor Antrean: ${ticket.queueNumber}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
        actions: [
          // Dual-View Segmented Toggle
          Obx(() {
            final isCashier = controller.isCashierView.value;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewTab(
                    label: AppStrings.cafeDualViewCashier.tr,
                    isSelected: isCashier,
                    onTap: () => controller.isCashierView.value = true,
                  ),
                  _buildViewTab(
                    label: AppStrings.cafeDualViewCustomer.tr,
                    isSelected: !isCashier,
                    onTap: () => controller.isCashierView.value = false,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: ResponsiveContentWrapper(
                maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Transcript Simulation / Live Input Bar
                    _buildTranscriptInputBar(textEditController),

                    const SizedBox(height: 16),

                    // Main Content: Cashier View or Customer View
                    Obx(() {
                      final isCashier = controller.isCashierView.value;
                      return isCashier
                          ? _buildCashierSide()
                          : _buildCustomerSide();
                    }),

                    const SizedBox(height: 24),

                    // Always Visible: Active Order Ticket
                    Obx(() {
                      final ticket = controller.currentTicket.value;
                      return CafeOrderTicketCard(
                        ticket: ticket,
                        onPaymentMethodChanged: controller.setPaymentMethod,
                        onAddCash: controller.addCashNominal,
                        onTranslateBill:
                            controller.translateBillToSignAndSpeech,
                        onClearTicket: controller.clearTicket,
                      );
                    }),
                  ],
                ),
              ),
            ),

            // High-Contrast Visual Call Modal for Deaf Customer
            Obx(() {
              if (!controller.isDeafCallActive.value) {
                return const SizedBox.shrink();
              }
              final ticket = controller.currentTicket.value;
              return Positioned.fill(
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: ResponsiveContentWrapper(
                    maxWidth: 500,
                    child: OrderReadyBanner(
                      queueNumber: ticket.queueNumber,
                      customerName: ticket.customerName,
                      onDismiss: controller.dismissDeafCall,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.surface : AppColors.muted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptInputBar(TextEditingController textEditController) {
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
              Icon(Icons.mic_none_rounded, size: 20, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SIMULATOR TRANSKRIP KAMERA / MIKROFON',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textEditController,
                  decoration: InputDecoration(
                    hintText: 'Ketik transkrip pesanan / kondisi di sini...',
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
                    textEditController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    controller.onTranscriptReceived(textEditController.text);
                    textEditController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Proses'),
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
        // 1-Tap Cashier Quick Deck (Fitur 5)
        Obx(() {
          return CashierQuickDeck(
            activeIndex: controller.activeQuickDeckIndex.value,
            onExecute: controller.executeQuickDeck,
          );
        }),

        const SizedBox(height: 16),

        // Dual-Mode Queue Pager (Fitur 4)
        Obx(() {
          final ticket = controller.currentTicket.value;
          return DualModeQueuePager(
            queueNumber: ticket.queueNumber,
            customerName: ticket.customerName,
            onCallHearing: controller.callHearingCustomer,
            onCallDeaf: controller.callDeafCustomer,
          );
        }),

        const SizedBox(height: 16),

        // Fingerspelling Cup Name Card (Fitur 2)
        Obx(() {
          final isSpelling = controller.isSpellingCustomerName.value;
          final name = controller.currentTicket.value.customerName;
          final buffer = controller.customerCupNameBuffer.value;
          final remaining = controller.spellingRemainingMs.value;

          return CupNameSpellingCard(
            isSpelling: isSpelling,
            currentName: name,
            buffer: buffer,
            remainingMs: remaining,
            onStartSpelling: controller.startCustomerNameSpelling,
            onFinishSpelling: controller.finishCustomerNameSpelling,
            onAddLetter: controller.addSpellingLetter,
          );
        }),
      ],
    );
  }

  // ── SISI PEMBELI ───────────────────────────────────────────────────────────
  Widget _buildCustomerSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Auto-Order Slot Tray (Fitur 1 & 6)
        Obx(() {
          final slot = controller.activeParsedSlot.value;
          return AutoOrderSlotTray(
            slot: slot,
            onConfirm: controller.confirmParsedSlotToTicket,
          );
        }),

        const SizedBox(height: 16),

        // AI Barista Sommelier (Fitur 3)
        Obx(() {
          final rec = controller.activeRecommendation.value;
          return CoffeeRecommendationCard(
            recommendation: rec,
            onSelect: () {
              if (rec != null) {
                Get.toNamed(
                  AppRoutes.coffeeDetail,
                  arguments: rec.item,
                );
              }
            },
          );
        }),

        const SizedBox(height: 16),

        // Waiting Sign Challenge (Fitur 8)
        Obx(() {
          return WaitingSignChallengeCard(
            signWord: controller.activeChallengeSign.value,
            progress: controller.challengeProgress.value,
            isCompleted: controller.isChallengeCompleted.value,
            onProgressChanged: controller.updateChallengeProgress,
          );
        }),
      ],
    );
  }
}
