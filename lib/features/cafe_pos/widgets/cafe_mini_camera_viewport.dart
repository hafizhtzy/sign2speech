import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';

/// Reusable responsive mini-camera viewport frame for Cafe POS features.
/// Integrates native Android CameraX via [CameraFeedService] with simulator fallback,
/// front/back lens switching, and gesture targeting HUD.
class CafeMiniCameraViewport extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double height;
  final VoidCallback? onClose;
  final VoidCallback? onSwitchCamera;
  final Widget? centerOverlay;
  final Widget? bottomBanner;
  final bool showHandSilhouette;
  final String? modelBadge;
  final CameraFeedService? cameraService;

  const CafeMiniCameraViewport({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 260,
    this.onClose,
    this.onSwitchCamera,
    this.centerOverlay,
    this.bottomBanner,
    this.showHandSilhouette = false,
    this.modelBadge,
    this.cameraService,
  });

  @override
  Widget build(BuildContext context) {
    CameraFeedService? cam = cameraService;
    if (cam == null && Get.isRegistered<CameraFeedService>()) {
      try {
        cam = Get.find<CameraFeedService>();
      } catch (_) {}
    }

    return RepaintBoundary(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cameraDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.cameraDark.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Camera Feed Viewport (Native CameraX or Fallback)
            Positioned.fill(child: _buildCameraFeed(cam)),

            // 2. Custom HUD / Hold Indicator (Isolated with RepaintBoundary)
            if (centerOverlay != null)
              Center(child: RepaintBoundary(child: centerOverlay!)),

            // 4. Top Control Bar (Title, Switch Camera, Close)
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (modelBadge != null && modelBadge!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      modelBadge!,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Switch Camera Button (Touch Target >= 48x48)
                  if (onSwitchCamera != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSwitchCamera,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.cameraswitch_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Close Camera Button (Touch Target >= 48x48)
                  if (onClose != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 5. Bottom Status HUD Banner
            if (bottomBanner != null)
              Positioned(bottom: 10, left: 14, right: 14, child: bottomBanner!)
            else if (subtitle != null)
              Positioned(
                bottom: 10,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFeed(CameraFeedService? cam) {
    if (cam == null) {
      return _buildFallbackSimulator();
    }

    return Obx(() {
      if (cam.isLoading.value) {
        return Container(
          color: AppColors.cameraDark,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.secondary,
              ),
            ),
          ),
        );
      }

      if (cam.isCameraReady) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          return const AndroidView(
            key: ValueKey('cafe_camera_preview_android_view'),
            viewType: 'com.speech2sign.bisindo/camera_preview',
            creationParamsCodec: StandardMessageCodec(),
          );
        }
      }

      return _buildFallbackSimulator();
    });
  }

  Widget _buildFallbackSimulator() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.cameraDark,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 32,
              color: AppColors.secondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.cafeCameraActive.tr,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
