import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/sign_video_entry.dart';
import 'package:speech2sign/features/sign_language/widgets/immersive_sign_video_card.dart';

import '../controllers/cafe_cashier_controller.dart';

/// Real-time Sign Language Video Card for the cashier side ("sisi kasir").
/// Positioned directly above the Live Camera & Order Sound Card.
///
/// Features:
/// 1. Real-time video playback of sign language (BISINDO / SIBI) matching customer voice.
/// 2. Supports Tier 1 offline APK assets, Tier 2 local cache, and Tier 3 online CDN.
/// 3. In-card 1-tap download for online CDN videos with live progress indicator.
/// 4. Interactive playlist word chips to navigate and replay individual sign words.
/// 5. Graceful standby state with quick test chips when no video is currently loaded.
class CafeCashierSignVideoCard extends StatefulWidget {
  final CafeCashierController? cashierController;
  final TextToSignController? textToSignController;

  const CafeCashierSignVideoCard({
    super.key,
    this.cashierController,
    this.textToSignController,
  });

  @override
  State<CafeCashierSignVideoCard> createState() =>
      _CafeCashierSignVideoCardState();
}

class _CafeCashierSignVideoCardState extends State<CafeCashierSignVideoCard> {
  bool _isCollapsed = false;

  CafeCashierController get _cashierCtrl =>
      widget.cashierController ??
      (Get.isRegistered<CafeCashierController>()
          ? Get.find<CafeCashierController>()
          : throw StateError('CafeCashierController not found'));

  TextToSignController? get _ttsCtrl {
    if (widget.textToSignController != null) {
      return widget.textToSignController;
    }
    if (Get.isRegistered<TextToSignController>()) {
      return Get.find<TextToSignController>();
    }
    return _cashierCtrl.textToSignController;
  }

  static const List<String> _sampleTestWords = [
    'Kopi',
    'Minum',
    'Susu',
    'Terima Kasih',
  ];

  @override
  Widget build(BuildContext context) {
    final tts = _ttsCtrl;
    if (tts == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.28 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Clean Editorial Header (Zero Clutter Pills or Icon Boxes) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 12, 18),
            child: Row(
              crossAxisAlignment: .center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        AppStrings.cafeCashierSignVideoTitle.tr,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.cafeCashierSignVideoSubtitle.tr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 22,
                    color: AppColors.muted,
                  ),
                  tooltip: _isCollapsed ? 'Perluas' : 'Ciutkan',
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // ── Video Content & Word Playlist (Visible when expanded) ────────
          if (!_isCollapsed) ...[
            Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
            Obx(() {
              final playlist = tts.playlist;
              final currentSource = tts.currentVideoSource.value;
              final currentEntry = tts.currentEntry.value;
              final isSearching = tts.isSearching.value;

              if (isSearching) {
                return _buildLoadingState();
              }

              if (playlist.isEmpty || currentSource.isEmpty) {
                return _buildStandbyState();
              }

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Remote Download Action Strip (if entry is remote)
                    if (currentEntry != null &&
                        currentEntry.source == SignVideoSource.remote)
                      _buildRemoteDownloadBar(currentEntry, tts),

                    // Immersive Full-Bleed Portrait Player (Hasil Speech-to-Sign Style)
                    ImmersiveSignVideoCard(
                      playlist: tts.playlist,
                      activeWordIndex: tts.activeWordIndex.value,
                      videoSource: tts.currentVideoSource.value,
                      spokenPhrase: _cashierCtrl.liveTranscript.value.isNotEmpty
                          ? _cashierCtrl.liveTranscript.value
                          : tts.recognizedWords.value,
                      signLanguageLabel: tts.selectedLanguage.value,
                      cardHeight: 330,
                      isLoading: tts.isLoadingVideo.value,
                      isDownloading: tts.isDownloading.value,
                      downloadProgress: tts.downloadProgress.value,
                      playbackSpeed: tts.playbackSpeed.value,
                      isLooping: tts.isLooping.value,
                      onWordSelected: (index) => tts.selectWordIndex(index),
                      onVideoCompleted: () => tts.onVideoFinished(),
                      onToggleLoop: () => tts.toggleLooping(),
                      errorMessage: tts.errorMessage.value,
                      onDownload: (currentEntry != null &&
                              currentEntry.source == SignVideoSource.remote)
                          ? () => tts.downloadAndPlay(currentEntry)
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRemoteDownloadBar(
      SignVideoEntry entry, TextToSignController tts) {
    final isDownloading = tts.isDownloading.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: isDownloading
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        firstChild: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: tts.downloadProgress.value.clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, progressVal, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressVal > 0 ? progressVal : null,
                    minHeight: 6,
                    backgroundColor: AppColors.amber.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(AppColors.amber),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(tts.downloadProgress.value * 100).toInt()}%',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        secondChild: Row(
          children: [
            Icon(Icons.cloud_download_outlined,
                size: 16, color: AppColors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Video online CDN dapat diunduh untuk penggunaan offline.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ink,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => tts.downloadAndPlay(entry),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      AppStrings.cafeCashierSignDownload.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
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

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mencari video isyarat...',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandbyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sign_language_rounded,
              size: 24,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.cafeCashierSignStandby.tr,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.cafeCashierSignStandbyDesc.tr,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          // Clean sample chips matching Speech to Sign style
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _sampleTestWords.map((word) {
              return ActionChip(
                label: Text(
                  'Coba: $word',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.border),
                ),
                onPressed: () {
                  _cashierCtrl.onTranscriptReceived(word, triggerSign: true);
                },
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
