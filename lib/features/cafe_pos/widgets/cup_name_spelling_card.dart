import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

class CupNameSpellingCard extends StatelessWidget {
  final bool isSpelling;
  final String currentName;
  final String buffer;
  final int remainingMs;
  final VoidCallback onStartSpelling;
  final VoidCallback onFinishSpelling;
  final ValueChanged<String> onAddLetter;

  const CupNameSpellingCard({
    super.key,
    required this.isSpelling,
    required this.currentName,
    required this.buffer,
    required this.remainingMs,
    required this.onStartSpelling,
    required this.onFinishSpelling,
    required this.onAddLetter,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSpelling) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Icons.text_fields_rounded,
                size: 20,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cafeCupNameFor.tr,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    currentName.isNotEmpty ? currentName : '-',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onStartSpelling,
                icon: const Icon(Icons.spellcheck, size: 18),
                label: Text(
                  AppStrings.cafeCupNameActive.tr,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.secondary, width: 1.2),
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

    final double progress = (remainingMs / 1500).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 20, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.cafeCupNameTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(remainingMs / 1000).toStringAsFixed(1)}s',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 1500ms Countdown Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.paleMist,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          // Display Buffer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              buffer.isNotEmpty ? buffer : 'Eja huruf...',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: buffer.isNotEmpty ? AppColors.ink : AppColors.muted,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick alphabet sample buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const {'R', 'I', 'A', 'N', 'D', 'T', 'O', 'S'}
                .map((letter) => SizedBox(
                      width: 44,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => onAddLetter(letter),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: AppColors.paleMist,
                        ),
                        child: Text(
                          letter,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 14),

          // Finish / Space Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onFinishSpelling,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                AppStrings.cafeCupNameFinish.tr,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
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
}
