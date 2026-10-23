import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flashing Indicator Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            AppStrings.cafeOrderReady.tr.toUpperCase(),
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          // Big Queue Number
          Text(
            queueNumber,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w900,
              fontSize: 38,
            ),
          ),

          if (customerName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Atas nama: $customerName',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.paleMist,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 12),

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
                Text(
                  'VIDEO ISYARAT DIPUTAR: "PESANAN SIAP"',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                'Tutup Notifikasi',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
