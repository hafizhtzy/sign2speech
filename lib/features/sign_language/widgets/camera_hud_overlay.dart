import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../services/bisindo_classifier_service.dart';

class CameraHudOverlay extends StatelessWidget {
  final SignLanguageModelType activeModel;
  final VoidCallback onToggleModel;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final bool isCameraActive;
  final String statusMessage;

  const CameraHudOverlay({
    super.key,
    required this.activeModel,
    required this.onToggleModel,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.isCameraActive,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.surface.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Model switcher pill
            GestureDetector(
              onTap: onToggleModel,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      size: 16,
                      color: AppColors.surface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeModel == SignLanguageModelType.bisindo
                          ? 'BISINDO'
                          : 'SIBI',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status message
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  statusMessage,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Controls: Flip & Pause
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isCameraActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: AppColors.surface,
                    size: 22,
                  ),
                  onPressed: onToggleCamera,
                  tooltip: isCameraActive ? 'Jeda Kamera' : 'Lanjutkan Kamera',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
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
    );
  }
}
