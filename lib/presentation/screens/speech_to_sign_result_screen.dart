import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/models/sign_video_entry.dart';
import '../../features/sign_language/services/sign_language_config.dart';
import '../../features/sign_language/widgets/immersive_sign_video_card.dart';

/// Editorial immersive Speech-to-Sign result screen featuring a tall rounded
/// full-bleed portrait video card, bottom gradient caption scrim, circular
/// playback action dock, and quick speed selector in the top bar.
class SpeechToSignResultScreen extends StatefulWidget {
  const SpeechToSignResultScreen({super.key});

  @override
  State<SpeechToSignResultScreen> createState() =>
      _SpeechToSignResultScreenState();
}

class _SpeechToSignResultScreenState extends State<SpeechToSignResultScreen> {
  static const List<double> _speedOptions = [0.75, 1.0, 1.25];
  bool _isSaved = false;

  void _cycleSpeed(TextToSignController ttsCtrl) {
    HapticFeedback.selectionClick();
    final current = ttsCtrl.playbackSpeed.value;
    final nextIndex =
        (_speedOptions.indexWhere((s) => (s - current).abs() < 0.05) + 1) %
        _speedOptions.length;
    ttsCtrl.setPlaybackSpeed(_speedOptions[nextIndex]);
  }

  void _handleSave(
    TextToSignController ttsCtrl,
    SettingsController settings,
    HistoryController history,
  ) {
    history.addHistoryEntry(
      original: ttsCtrl.recognizedWords.value,
      translated: 'Peragaan Isyarat',
      direction: TranslationDirection.speechToSign,
      signLanguage: settings.selectedSignLanguage.value,
    );
    setState(() => _isSaved = true);
    AppSnackbar.success(
      title: AppStrings.signResultSaved.tr,
      message: AppStrings.signResultSavedDesc.tr,
      icon: Icons.bookmark_added_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ttsCtrl = Get.find<TextToSignController>();
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppStrings.speechResultTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          Obx(() {
            final speed = ttsCtrl.playbackSpeed.value;
            final label = speed == 1.0
                ? '1.0x'
                : '${speed.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}x';
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: InkWell(
                  onTap: () => _cycleSpeed(ttsCtrl),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.1),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 15,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double topPadding = 24;
              const double bottomPadding = 28;
              final double minHeight =
                  (constraints.maxHeight - topPadding - bottomPadding).clamp(
                    0.0,
                    double.infinity,
                  );

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  topPadding,
                  20,
                  bottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .stretch,
                    children: [
                      // Cross-language fallback banner (when applicable)
                      Obx(() {
                        final result = ttsCtrl.searchResult.value;
                        if (result == null || !result.isCrossLanguageFallback) {
                          return const SizedBox.shrink();
                        }
                        final lang =
                            result.crossLanguageSystem?.toUpperCase() ??
                            'bahasa lain';
                        final userLang =
                            ttsCtrl.selectedLanguage.value.toUpperCase();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
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

                      // Remote video download prompt (when remote & not yet cached)
                      Obx(() {
                        final entry = ttsCtrl.currentEntry.value;
                        if (entry == null ||
                            entry.source != SignVideoSource.remote) {
                          return const SizedBox.shrink();
                        }
                        return _RemoteVideoDownloadCard(
                          entry: entry,
                          isDownloading: ttsCtrl.isDownloading.value,
                          downloadProgress: ttsCtrl.downloadProgress.value,
                          onDownload: () => ttsCtrl.downloadAndPlay(entry),
                        );
                      }),

                      // Editorial Immersive Full-Bleed Portrait Card + Circular Dock
                      Obx(
                        () => ImmersiveSignVideoCard(
                          playlist: ttsCtrl.playlist,
                          activeWordIndex: ttsCtrl.activeWordIndex.value,
                          videoSource: ttsCtrl.currentVideoSource.value,
                          spokenPhrase: ttsCtrl.recognizedWords.value.isEmpty
                              ? 'Halo'
                              : ttsCtrl.recognizedWords.value,
                          signLanguageLabel:
                              settings.selectedSignLanguage.value,
                          isLoading: ttsCtrl.isLoadingVideo.value,
                          isDownloading: ttsCtrl.isDownloading.value,
                          downloadProgress: ttsCtrl.downloadProgress.value,
                          playbackSpeed: ttsCtrl.playbackSpeed.value,
                          isLooping: ttsCtrl.isLooping.value,
                          isSaved: _isSaved,
                          errorMessage: ttsCtrl.errorMessage.value,
                          onWordSelected: (index) =>
                              ttsCtrl.selectWordIndex(index),
                          onVideoCompleted: () => ttsCtrl.onVideoFinished(),
                          onToggleLoop: () => ttsCtrl.toggleLooping(),
                          onSave: () =>
                              _handleSave(ttsCtrl, settings, history),
                          onSpeakAgain: () => Get.back(),
                          onDownload: () {
                            final entry = ttsCtrl.currentEntry.value;
                            if (entry != null &&
                                entry.source == SignVideoSource.remote) {
                              ttsCtrl.downloadAndPlay(entry);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Download prompt card shown when a sign video exists on cloud but isn't cached locally.
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
    final buttonFg = AppColors.isDark
        ? AppColors.darkCanvas
        : AppColors.textOnDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_download_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
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
                      '${SignLanguageConfig.hostDomain} — unduh untuk menonton offline',
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
          const SizedBox(height: 14),
          if (isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: downloadProgress > 0 ? downloadProgress : null,
                backgroundColor: AppColors.bgSurface,
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
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDownload,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: buttonFg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                ),
                icon: Icon(Icons.download_rounded, size: 18, color: buttonFg),
                label: Text(
                  'Unduh & Putar Video',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: buttonFg,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
