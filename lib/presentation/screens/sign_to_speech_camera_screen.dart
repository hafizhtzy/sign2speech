import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/bisindo_recognition_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/models/sign_language_model.dart';
import '../../features/sign_language/models/sign_token.dart';
import '../../features/sign_language/widgets/gesture_candidate_loader.dart';

/// Camera lens orientation for Sign Language screen.
enum LensFacing { front, back }

/// Realtime Sign Language (SIBI & BISINDO) Recognition Screen.
/// Clean Architecture Presentation View connected with GetX controllers.
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
  final SettingsController settings = Get.find<SettingsController>();

  bool _isTrayExpanded = true;
  int _selectedCategoryTab = 0; // 0: Kata Populer, 1: Eja Alfabet

  // Popular gesture presets for BISINDO
  static const List<String> _bisindoPopularWords = [
    'Halo',
    'Terima Kasih',
    'Apa Kabar',
    'Baik',
    'Kamu',
    'Kami',
    'Air',
    'Minum',
    'Duduk',
    'Berdiri',
    'Siapa',
    'Tuli',
  ];

  // Popular gesture presets for SIBI
  static const List<String> _sibiPopularWords = [
    'Halo',
    'Terima',
    'Bantu',
    'Darurat',
    'Dokter',
    'Rumah',
    'Sakit',
    'Makan',
    'Minum',
    'Shalat',
    'Kamu',
    'Kita',
  ];

  static const List<String> _alphabetLetters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'I',
    'K',
    'L',
    'M',
    'N',
    'S',
    'T',
  ];

  @override
  void initState() {
    super.initState();
    // Connect prediction stream to recognition controller
    signCtrl.onPredictionAccepted = (prediction) {
      recCtrl.handlePrediction(prediction);
    };
    recCtrl.setModelThresholds(
      confidenceThreshold:
          signCtrl.currentModel.value == SignLanguageModel.sibi ? 0.58 : 0.70,
      stablePredictionsRequired:
          signCtrl.currentModel.value == SignLanguageModel.sibi ? 2 : 3,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!signCtrl.isContinuousRunning.value) {
        signCtrl.startContinuous();
      }
    });
  }

  @override
  void dispose() {
    if (signCtrl.isContinuousRunning.value) {
      signCtrl.stopContinuous();
    }
    super.dispose();
  }

  void _onSaveAndFinish() {
    if (recCtrl.fullTranscriptText.isNotEmpty) {
      final history = Get.find<HistoryController>();
      final isEn = settings.selectedAppLanguage.value == 'en';
      final textToSave = isEn
          ? recCtrl.translatedTranscriptText
          : recCtrl.fullTranscriptText;
      history.addHistoryEntry(
        original: isEn
            ? 'Sign Gesture (${recCtrl.fullTranscriptText})'
            : 'Gestur Kamera',
        translated: textToSave,
        direction: TranslationDirection.signToSpeech,
        signLanguage: settings.selectedSignLanguage.value,
      );
    }
    Get.toNamed(AppRoutes.signToSpeechResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.sign_language_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.cameraTitle.tr,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= ResponsiveBreakpoints.compactMaxWidth) {
                // Wide Screen (Tablet / Desktop / Landscape): 2-Column Split
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Camera Viewport + Controls
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildModelSwitcher(),
                              _buildCameraPanel(height: 380),
                              const SizedBox(height: 12),
                              _buildRecognitionStatus(),
                              const SizedBox(height: 12),
                              _buildControls(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Column: Gesture Simulator + AI Unified Result + Action Buttons
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildGestureSimulatorTray(),
                              const SizedBox(height: 12),
                              _buildUnifiedResultCard(),
                              const SizedBox(height: 16),
                              _buildFinishActionButtons(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Smartphone (Compact): 1-Column Stack
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // 1. Model Switcher [ SIBI | BISINDO ]
                  _buildModelSwitcher(),

                  // 2. Camera Viewport & Overlays
                  _buildCameraPanel(),

                  // 3. Collapsible Gesture Simulator Tray
                  _buildGestureSimulatorTray(),
                  const SizedBox(height: 12),

                  // 4. AI Transcription Result Card
                  _buildUnifiedResultCard(),
                  const SizedBox(height: 12),

                  // 5. Recognition Status & Manual Capture Option
                  _buildRecognitionStatus(),
                  const SizedBox(height: 16),

                  // 6. Action Controls: MULAI / BERHENTI, SPASI, HAPUS, RESET
                  _buildControls(),
                  const SizedBox(height: 14),

                  // 7. TTS Speaker & Finish Buttons
                  _buildFinishActionButtons(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFinishActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final raw = recCtrl.fullTranscriptText.trim();
              return AppSecondaryButton(
                label: 'Suarakan',
                icon: Icons.record_voice_over_rounded,
                onPressed: raw.isEmpty ? null : () => recCtrl.speakTranscript(),
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppPrimaryButton(
              label: 'Selesai',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _onSaveAndFinish,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern 2-Tab Segmented Model Switcher [ SIBI | BISINDO ]
  Widget _buildModelSwitcher() {
    return Obx(() {
      final current = signCtrl.currentModel.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildModelOptionTab(
                model: SignLanguageModel.sibi,
                label: 'SIBI (72)',
                icon: Icons.sort_by_alpha_rounded,
                isSelected: current == SignLanguageModel.sibi,
                onTap: () {
                  signCtrl.switchModel(SignLanguageModel.sibi);
                  recCtrl.setModelThresholds(
                    confidenceThreshold: 0.58,
                    stablePredictionsRequired: 2,
                  );
                  recCtrl.resetRecognitionState();
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildModelOptionTab(
                model: SignLanguageModel.bisindo,
                label: 'BISINDO (47)',
                icon: Icons.handshake_rounded,
                isSelected: current == SignLanguageModel.bisindo,
                onTap: () {
                  signCtrl.switchModel(SignLanguageModel.bisindo);
                  recCtrl.setModelThresholds(
                    confidenceThreshold: 0.70,
                    stablePredictionsRequired: 3,
                  );
                  recCtrl.resetRecognitionState();
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModelOptionTab({
    required SignLanguageModel model,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelected ? null : onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.muted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Camera Panel with Standby State, Active Viewport & Live Overlays
  Widget _buildCameraPanel({double height = 310}) {
    return RepaintBoundary(
      child: Obx(() {
        final isCameraActive = signCtrl.isCameraActive.value;
      final currentModel = signCtrl.currentModel.value;
      final liveState = signCtrl.state.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cameraDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Camera Standby or Active Feed
                if (!isCameraActive)
                  ColoredBox(
                    color: AppColors.cameraDark,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.5),
                              border: Border.all(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.videocam_outlined,
                              color: Colors.white70,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppStrings.cameraInactiveTitle.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              AppStrings.cameraInactiveDesc.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildActiveCameraFeed(),

                // 2. Top-Left Status Badges [ LIVE | SIBI / BISINDO ]
                Positioned(
                  left: 14,
                  top: 13,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CameraBadge(
                        text: isCameraActive ? 'LIVE' : 'STANDBY',
                        isLive: isCameraActive,
                        color: isCameraActive
                            ? AppColors.success.withValues(alpha: 0.9)
                            : Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      _CameraBadge(
                        text: currentModel.displayName,
                        isLive: false,
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),

                // 3. Top-Right Switch Camera Button
                Positioned(
                  right: 14,
                  top: 11,
                  child: _SwitchCameraButton(
                    isFrontCamera: signCtrl.isFrontCamera.value,
                    isCameraActive: isCameraActive,
                    onTap: () => signCtrl.flipCamera(),
                  ),
                ),

                // 4. Overlays depending on live state
                if (isCameraActive) ...[
                  if (liveState == BisindoLiveState.signing)
                    Positioned(
                      left: 14,
                      bottom: 16,
                      child: _LivePill(
                        text: 'Membaca gerakan...',
                        borderColor: AppColors.warning,
                        leading: _PulsingDot(color: AppColors.warning),
                      ),
                    ),
                  if (liveState == BisindoLiveState.classifying)
                    Positioned(
                      left: 14,
                      bottom: 16,
                      child: _LivePill(
                        text: 'Memproses...',
                        borderColor: AppColors.secondary,
                        leading: SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (liveState == BisindoLiveState.listening)
                    Positioned(
                      left: 14,
                      bottom: 16,
                      child: _LivePill(
                        text: 'Siap — lakukan isyarat',
                        borderColor: AppColors.success,
                        leading: Icon(
                          Icons.videocam_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (liveState == BisindoLiveState.manualCountdown)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.9),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${signCtrl.countdownSeconds.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (liveState == BisindoLiveState.manualCapturing)
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Perekaman Gerakan...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${signCtrl.framesCollected.value} frame',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: signCtrl.captureProgress.value,
                                minHeight: 4,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // 5. Streaming Gesture Suggestion Badge with 12 O'Clock Capsule Loader
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Obx(() {
                    final streaming = signCtrl.streamingCandidate.value;
                    final detected = signCtrl.detectedLabel.value;
                    final isConfirmed = signCtrl.isCandidateConfirmed.value;
                    final progress = signCtrl.suggestionProgress.value;
                    final activeLabel = isConfirmed
                        ? (detected.isNotEmpty ? detected : streaming)
                        : streaming;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: activeLabel.isNotEmpty
                          ? RepaintBoundary(
                              child: GestureCandidateLoader(
                                key: const ValueKey('gesture_candidate_loader'),
                                label: activeLabel,
                                progress: progress,
                                isConfirmed: isConfirmed,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

  /// Active Camera Viewport: Real CameraPreview, Permission Prompt, or Simulator Fallback
  Widget _buildActiveCameraFeed() {
    return Obx(() {
      final camService = signCtrl.cameraFeedService;

      // 1. Loading camera sensor & requesting permissions
      if (camService.isLoading.value) {
        return Container(
          color: AppColors.cameraDark,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mengaktifkan Kamera...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Menyiapkan sensor dan izin kamera',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 2. Permission Denied Viewport
      if (!camService.isPermissionGranted.value) {
        return Container(
          color: AppColors.cameraDark,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.no_photography_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Izin Kamera Diperlukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    camService.isPermissionPermanentlyDenied.value
                        ? 'Akses kamera ditolak permanen di perangkat. Buka pengaturan aplikasi untuk mengizinkan kamera.'
                        : 'Aplikasi membutuhkan izin kamera untuk mendeteksi gerakan isyarat secara langsung.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (camService.isPermissionPermanentlyDenied.value) {
                        camService.openSettings();
                      } else {
                        signCtrl.retryStartCamera();
                      }
                    },
                    icon: Icon(
                      camService.isPermissionPermanentlyDenied.value
                          ? Icons.settings_rounded
                          : Icons.lock_open_rounded,
                      size: 16,
                    ),
                    label: Text(
                      camService.isPermissionPermanentlyDenied.value
                          ? 'Buka Pengaturan'
                          : 'Beri Izin Kamera',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 3. Real Native Hardware Camera Feed Ready
      if (camService.isCameraReady) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          return const AndroidView(
            viewType: 'com.speech2sign.bisindo/camera_preview',
            creationParamsCodec: StandardMessageCodec(),
          );
        } else {
          return Container(color: AppColors.cameraDark);
        }
      }

      // 4. Hardware Fallback / Simulator Viewport
      return Container(
        color: AppColors.cameraDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_rounded,
                size: 54,
                color: AppColors.secondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              Text(
                camService.hasCameraHardware.value
                    ? 'Kamera Aktif — Siap Deteksi'
                    : 'Mode Simulator (Sensor Tidak Terdeteksi)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                camService.hasCameraHardware.value
                    ? 'Arahkan gestur ke kamera atau gunakan simulator di bawah'
                    : 'Sensor fisik kamera tidak tersedia. Gunakan simulator di bawah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Collapsible gesture simulation tray for instant manual/emulator testing
  Widget _buildGestureSimulatorTray() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tray Header with Expand/Collapse toggle
          InkWell(
            onTap: () {
              setState(() {
                _isTrayExpanded = !_isTrayExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uji Coba Gestur:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Obx(() {
                      final modelName = signCtrl.currentModel.value.displayName;
                      final count = signCtrl.currentModel.value.classCount;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleMist,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'TFLite $modelName ($count)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isTrayExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Chips Selector
          if (_isTrayExpanded) ...[
            Divider(height: 1, color: AppColors.borderSoft),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab selector: Kata Populer vs Eja Alfabet
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimulatorCategoryTab(
                          index: 0,
                          title: 'Kata Populer',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSimulatorCategoryTab(
                          index: 1,
                          title: 'Eja Alfabet',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chips List
                  Obx(() {
                    final isBisindo =
                        signCtrl.currentModel.value == SignLanguageModel.bisindo;
                    final list = _selectedCategoryTab == 0
                        ? (isBisindo ? _bisindoPopularWords : _sibiPopularWords)
                        : _alphabetLetters;

                    return SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final word = list[index];
                          return ActionChip(
                            label: Text(
                              word,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            backgroundColor: AppColors.paleMist,
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            onPressed: () => signCtrl.simulateGesture(word),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimulatorCategoryTab({
    required int index,
    required String title,
  }) {
    final isSelected = _selectedCategoryTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategoryTab = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }

  /// AI Transcription Card ("TRANSKRIPSI AI")
  Widget _buildUnifiedResultCard() {
    return Obx(() {
      final items = recCtrl.tokens;
      final raw = recCtrl.fullTranscriptText;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.cameraDetectedText.tr,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (recCtrl.spellingBuffer.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paleMist,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${AppStrings.cameraSpelling.tr}: ${recCtrl.spellingBuffer.value}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (raw.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppStrings.cameraAimGuide.tr,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              )
            else ...[
              if (items.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: items.map(_buildGestureBox).toList()),
                ),
              const SizedBox(height: 10),
              Divider(color: AppColors.borderSoft, height: 1),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final isEnglish =
                            settings.selectedAppLanguage.value == 'en';
                        final englishText = recCtrl.translatedTranscriptText;
                        if (isEnglish && englishText.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                englishText,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Isyarat: $raw',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          raw,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: recCtrl.speakTranscript,
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    label: Text(
                      AppStrings.listen.tr,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildGestureBox(SignToken token) {
    if (token.type == SignTokenType.space) {
      return Container(
        margin: const EdgeInsets.only(right: 6),
        width: 32,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.paleMist,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Center(
          child: Icon(
            Icons.space_bar_rounded,
            size: 16,
            color: AppColors.muted,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: 38),
      decoration: BoxDecoration(
        color: AppColors.paleMist,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          token.value,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Compact live status for continuous detection + manual fallback option.
  Widget _buildRecognitionStatus() {
    return Obx(() {
      final liveState = signCtrl.state.value;
      final conf = signCtrl.confidenceScore.value;
      final progress = signCtrl.captureProgress.value;
      final statusText = signCtrl.stateStatusText;

      final isRecognized = liveState == BisindoLiveState.recognized;
      final isRejected =
          liveState == BisindoLiveState.rejected || liveState == BisindoLiveState.error;
      final isSigning = liveState == BisindoLiveState.signing;
      final isClassifying = liveState == BisindoLiveState.classifying;
      final isRecordingVisual = isSigning || liveState == BisindoLiveState.manualCapturing;

      final canManual = signCtrl.isCameraActive.value &&
          (liveState == BisindoLiveState.listening ||
              liveState == BisindoLiveState.recognized ||
              liveState == BisindoLiveState.rejected);

      final Color accentColor = isRecognized
          ? AppColors.success
          : isRejected
              ? AppColors.error
              : isRecordingVisual
                  ? AppColors.warning
                  : AppColors.secondary;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecognized || isRejected || isRecordingVisual
                ? accentColor.withValues(alpha: 0.5)
                : AppColors.border,
            width: isRecognized || isRejected || isRecordingVisual ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isRecognized
                      ? Icons.check_circle_rounded
                      : isRejected
                          ? Icons.info_outline_rounded
                          : isRecordingVisual
                              ? Icons.fiber_manual_record_rounded
                              : Icons.sensors_rounded,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isRecognized
                          ? AppColors.success
                          : AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isRecognized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(conf * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSigning ||
                isClassifying ||
                liveState == BisindoLiveState.manualCountdown ||
                liveState == BisindoLiveState.manualCapturing) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: isClassifying ? null : progress,
                  minHeight: 5,
                  backgroundColor: AppColors.paleMist,
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    signCtrl.isCameraActive.value
                        ? 'Deteksi gestur otomatis aktif'
                        : 'Tekan MULAI untuk deteksi otomatis',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                // Manual fallback trigger
                TextButton.icon(
                  onPressed: canManual
                      ? () => signCtrl.startCaptureSession()
                      : null,
                  icon: const Icon(Icons.radio_button_checked_rounded, size: 14),
                  label: const Text(
                    'Rekam Manual',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Action Buttons (STOP / MULAI, SPASI, HAPUS, RESET)
  Widget _buildControls() {
    return Obx(() {
      final isRunning = signCtrl.isContinuousRunning.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. MULAI / BERHENTI
            Expanded(
              child: _RoundControl(
                label: isRunning ? 'Berhenti' : 'Mulai',
                icon: isRunning ? Icons.stop_rounded : Icons.videocam_rounded,
                bgColor: isRunning
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.15),
                borderColor: isRunning ? AppColors.error : AppColors.success,
                iconColor: isRunning ? AppColors.error : AppColors.success,
                onTap: () => signCtrl.toggleCameraActive(),
              ),
            ),
            const SizedBox(width: 8),

            // 2. SPASI
            Expanded(
              child: _RoundControl(
                label: 'Spasi',
                icon: Icons.space_bar_rounded,
                bgColor: AppColors.paleMist,
                borderColor: AppColors.border,
                iconColor: AppColors.primary,
                onTap: () => recCtrl.insertSpace(),
              ),
            ),
            const SizedBox(width: 8),

            // 3. HAPUS
            Expanded(
              child: _RoundControl(
                label: 'Hapus',
                icon: Icons.backspace_rounded,
                bgColor: AppColors.warning.withValues(alpha: 0.12),
                borderColor: AppColors.warning.withValues(alpha: 0.6),
                iconColor: AppColors.warning,
                onTap: () => recCtrl.deleteLast(),
              ),
            ),
            const SizedBox(width: 8),

            // 4. RESET
            Expanded(
              child: _RoundControl(
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                bgColor: AppColors.paleMist,
                borderColor: AppColors.border,
                iconColor: AppColors.muted,
                onTap: () => recCtrl.resetTranscript(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Circular Action Control button with touch target >= 48dp (52dp circle + label)
class _RoundControl extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _RoundControl({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap == null ? bgColor.withValues(alpha: 0.4) : bgColor,
              border: Border.all(
                color: onTap == null
                    ? borderColor.withValues(alpha: 0.3)
                    : borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: onTap == null ? iconColor.withValues(alpha: 0.4) : iconColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _CameraBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isLive;

  const _CameraBadge({
    required this.text,
    required this.color,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCameraButton extends StatelessWidget {
  final bool isFrontCamera;
  final bool isCameraActive;
  final VoidCallback onTap;

  const _SwitchCameraButton({
    required this.isFrontCamera,
    required this.isCameraActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortLabel = isFrontCamera ? 'Depan' : 'Belakang';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCameraActive ? AppColors.secondary : Colors.white30,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cameraswitch_rounded,
                  size: 15,
                  color: isCameraActive ? AppColors.secondary : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  shortLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Widget leading;

  const _LivePill({
    required this.text,
    required this.borderColor,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
