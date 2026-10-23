import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/features/sign_language/widgets/hold_confirm_ring.dart';

class WaitingSignChallengeCard extends StatefulWidget {
  final String signWord;
  final double progress;
  final bool isCompleted;
  final ValueChanged<double> onProgressChanged;

  const WaitingSignChallengeCard({
    super.key,
    required this.signWord,
    required this.progress,
    required this.isCompleted,
    required this.onProgressChanged,
  });

  @override
  State<WaitingSignChallengeCard> createState() =>
      _WaitingSignChallengeCardState();
}

class _WaitingSignChallengeCardState extends State<WaitingSignChallengeCard> {
  bool _isPracticing = false;

  void _simulateCameraRecognition() {
    setState(() {
      _isPracticing = true;
    });

    // Simulate recognition hold from 0 to 1.0 over 1.2 seconds
    double p = 0.0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted || !_isPracticing) return false;
      p += 0.25;
      widget.onProgressChanged(p);
      return p < 1.0;
    }).then((_) {
      if (mounted) {
        setState(() {
          _isPracticing = false;
        });
      }
    });
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
          // Header
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
            ],
          ),

          const SizedBox(height: 14),

          // Central Challenge Box with HoldConfirmRing
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
                        'ISYARAT HARI INI:',
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
                          child: Text(
                            AppStrings.cafeChallengeSuccess.tr,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.matcha,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          _isPracticing
                              ? AppStrings.cafeHoldGuide.tr
                              : 'Arahkan gestur tangan ke kamera kafe',
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

          const SizedBox(height: 14),

          // Practice Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isPracticing ? null : _simulateCameraRecognition,
              icon: Icon(
                widget.isCompleted ? Icons.replay : Icons.videocam_outlined,
                size: 20,
              ),
              label: Text(
                widget.isCompleted ? 'Coba Lagi' : AppStrings.cafeTryCamera.tr,
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
