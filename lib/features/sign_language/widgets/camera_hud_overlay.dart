import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/bisindo_prediction.dart';
import '../services/bisindo_classifier_service.dart';

class CameraHudOverlay extends StatelessWidget {
  final SignLanguageModelType activeModel;
  final VoidCallback onToggleModel;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final bool isCameraActive;
  final String statusMessage;
  final BisindoPrediction? latestPrediction;
  final bool isInferring;

  const CameraHudOverlay({
    super.key,
    required this.activeModel,
    required this.onToggleModel,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.isCameraActive,
    required this.statusMessage,
    this.latestPrediction,
    this.isInferring = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top HUD Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.surface.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Model switcher badge with class count
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleModel,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.surface.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: AppColors.surface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeModel == SignLanguageModelType.bisindo
                              ? 'BISINDO (47)'
                              : 'SIBI (72)',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Status indicator chip
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !isCameraActive
                              ? Colors.grey
                              : (isInferring
                                  ? AppColors.warning
                                  : AppColors.success),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusMessage,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons: Flip & Pause (touch targets >= 48dp)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isCameraActive
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      color: AppColors.surface,
                      size: 22,
                    ),
                    onPressed: onToggleCamera,
                    tooltip: isCameraActive ? 'Jeda Kamera' : 'Lanjutkan Kamera',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.flip_camera_ios_rounded,
                      color: AppColors.surface,
                      size: 20,
                    ),
                    onPressed: onFlipCamera,
                    tooltip: 'Balik Kamera',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Live Prediction Banner (if available)
        if (latestPrediction != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  latestPrediction!.isLetter
                      ? Icons.spellcheck_rounded
                      : Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  latestPrediction!.isLetter
                      ? 'Mengeja: ${latestPrediction!.cleanLabel}'
                      : latestPrediction!.cleanLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.paleMist,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(latestPrediction!.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
