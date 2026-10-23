import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

class DualModeQueuePager extends StatelessWidget {
  final String queueNumber;
  final String customerName;
  final VoidCallback onCallHearing;
  final VoidCallback onCallDeaf;

  const DualModeQueuePager({
    super.key,
    required this.queueNumber,
    required this.customerName,
    required this.onCallHearing,
    required this.onCallDeaf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_outlined,
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
                      AppStrings.cafeQueuePagerTitle.tr,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Antrean: $queueNumber${customerName.isNotEmpty ? " ($customerName)" : ""}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Button 1: Call Hearing Customer (FIFO TTS)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onCallHearing,
              icon: const Icon(Icons.volume_up, size: 20),
              label: Text(
                AppStrings.cafeCallHearing.tr,
                style: AppTypography.labelMedium.copyWith(
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

          const SizedBox(height: 8),

          // Button 2: Call Deaf Customer (Visual Flash + Haptic + Sign Video)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onCallDeaf,
              icon: Icon(Icons.vibration_outlined, size: 20, color: AppColors.amber),
              label: Text(
                AppStrings.cafeCallDeaf.tr,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.amber, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.amber.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
