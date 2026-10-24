import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
import 'package:speech2sign/features/sign_language/widgets/hold_confirm_ring.dart';

import 'cafe_mini_camera_viewport.dart';

class WaitingSignChallengeCard extends StatefulWidget {
  final String signWord;
  final double progress;
  final bool isCompleted;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback? onNextWord;
  final VoidCallback? onStartCamera;
  final VoidCallback? onCloseCamera;
  final VoidCallback? onSwitchCamera;
  final bool isCameraActive;
  final String? modelBadge;
  final CameraFeedService? cameraService;

  const WaitingSignChallengeCard({
    super.key,
    required this.signWord,
    required this.progress,
    required this.isCompleted,
    required this.onProgressChanged,
    this.onNextWord,
    this.onStartCamera,
    this.onCloseCamera,
    this.onSwitchCamera,
    this.isCameraActive = false,
    this.modelBadge,
    this.cameraService,
  });

  @override
  State<WaitingSignChallengeCard> createState() =>
      _WaitingSignChallengeCardState();
}

class _WaitingSignChallengeCardState extends State<WaitingSignChallengeCard> {
  bool _localPracticing = false;

  bool get _isCameraShowing => widget.isCameraActive || _localPracticing;

  void _startCamera() {
    setState(() {
      _localPracticing = true;
    });
    if (widget.onStartCamera != null) {
      widget.onStartCamera!();
    }
  }

  void _stopCamera() {
    setState(() {
      _localPracticing = false;
    });
    if (widget.onCloseCamera != null) {
      widget.onCloseCamera!();
    }
  }

  void _showSignGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sign_language_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.cafeSignGuideTitle.trParams({'word': widget.signWord}),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.pan_tool_alt_rounded,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getGuideText(widget.signWord),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppStrings.cafeReadyToPractice.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGuideText(String word) {
    final isEn = Get.locale?.languageCode == 'en';
    switch (word.toUpperCase()) {
      case 'TERIMA KASIH':
      case 'THANK YOU':
        return isEn
            ? 'Touch the fingertips of your right hand to your chin or lips, then move your open palm forward toward the other person.'
            : 'Sentuhkan ujung jari tangan kanan ke bibir atau dagu, lalu gerakkan tangan ke depan ke arah lawan bicara dengan telapak terbuka.';
      case 'KOPI':
      case 'COFFEE':
        return isEn
            ? 'Make fists with both hands, place right hand over left hand and rotate as if grinding coffee beans.'
            : 'Kepalkan kedua tangan, letakkan tangan kanan di atas tangan kiri dan putar seperti sedang menggiling biji kopi.';
      case 'SUSU':
      case 'MILK':
        return isEn
            ? 'Open and close your right hand fingers rhythmically like milking a cow.'
            : 'Buka dan tutup jari-jari tangan kanan seperti gerakan memerah susu sapi secara ritmis.';
      case 'DINGIN':
      case 'COLD':
        return isEn
            ? 'Make fists in front of your chest, then gently shiver your body and hands as if feeling cold.'
            : 'Kepalkan kedua tangan di depan dada, lalu getarkan tubuh dan tangan seolah menggigil kedinginan.';
      case 'PANAS':
      case 'HOT':
        return isEn
            ? 'Form a claw shape in front of your mouth, then draw forward while gently blowing.'
            : 'Bentuk tangan seperti cakar di depan mulut, lalu tarik ke depan dan tiup perlahan.';
      case 'SAMA-SAMA':
      case "YOU'RE WELCOME":
        return isEn
            ? 'Open both palms facing upward in front of your chest, and move slightly forward with a friendly smile.'
            : 'Buka kedua telapak tangan menghadap ke atas di depan dada, lalu gerakkan sedikit ke depan dengan senyuman ramah.';
      default:
        return isEn
            ? 'Face the cafe camera with confidence, center your hand in frame, and perform the sign gesture.'
            : 'Tatap kamera kafe dengan percaya diri, posisikan tangan di tengah frame, dan peragakan gestur isyarat.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCompleted ? AppColors.matcha : AppColors.border,
          width: widget.isCompleted ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isCompleted
                ? AppColors.matcha.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Trophy & Next word button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? AppColors.matcha.withValues(alpha: 0.15)
                      : AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isCompleted
                      ? Icons.military_tech_rounded
                      : Icons.school_outlined,
                  size: 20,
                  color: widget.isCompleted
                      ? AppColors.matcha
                      : AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeWaitingChallengeTitle.tr,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.cafeWaitingChallengeDesc.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onNextWord != null)
                IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  color: AppColors.secondary,
                  tooltip: AppStrings.cafeChangeSignTooltip.tr,
                  onPressed: widget.onNextWord,
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Embedded Mini-Camera / Recognition Viewport
          if (_isCameraShowing) ...[
            Builder(
              builder: (ctx) {
                final isShort = MediaQuery.sizeOf(ctx).height < 500;
                final cameraHeight = isShort ? 220.0 : 260.0;
                return CafeMiniCameraViewport(
                  title: AppStrings.cafeChallengeTitle.trParams({'word': widget.signWord}),
                  subtitle: widget.progress >= 1.0
                      ? AppStrings.cafeChallengeSuccess.tr
                      : '${AppStrings.cafeMatchPercentage.trParams({'percent': '${(widget.progress * 100).toInt()}'})} • ${AppStrings.cafeHoldGuide.tr}',
                  height: cameraHeight,
                  onClose: _stopCamera,
                  onSwitchCamera: widget.onSwitchCamera,
                  cameraService: widget.cameraService,
                  modelBadge: widget.modelBadge,
                  centerOverlay: (widget.progress >= 1.0 || widget.isCompleted)
                      ? RepaintBoundary(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.matcha.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.matcha.withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 14),
          ] else ...[
            // Static Challenge Box with HoldConfirmRing
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  HoldConfirmRing(
                    progress: widget.progress,
                    size: 72,
                    child: Icon(
                      widget.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.sign_language,
                      size: 28,
                      color: widget.isCompleted
                          ? AppColors.matcha
                          : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.cafeTodaySignTitle.tr,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '"${widget.signWord}"',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.matcha.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.matcha),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    AppStrings.cafeChallengeSuccess.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.matcha,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            AppStrings.cafeAimGestureHint.tr,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hint Button: "Lihat Contoh Isyarat" (Touch Target >= 48x48)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showSignGuideSheet(context),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: Text(
                  AppStrings.cafeChallengeHintBtn.tr,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  side: BorderSide(color: AppColors.secondary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Practice or Close Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _isCameraShowing
                ? OutlinedButton.icon(
                    onPressed: _stopCamera,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: Text(
                      AppStrings.cafeChallengeCloseCamera.tr,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _startCamera,
                    icon: Icon(
                      widget.isCompleted ? Icons.replay : Icons.videocam_outlined,
                      size: 20,
                    ),
                    label: Text(
                      widget.isCompleted ? AppStrings.cafeTryAgain.tr : AppStrings.cafeTryCamera.tr,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isCompleted
                          ? AppColors.matcha
                          : AppColors.secondary,
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

