import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/widgets/sign_speech_card.dart';

class SpeechToSignMicScreen extends StatelessWidget {
  const SpeechToSignMicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ttsCtrl = Get.find<TextToSignController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Speech to Sign',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.speechSpeakMic.tr,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.speechSpeakMicDesc.tr,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Speech Visualizer Card
              Obx(
                () => SignSpeechCard(
                  isListening: ttsCtrl.isListening.value,
                  recognizedText: ttsCtrl.recognizedWords.value,
                  statusText: ttsCtrl.statusMessage.value,
                  onToggleListen: () => ttsCtrl.toggleVoiceRecognition(),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                AppStrings.speechTrySamples.tr,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTestChip(ttsCtrl, 'Saya mau beli tiket'),
                    const SizedBox(width: 8),
                    _buildTestChip(ttsCtrl, 'Pesan kopi satu'),
                    const SizedBox(width: 8),
                    _buildTestChip(ttsCtrl, 'Kurang gula'),
                    const SizedBox(width: 8),
                    _buildTestChip(ttsCtrl, 'Bayar QRIS'),
                    const SizedBox(width: 8),
                    _buildTestChip(ttsCtrl, 'Bawa pulang'),
                    const SizedBox(width: 8),
                    _buildTestChip(ttsCtrl, 'Terima kasih'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              AppPrimaryButton(
                label: AppStrings.speechViewSignVideo.tr,
                icon: Icons.sign_language_rounded,
                onPressed: () {
                    final query = ttsCtrl.recognizedWords.value.isEmpty
                        ? 'Terima kasih'
                        : ttsCtrl.recognizedWords.value;

                    ttsCtrl.processVoiceInput(query);

                    final history = Get.find<HistoryController>();
                    history.addHistoryEntry(
                      original: query,
                      translated: 'Peragaan Isyarat',
                      direction: TranslationDirection.speechToSign,
                      signLanguage: settings.selectedSignLanguage.value,
                    );

                    Get.toNamed(AppRoutes.speechToSignResult);
                  },
                ),
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTestChip(TextToSignController ctrl, String phrase) {
    return ActionChip(
      label: Text(phrase),
      onPressed: () {
        ctrl.recognizedWords.value = phrase;
        ctrl.processVoiceInput(phrase);
        Get.toNamed(AppRoutes.speechToSignResult);
      },
      backgroundColor: AppColors.surface,
      labelStyle: AppTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
    );
  }
}
