import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/models/sign_video_entry.dart';
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
        title: Text(
          AppStrings.speechResultTitle.tr,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: 720,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                        Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.speechSpokenText.tr,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Obx(
                                () => Text(
                                  ttsCtrl.recognizedWords.value.isEmpty
                                      ? 'Terima kasih, saya mau beli tiket'
                                      : ttsCtrl.recognizedWords.value,
                                  style: AppTypography.titleMedium.copyWith(
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
                  const SizedBox(height: 12),

                  // Cross-language fallback banner
                  Obx(() {
                    final result = ttsCtrl.searchResult.value;
                    if (result == null || !result.isCrossLanguageFallback) {
                      return const SizedBox.shrink();
                    }
                    final lang = result.crossLanguageSystem?.toUpperCase() ?? 'bahasa lain';
                    final userLang = ttsCtrl.selectedLanguage.value.toUpperCase();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kata ini tidak ditemukan di $userLang. Menampilkan hasil dari $lang.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Remote video download prompt — tampil jika video belum diunduh
                  Obx(() {
                    final entry = ttsCtrl.currentEntry.value;
                    if (entry == null) return const SizedBox.shrink();
                    if (entry.source != SignVideoSource.remote) {
                      return const SizedBox.shrink();
                    }
                    // Video ada di cloud tapi belum diunduh
                    return _RemoteVideoDownloadCard(
                      entry: entry,
                      isDownloading: ttsCtrl.isDownloading.value,
                      downloadProgress: ttsCtrl.downloadProgress.value,
                      onDownload: () => ttsCtrl.downloadAndPlay(entry),
                    );
                  }),

                  const SizedBox(height: 4),

                  // Sequential Video Player Component
                  Obx(
                    () => SignVideoPlayer(
                      playlist: ttsCtrl.playlist,
                      activeWordIndex: ttsCtrl.activeWordIndex.value,
                      videoSource: ttsCtrl.currentVideoSource.value,
                      isLoading: ttsCtrl.isLoadingVideo.value,
                      isDownloading: ttsCtrl.isDownloading.value,
                      downloadProgress: ttsCtrl.downloadProgress.value,
                      playbackSpeed: ttsCtrl.playbackSpeed.value,
                      isLooping: ttsCtrl.isLooping.value,
                      onWordSelected: (index) => ttsCtrl.selectWordIndex(index),
                      onSpeedChanged: (speed) => ttsCtrl.setPlaybackSpeed(speed),
                      onToggleLoop: () => ttsCtrl.toggleLooping(),
                      errorMessage: ttsCtrl.errorMessage.value,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Actions
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: AppStrings.speechSpeakAgain.tr,
                          icon: Icons.mic_rounded,
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          label: AppStrings.save.tr,
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
        ),
    );
  }
}

/// Widget kartu download untuk video yang belum diunduh dari cloud
class _RemoteVideoDownloadCard extends StatelessWidget {
  final SignVideoEntry entry;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;

  const _RemoteVideoDownloadCard({
    required this.entry,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paleMist,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cloud_download_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video "${entry.label}" tersedia di cloud',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'hajicare-sign.web.app — unduh untuk menonton offline',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Download progress or button
          if (isDownloading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: downloadProgress > 0 ? downloadProgress : null,
                      backgroundColor: AppColors.paleMist,
                      color: AppColors.secondary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    downloadProgress > 0
                        ? 'Mengunduh ${(downloadProgress * 100).toInt()}%...'
                        : 'Menyiapkan unduhan...',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDownload,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    'Unduh & Putar Video',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
