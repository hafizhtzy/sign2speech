import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';

import '../domain/models/cafe_order_ticket.dart';
import '../domain/models/dietary_alert_tag.dart';
import '../domain/models/order_enums.dart';
import 'dietary_alert_badge.dart';

class CafeOrderTicketCard extends StatelessWidget {
  final CafeOrderTicket ticket;
  final ValueChanged<OrderPaymentMethod> onPaymentMethodChanged;
  final ValueChanged<int> onAddCash;
  final VoidCallback onTranslateBill;
  final VoidCallback onClearTicket;
  final VoidCallback? onProcessQris;
  final VoidCallback? onCompleteCash;
  final VoidCallback? onSetExactCash;
  final bool isQrisProcessing;
  final void Function(int itemIndex, OrderMilkType newMilk)? onSubstituteMilk;
  final void Function(int itemIndex)? onRemoveItem;

  const CafeOrderTicketCard({
    super.key,
    required this.ticket,
    required this.onPaymentMethodChanged,
    required this.onAddCash,
    required this.onTranslateBill,
    required this.onClearTicket,
    this.onProcessQris,
    this.onCompleteCash,
    this.onSetExactCash,
    this.isQrisProcessing = false,
    this.onSubstituteMilk,
    this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    AppTranslations.ensureLoaded();
    final isPaid = ticket.status == OrderStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid ? AppColors.matcha : AppColors.border,
          width: isPaid ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPaid
                ? AppColors.matcha.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ticket Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.matcha.withValues(alpha: 0.12)
                  : AppColors.paleMist,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isPaid ? AppStrings.cafeOfficialReceipt.tr : AppStrings.cafeTicketTitle.tr,
                          style: AppTypography.titleMedium.copyWith(
                            color: isPaid ? AppColors.matcha : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPaid) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.matcha,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LUNAS',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${ticket.orderId} • ${ticket.queueNumber}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (ticket.customerName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.secondary, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_pin_circle_outlined,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.customerName,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Customer Notes Banner (from Quick Deck interaction)
          if (ticket.customerNotes.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.cafeCustomerNotesPrefix.trParams({'notes': ticket.customerNotes}),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Dietary Alerts on Ticket (if any)
          if (ticket.allDietaryAlerts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: ticket.allDietaryAlerts
                    .map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: DietaryAlertBadge(tag: alert, isCompact: true),
                        ))
                    .toList(),
              ),
            ),

          // Items List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: ticket.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        AppStrings.cafeEmptyTicket.tr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(ticket.items.length, (idx) {
                      final item = ticket.items[idx];
                      final hasLactoseConflict = item.dietaryAlerts.any((a) =>
                          a.type == DietaryAlertType.lactoseIntolerant ||
                          a.type == DietaryAlertType.dairyAllergy);

