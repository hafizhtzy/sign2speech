import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import '../domain/models/coffee_recommendation_result.dart';

class CoffeeRecommendationCard extends StatelessWidget {
  final CoffeeRecommendationResult? recommendation;
  final VoidCallback onSelect;

  const CoffeeRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendation == null) return const SizedBox.shrink();

    final rec = recommendation!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
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
                  color: AppColors.matcha.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 20,
                  color: AppColors.matcha,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeAiSommelierTitle.tr,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.cafeAiSommelierSubtitle.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paleMist,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rp ${rec.item.basePrice}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Drink Name
          Text(
            rec.item.nameId,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // Reason text
          Text(
            rec.reasonId,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Matched tokens
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: rec.matchedTokens
                .map((token) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paleMist,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Text(
                        '#$token',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 14),

          // Select button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                AppStrings.cafeAiChooseCustomize.tr,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.secondary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
