import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';

import '../domain/models/parsed_cafe_order_slot.dart';
import 'dietary_alert_badge.dart';

class AutoOrderSlotTray extends StatelessWidget {
  final ParsedCafeOrderSlot? slot;
  final VoidCallback onConfirm;

  const AutoOrderSlotTray({
    super.key,
    required this.slot,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (slot == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 20,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cafeAutoOrderTitle.tr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.cafeAutoOrderSubtitle.tr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final item = slot!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.6), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeParsedSlotDetected.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.drinkNameId,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupiah(item.totalPrice),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Chips of slot modifiers
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSlotChip(
                label: item.temperature.name.toUpperCase(),
                icon: item.temperature.name == 'hot'
                    ? Icons.local_fire_department
                    : Icons.ac_unit,
              ),
              _buildSlotChip(
                label: item.cupSize.name.toUpperCase(),
                icon: Icons.coffee,
              ),
              _buildSlotChip(
                label: item.milkType.name.toUpperCase(),
                icon: Icons.water_drop,
              ),
              _buildSlotChip(
                label: item.sweetnessLevel.name.toUpperCase(),
                icon: Icons.bubble_chart,
              ),
              if (item.extraShot)
                _buildSlotChip(
                  label: AppStrings.cafeModifierExtraShot.tr,
                  icon: Icons.bolt,
                ),
              if (item.quantity > 1)
                _buildSlotChip(
                  label: '${item.quantity}x',
                  icon: Icons.shopping_basket,
                ),
            ],
          ),

          // Dietary Alert Badges (if any)
          if (item.dietaryAlerts.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...item.dietaryAlerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DietaryAlertBadge(tag: alert),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 1-Tap Confirm Button (Stadium Pill matching Speech to Sign)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.add_shopping_cart, size: 19),
              label: Text(
                AppStrings.cafeConfirmToTicket.tr,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
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
    );
  }

  Widget _buildSlotChip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paleMist,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
