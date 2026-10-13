import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/widgets/sign_video_player.dart';

class SpeechToSignResultScreen extends StatelessWidget {
  const SpeechToSignResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ttsCtrl = Get.find<TextToSignController>();
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Hasil Speech to Sign'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spoken Phrase Card
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Teks Ucapan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Obx(
                            () => Text(
                              ttsCtrl.recognizedWords.value.isEmpty
                                  ? 'Terima kasih, saya mau beli tiket'
                                  : ttsCtrl.recognizedWords.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sequential Video Player Component
              Obx(
                () => SignVideoPlayer(
                  playlist: ttsCtrl.playlist,
                  activeWordIndex: ttsCtrl.activeWordIndex.value,
                  videoSource: ttsCtrl.currentVideoSource.value,
                  isLoading: ttsCtrl.isLoadingVideo.value,
                  playbackSpeed: ttsCtrl.playbackSpeed.value,
                  isLooping: ttsCtrl.isLooping.value,
                  onWordSelected: (index) => ttsCtrl.selectWordIndex(index),
                  onSpeedChanged: (speed) => ttsCtrl.setPlaybackSpeed(speed),
                  onToggleLoop: () => ttsCtrl.toggleLooping(),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Bicara Lagi',
                      icon: Icons.mic_rounded,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Simpan',
                      icon: Icons.bookmark_border_rounded,
                      onPressed: () {
                        history.addHistoryEntry(
                          original: ttsCtrl.recognizedWords.value,
                          translated: 'Peragaan Isyarat',
                          direction: TranslationDirection.speechToSign,
                          signLanguage: settings.selectedSignLanguage.value,
                        );
                        Get.snackbar(
                          'Tersimpan',
                          'Peragaan isyarat berhasil disimpan ke Riwayat',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surface,
                          colorText: AppColors.ink,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
