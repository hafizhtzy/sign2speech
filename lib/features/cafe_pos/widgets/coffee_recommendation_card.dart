import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';

import '../domain/models/coffee_menu_item.dart';
import '../domain/models/coffee_recommendation_result.dart';

class CoffeeRecommendationCard extends StatelessWidget {
  final CoffeeRecommendationResult? recommendation;
  final VoidCallback onSelect;
  final String selectedTag;
  final ValueChanged<String>? onTagSelected;
  final ValueChanged<CoffeeMenuItem>? onAddDirectly;

  const CoffeeRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onSelect,
    this.selectedTag = 'Semua',
    this.onTagSelected,
    this.onAddDirectly,
  });

  static const List<String> _preferenceTags = [
    'Semua',
    'Aman Lambung',
    'Karamel Dingin',
    'Double Shot Aren',
    'Matcha Sehat',
    'Americano Diet',
  ];

  @override
  Widget build(BuildContext context) {
    if (recommendation == null) return const SizedBox.shrink();

    final rec = recommendation!;
    final isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clean Editorial Header (No icon circle or boxed price pill)
          Text(
            AppStrings.cafeAiSommelierTitle.tr,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            AppStrings.cafeAiSommelierSubtitle.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 12.5,
            ),
          ),

          // Airy Preference Filter Pills
          if (onTagSelected != null) ...[
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _preferenceTags.map((tag) {
                  final isSelected = selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(tag),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 12,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      onSelected: (_) => onTagSelected!(tag),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: AppColors.borderSoft),
          ),

          // Drink Name & Price aligned cleanly on 1 editorial row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  rec.item.nameId,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatRupiah(rec.item.basePrice),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Calm recommendation copy (decorative hashtag pills removed)
          Text(
            rec.reasonId,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.muted,
              height: 1.45,
              fontSize: 13.5,
            ),
          ),

          const SizedBox(height: 22),

          // Full-Width Non-Truncating Stadium Action Buttons
          if (onAddDirectly != null) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => onAddDirectly!(rec.item),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: Text(
                  AppStrings.cafeQuickOrderAction.tr,
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
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onSelect,
              icon: Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.ink,
              ),
              label: Text(
                AppStrings.cafeAiChooseCustomize.tr,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.border, width: 1.2),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
