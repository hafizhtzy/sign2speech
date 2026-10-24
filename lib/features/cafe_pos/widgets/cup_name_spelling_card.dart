import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
import 'package:speech2sign/features/sign_language/widgets/hold_confirm_ring.dart';

import 'cafe_mini_camera_viewport.dart';

class CupNameSpellingCard extends StatelessWidget {
  final bool isSpelling;
  final String currentName;
  final String buffer;
  final int remainingMs;
  final VoidCallback onStartSpelling;
  final VoidCallback onFinishSpelling;
  final ValueChanged<String> onAddLetter;
  final VoidCallback? onDeleteLetter;
  final VoidCallback? onClearBuffer;
  final VoidCallback? onCancelSpelling;
  final VoidCallback? onSwitchCamera;
  final String? detectedLetter;
  final double letterHoldProgress;
  final String? modelBadge;
  final CameraFeedService? cameraService;

  const CupNameSpellingCard({
    super.key,
    required this.isSpelling,
    required this.currentName,
    required this.buffer,
    required this.remainingMs,
    required this.onStartSpelling,
    required this.onFinishSpelling,
    required this.onAddLetter,
    this.onDeleteLetter,
    this.onClearBuffer,
    this.onCancelSpelling,
    this.onSwitchCamera,
    this.detectedLetter,
    this.letterHoldProgress = 0.0,
    this.modelBadge,
    this.cameraService,
  });

  static const List<String> _fullAlphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static const List<String> _quickNames = [
    'RIAN',
    'DIAN',
    'SARI',
    'BUDI',
    'AYU',
    'FADLI',
  ];

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
                  currentName.isNotEmpty ? 'Eja Ulang' : AppStrings.cafeSpellingCameraTitle.tr,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

    final isShort = MediaQuery.sizeOf(context).height < 500;
    final cameraHeight = isShort ? 220.0 : 260.0;

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
              Icon(Icons.touch_app_outlined,
                  size: 20, color: AppColors.secondary),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.matcha.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.matcha,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.cafeCameraActive.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.matcha,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Enlarged & Optimized Mini-Camera Viewport for fingerspelling
          CafeMiniCameraViewport(
            title: AppStrings.cafeSpellingCameraTitle.tr,
            subtitle: (detectedLetter != null && detectedLetter!.isNotEmpty)
                ? '${AppStrings.cafeDetectedLetter.tr}: "$detectedLetter" • ${AppStrings.cafeHoldGuide.tr}'
                : AppStrings.cafeSpellingCameraHint.tr,
            height: cameraHeight,
            onClose: onCancelSpelling ?? onFinishSpelling,
            onSwitchCamera: onSwitchCamera,
            cameraService: cameraService,
            modelBadge: modelBadge,
            centerOverlay: (detectedLetter != null && detectedLetter!.isNotEmpty)
                ? RepaintBoundary(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HoldConfirmRing(
                          progress: letterHoldProgress,
                          size: 68,
                          child: Text(
                            detectedLetter!,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppStrings.cafeHoldForLetter.trParams({'letter': detectedLetter!}),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 10),

          // Helpful User-Friendly Guidance Banner (No auto-timer countdown)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paleMist,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sign_language_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.cafeSpellingHintUnlimited.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    buffer.isNotEmpty ? buffer : AppStrings.cafeTouchToSpell.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      color:
                          buffer.isNotEmpty ? AppColors.ink : AppColors.muted,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                if (buffer.isNotEmpty && onDeleteLetter != null)
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined, size: 20),
                    color: AppColors.muted,
                    tooltip: AppStrings.cafeDeleteLastLetter.tr,
                    onPressed: onDeleteLetter,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Quick Preset Names
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _quickNames.map((name) {
              return ActionChip(
                label: Text(name),
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                backgroundColor: AppColors.paleMist,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () {
                  for (var i = 0; i < name.length; i++) {
                    onAddLetter(name[i]);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Dynamic A-Z Alphabet Palette (Standard touch target >= 48x48)
          SizedBox(
            height: 130,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _fullAlphabet.map((letter) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => onAddLetter(letter),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        side: BorderSide(color: AppColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: AppColors.paleMist,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            letter,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          Icon(
                            Icons.sign_language_rounded,
                            size: 10,
                            color: AppColors.secondary.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Space / Clear / Finish
          Row(
            children: [
              if (onClearBuffer != null) ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onClearBuffer,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.delete_outline, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onFinishSpelling,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      'Simpan Nama Cup',
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
