import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import '../domain/models/cafe_order_ticket.dart';
import '../domain/models/order_enums.dart';
import 'dietary_alert_badge.dart';

class CafeOrderTicketCard extends StatelessWidget {
  final CafeOrderTicket ticket;
  final ValueChanged<OrderPaymentMethod> onPaymentMethodChanged;
  final ValueChanged<int> onAddCash;
  final VoidCallback onTranslateBill;
  final VoidCallback onClearTicket;

  const CafeOrderTicketCard({
    super.key,
    required this.ticket,
    required this.onPaymentMethodChanged,
    required this.onAddCash,
    required this.onTranslateBill,
    required this.onClearTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
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
              color: AppColors.paleMist,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeTicketTitle.tr,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
                        'Belum ada item pesanan dalam nota.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: ticket.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  ),
                                  Text(
                                    '${item.cupSize.name} • ${item.temperature.name} • ${item.milkType.name}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${item.totalPrice}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Perforated Dashed Divider
          _buildDashedLine(),

          // Financial Breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                _buildPriceRow(AppStrings.cafeSubtotal.tr, 'Rp ${ticket.subtotal}'),
                const SizedBox(height: 6),
                _buildPriceRow(AppStrings.cafeTax.tr, 'Rp ${ticket.taxAmount}'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.cafeGrandTotal.tr,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${ticket.grandTotal}',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment Selector & Change Calculator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                const SizedBox(height: 12),

                // Cash Change or QRIS visual
                if (ticket.paymentMethod == OrderPaymentMethod.cash) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppStrings.cafeAmountReceived.tr}: Rp ${ticket.amountPaid}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${AppStrings.cafeChange.tr}: Rp ${ticket.changeAmount}',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.matcha,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickCashChip('+Rp 20.000', () => onAddCash(20000)),
                      _buildQuickCashChip('+Rp 50.000', () => onAddCash(50000)),
                      _buildQuickCashChip('+Rp 100.000', () => onAddCash(100000)),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scan QRIS aktif. Total nominal terkunci otomatis.',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Translate Bill & Clear Ticket Buttons
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
                        tooltip: 'Reset Nota',
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
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
        ),
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
      height: 44,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.surface : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(String text, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      label: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
