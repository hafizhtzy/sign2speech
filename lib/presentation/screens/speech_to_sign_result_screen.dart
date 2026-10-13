import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
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
        title: const Text('Hasil Speech to Sign'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
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
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFE65100), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kata ini tidak ditemukan di $userLang. Menampilkan hasil dari $lang.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE65100),
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
                  child: const Icon(
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'hajicare-sign.web.app — unduh untuk menonton offline',
                        style: const TextStyle(
                          fontSize: 12,
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
                    style: const TextStyle(
                      fontSize: 12,
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
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Unduh & Putar Video',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
