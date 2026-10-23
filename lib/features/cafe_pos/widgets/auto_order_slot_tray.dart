import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
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
                    AppStrings.cafeAutoOrderTitle.tr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeParsedSlotDetected.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.drinkNameId,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${item.totalPrice}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chips of slot modifiers
          Wrap(
            spacing: 8,
            runSpacing: 6,
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
            const SizedBox(height: 12),
            ...item.dietaryAlerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DietaryAlertBadge(tag: alert),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 1-Tap Confirm Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              label: Text(
                AppStrings.cafeConfirmToTicket.tr,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
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