                      final itemContent = Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${item.quantity}x',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.drinkNameId,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.cupSize.labelId.toUpperCase()} • ${item.temperature.labelId} • ${item.milkType.labelId}',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.muted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatRupiah(item.totalPrice),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (onRemoveItem != null) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    iconSize: 18,
                                    color: AppColors.muted,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    splashRadius: 18,
                                    tooltip: AppStrings.cafeDeleteItem.tr,
                                    onPressed: () async {
                                      final confirmed =
                                          await _showDeleteConfirmation(
                                        context,
                                        item.drinkNameId,
                                      );
                                      if (confirmed == true) {
                                        onRemoveItem!(idx);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                            if (hasLactoseConflict && onSubstituteMilk != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 24),
                                child: InkWell(
                                  onTap: () => onSubstituteMilk!(
                                      idx, OrderMilkType.oatMilk),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.matcha
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.matcha, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.autorenew_rounded,
                                            size: 14, color: AppColors.matcha),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppStrings.cafeSubstituteOatMilk.tr,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.matcha,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );

                      if (onRemoveItem == null) return itemContent;

                      return Dismissible(
                        key: ValueKey(
                          'ticket_item_${idx}_${item.drinkId}_${item.totalPrice}',
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmation(
                            context,
                            item.drinkNameId,
                          );
                        },
                        onDismissed: (_) {
                          onRemoveItem!(idx);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                AppStrings.cafeDeleteItem.tr,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        child: itemContent,
                      );
                    }),
                  ),
          ),

          // Perforated Dashed Divider
          _buildDashedLine(),

          // Financial Breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                _buildPriceRow(
                    AppStrings.cafeSubtotal.tr, formatRupiah(ticket.subtotal)),
                const SizedBox(height: 6),
                _buildPriceRow(AppStrings.cafeTax.tr, formatRupiah(ticket.taxAmount)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.cafeGrandTotal.tr,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatRupiah(ticket.grandTotal),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment Selector & QRIS / Cash Module
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isPaid) ...[
                  // Payment Method Tabs
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentTab(
                          label: AppStrings.cafePaymentQris.tr,
                          icon: Icons.qr_code_scanner,
                          isSelected:
                              ticket.paymentMethod == OrderPaymentMethod.qris,
                          onTap: () =>
                              onPaymentMethodChanged(OrderPaymentMethod.qris),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPaymentTab(
                          label: AppStrings.cafePaymentCash.tr,
                          icon: Icons.payments_outlined,
                          isSelected:
                              ticket.paymentMethod == OrderPaymentMethod.cash,
                          onTap: () =>
                              onPaymentMethodChanged(OrderPaymentMethod.cash),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Dynamic QRIS or Cash Section
                  if (ticket.paymentMethod == OrderPaymentMethod.cash) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppStrings.cafeAmountReceived.tr}: ${formatRupiah(ticket.amountPaid)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${AppStrings.cafeChange.tr}: ${formatRupiah(ticket.changeAmount)}',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.matcha,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (onSetExactCash != null)
                          ActionChip(
                            label: Text(AppStrings.cafeExactCash.tr),
                            labelStyle: AppTypography.labelSmall.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: AppColors.secondary,
                            onPressed: onSetExactCash,
                          ),
                        _buildQuickCashChip('+Rp 10.000', () => onAddCash(10000)),
                        _buildQuickCashChip('+Rp 20.000', () => onAddCash(20000)),
                        _buildQuickCashChip('+Rp 50.000', () => onAddCash(50000)),
                        _buildQuickCashChip('+Rp 100.000', () => onAddCash(100000)),
                      ],
                    ),
                    if (onCompleteCash != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: ticket.amountPaid >= ticket.grandTotal
                              ? onCompleteCash
                              : null,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: Text(AppStrings.cafeCompleteCashPayment.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.matcha,
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Dynamic QRIS Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'QRIS',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppStrings.cafeQrisNationalStandard.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Crisp Simulated QR Matrix Box
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: CustomPaint(
                              painter: _QrisMatrixPainter(seed: ticket.orderId),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(4),
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
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Scan QRIS aktif • Nominal: ${formatRupiah(ticket.grandTotal)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (onProcessQris != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: isQrisProcessing
                                    ? null
                                    : onProcessQris,
                                icon: isQrisProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.verified, size: 18),
                                label: Text(isQrisProcessing
                                    ? AppStrings.cafeQrisVerifying.tr
                                    : AppStrings.cafeQrisSimulatePay.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.matcha,
                                  foregroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Already Paid Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.matcha.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.matcha, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.cafePaymentSuccessServing.tr,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.matcha,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Translate Bill & Reset Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: onTranslateBill,
                          icon: const Icon(Icons.record_voice_over, size: 18),
                          label: Text(
                            AppStrings.cafeTranslateBill.tr,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: IconButton(
                        onPressed: onClearTicket,
                        icon: const Icon(Icons.refresh),
                        color: AppColors.muted,
                        tooltip: AppStrings.cafeResetTicketTooltip.tr,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.borderDashed),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.surface : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? AppColors.surface : AppColors.muted,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      labelStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onTap,
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String itemName) {
    AppTranslations.ensureLoaded();
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.cafeDeleteOrderTitle.tr,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.cafeDeleteOrderConfirm.trParams({'name': itemName}),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                AppStrings.cancel.tr,
                style: AppTypography.labelLarge.copyWith(color: AppColors.muted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                AppStrings.cafeDeleteItem.tr,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter to render deterministic crisp QRIS pattern with 3 positioning corners
class _QrisMatrixPainter extends CustomPainter {
  final String seed;

  _QrisMatrixPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    const gridSize = 17;
    final cellSize = size.width / gridSize;

    // Corner Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    void drawFinder(double x, double y) {
      // Outer 7x7 square
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, 7 * cellSize, 7 * cellSize),
        paint,
      );
      // Inner 5x5 white
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 1) * cellSize,
          (y + 1) * cellSize,
          5 * cellSize,
          5 * cellSize,
        ),
        Paint()..color = Colors.white,
      );
      // Center 3x3 square
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 2) * cellSize,
          (y + 2) * cellSize,
          3 * cellSize,
          3 * cellSize,
        ),
        paint,
      );
    }

    drawFinder(1, 1);
    drawFinder(9, 1);
    drawFinder(1, 9);

    // Deterministic pseudo-random pattern based on seed hashCode
    var h = seed.hashCode.abs();
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip corner finders
        if ((r < 8 && c < 8) || (r < 8 && c >= 9) || (r >= 9 && c < 8)) {
          continue;
        }
        h = (h * 31 + r * 17 + c * 7) & 0x7FFFFFFF;
        if (h % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrisMatrixPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
