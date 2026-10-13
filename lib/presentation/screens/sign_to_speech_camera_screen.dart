import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/bisindo_recognition_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/models/bisindo_prediction.dart';
import '../../features/sign_language/widgets/camera_hud_overlay.dart';
import '../../features/sign_language/widgets/hold_confirm_ring.dart';

class SignToSpeechCameraScreen extends StatefulWidget {
  const SignToSpeechCameraScreen({super.key});

  @override
  State<SignToSpeechCameraScreen> createState() =>
      _SignToSpeechCameraScreenState();
}

class _SignToSpeechCameraScreenState extends State<SignToSpeechCameraScreen> {
  final SignLanguageController signCtrl = Get.find<SignLanguageController>();
  final BisindoRecognitionController recCtrl =
      Get.find<BisindoRecognitionController>();

  double _simulatedHold = 0.0;

  void _simulateGesture(String label, {bool isLetter = false}) {
    setState(() {
      _simulatedHold = 1.0;
    });

    recCtrl.handlePrediction(
      BisindoPrediction(
        label: label,
        confidence: 0.94,
        margin: 0.35,
        isLetter: isLetter,
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _simulatedHold = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Overlay over simulated CameraX feed
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera Simulation Viewport
                  Container(
                    color: const Color(0xFF141F24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_outlined,
                            size: 64,
                            color: AppColors.surface.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pratinjau Kamera MediaPipe CameraX',
                            style: TextStyle(
                              color: AppColors.surface.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Posisikan tangan dan tubuh atas di dalam bingkai',
                            style: TextStyle(
                              color: AppColors.surface.withValues(alpha: 0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hold Confirm Ring in Center
                  Center(
                    child: HoldConfirmRing(
                      progress: _simulatedHold,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                        child: const Icon(
                          Icons.pan_tool_rounded,
                          color: AppColors.surface,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // HUD Overlay Controls
                  Obx(
                    () => CameraHudOverlay(
                      activeModel: signCtrl.activeModel.value,
                      isCameraActive: signCtrl.isCameraActive.value,
                      statusMessage: signCtrl.statusMessage.value,
                      onToggleModel: () => signCtrl.toggleModel(),
                      onToggleCamera: () => signCtrl.toggleCameraActive(),
                      onFlipCamera: () => signCtrl.flipCamera(),
                    ),
                  ),

                  // Back Button (Top Left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.surface,
                          size: 20,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Gesture Simulation Bar (for instant testing without hardware)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Uji Coba Gestur:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTestGestureChip(
                      'Halo',
                      () => _simulateGesture('Halo'),
                    ),
                    const SizedBox(width: 6),
                    _buildTestGestureChip(
                      'Terima Kasih',
                      () => _simulateGesture('Terima Kasih'),
                    ),
                    const SizedBox(width: 6),
                    _buildTestGestureChip(
                      'Saya',
                      () => _simulateGesture('Saya'),
                    ),
                    const SizedBox(width: 6),
                    _buildTestGestureChip('Mau', () => _simulateGesture('Mau')),
                    const SizedBox(width: 6),
                    _buildTestGestureChip(
                      'Beli',
                      () => _simulateGesture('Beli'),
                    ),
                    const SizedBox(width: 6),
                    _buildTestGestureChip(
                      'Eja: B',
                      () => _simulateGesture('B', isLetter: true),
                    ),
                    const SizedBox(width: 6),
                    _buildTestGestureChip(
                      'Eja: E',
                      () => _simulateGesture('E', isLetter: true),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Transcript Card
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Teks Terdeteksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Obx(
                          () => IconButton(
                            icon: const Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.secondary,
                            ),
                            onPressed: recCtrl.tokens.isEmpty
                                ? null
                                : () => recCtrl.replayLastOrFullTranscript(),
                            tooltip: 'Suarakan Kalimat',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Transcript Text Display Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Obx(() {
                          final text = recCtrl.fullTranscriptText;
                          if (text.isEmpty) {
                            return const Center(
                              child: Text(
                                'Arahkan gestur ke kamera untuk memulai penerjemahan...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.4,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Controls Row: Spasi, Reset, and Selesai
                    Row(
                      children: [
                        AppSecondaryButton(
                          label: 'Spasi',
                          width: 85,
                          icon: Icons.space_bar,
                          onPressed: () => recCtrl.insertSpace(),
                        ),
                        const SizedBox(width: 8),
                        AppSecondaryButton(
                          label: 'Reset',
                          width: 85,
                          icon: Icons.refresh,
                          onPressed: () => recCtrl.resetTranscript(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Selesai',
                            icon: Icons.check,
                            onPressed: () {
                              if (recCtrl.fullTranscriptText.isNotEmpty) {
                                final history = Get.find<HistoryController>();
                                final settings = Get.find<SettingsController>();
                                history.addHistoryEntry(
                                  original: 'Gestur Kamera',
                                  translated: recCtrl.fullTranscriptText,
                                  direction: TranslationDirection.signToSpeech,
                                  signLanguage:
                                      settings.selectedSignLanguage.value,
                                );
                              }
                              Get.toNamed(AppRoutes.signToSpeechResult);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestGestureChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.paleMist,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
