import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import 'package:speech2sign/core/localization/app_translations.dart';

class OrderReadyBanner extends StatelessWidget {
  final String queueNumber;
  final String customerName;
  final VoidCallback onDismiss;

  const OrderReadyBanner({
    super.key,
    required this.queueNumber,
    required this.customerName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    AppTranslations.ensureLoaded();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flashing Indicator Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              AppStrings.cafeOrderReady.tr.toUpperCase(),
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Big Queue Number
            Text(
              queueNumber,
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w900,
                fontSize: 34,
              ),
            ),

            if (customerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.cafeForCustomerName.trParams({'name': customerName}),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.paleMist,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Sign Video Callout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sign_language, size: 18, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.cafeSignVideoReady.tr,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppStrings.cafeCloseNotification.tr,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
