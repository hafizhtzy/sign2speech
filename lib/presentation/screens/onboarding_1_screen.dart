import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';

class Onboarding1Screen extends StatelessWidget {
  const Onboarding1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Step Indicator & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.chooseRole),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Editorial Illustration
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  decoration: BoxDecoration(
                    color: AppColors.paleMist.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    AppAssets.onboardingWoman,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Text Content
              const Text(
                'Komunikasi Lebih Mudah',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Jembatan dua arah cerdas antara bahasa isyarat ke suara lisan, dan suara lisan ke video isyarat berurutan secara langsung.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Feature Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip(
                    'Kamera AI Real-time',
                    Icons.camera_alt_outlined,
                  ),
                  _buildFeatureChip(
                    'Suara Alami Indonesia',
                    Icons.record_voice_over_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bottom CTA
              AppPrimaryButton(
                label: 'Lanjut',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Get.toNamed(AppRoutes.onboarding2),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
