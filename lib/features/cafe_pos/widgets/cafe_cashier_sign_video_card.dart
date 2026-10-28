import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';
import 'package:speech2sign/features/sign_language/models/sign_video_entry.dart';
import 'package:speech2sign/features/sign_language/widgets/sign_video_player.dart';

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier 1: Ikon, Judul & Subjudul, Tombol Lipat (Chevron)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.sign_language_rounded,
                        size: 22,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.cafeCashierSignVideoTitle.tr,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.cafeCashierSignVideoSubtitle.tr,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
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
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                // Tier 2: Sub-Header Status Badges & Model Switcher
                const SizedBox(height: 10),
                Obx(() {
                  final entry = tts.currentEntry.value;
                  return Row(
                    children: [
                      if (entry != null) ...[
                        _buildSourceBadge(entry),
                        const SizedBox(width: 8),
                      ],
                      _buildModelSwitchBadge(),
                      const Spacer(),
                      // Micro-Indicator: Live Audio Sync
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleMist,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.matcha,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Live Audio Sync',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // ── Video Content & Word Playlist (Visible when expanded) ────────
          if (!_isCollapsed) ...[
            Divider(height: 1, thickness: 1, color: AppColors.border),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Remote Download Action Strip (if entry is remote)
                    if (currentEntry != null &&
                        currentEntry.source == SignVideoSource.remote)
                      _buildRemoteDownloadBar(currentEntry, tts),

                    // Embedded Video Player
                    SignVideoPlayer(
                      playlist: tts.playlist,
                      activeWordIndex: tts.activeWordIndex.value,
                      videoSource: tts.currentVideoSource.value,
                      isLoading: tts.isLoadingVideo.value,
                      isDownloading: tts.isDownloading.value,
                      downloadProgress: tts.downloadProgress.value,
                      playbackSpeed: tts.playbackSpeed.value,
                      isLooping: tts.isLooping.value,
                      onWordSelected: (index) =>
                          tts.selectWordIndex(index),
                      onSpeedChanged: (speed) =>
                          tts.setPlaybackSpeed(speed),
                      onToggleLoop: () => tts.toggleLooping(),
                      errorMessage: tts.errorMessage.value,
                      onDownload: (currentEntry != null &&
                              currentEntry.source == SignVideoSource.remote)
                          ? () => tts.downloadAndPlay(currentEntry)
                          : null,
                    ),

                    const SizedBox(height: 10),

                    // Word Sequence Chips
                    if (playlist.length > 1) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.playlist_play_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.cafeCashierSignWordChips.tr,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: playlist.asMap().entries.map((item) {
                            final idx = item.key;
                            final entry = item.value;
                            final isPlaying =
                                idx == tts.activeWordIndex.value;
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => tts.selectWordIndex(idx),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? AppColors.primary
                                        : AppColors.paleMist,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isPlaying
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isPlaying) ...[
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        entry.label,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                          color: isPlaying
                                              ? Colors.white
                                              : AppColors.ink,
                                          fontWeight: isPlaying
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceBadge(SignVideoEntry entry) {
    final isAsset = entry.source == SignVideoSource.asset;
    final isCached = entry.source == SignVideoSource.localCached;
    final isOffline = isAsset || isCached;

    final color = isOffline ? AppColors.matcha : AppColors.amber;
    final label = isAsset
        ? AppStrings.cafeCashierSignOfflineBadge.tr
        : (isCached
            ? AppStrings.cafeCashierSignCachedBadge.tr
            : AppStrings.cafeCashierSignOnlineBadge.tr);
    final icon = isAsset
        ? Icons.offline_pin_rounded
        : (isCached ? Icons.save_rounded : Icons.cloud_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSwitchBadge() {
    final activeModel = _cashierCtrl.activeSignModel;
    final isSibi = activeModel == SignLanguageModel.sibi;
    return InkWell(
      onTap: () {
        final next = isSibi
            ? SignLanguageModel.bisindo
            : SignLanguageModel.sibi;
        _cashierCtrl.switchSignLanguageModel(next);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.paleMist,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeModel.displayName,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 13, color: AppColors.secondary),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.record_voice_over_outlined,
              size: 22,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.cafeCashierSignStandby.tr,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            AppStrings.cafeCashierSignStandbyDesc.tr,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Demo Test Word Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: _sampleTestWords.map((word) {
              return ActionChip(
                label: Text(
                  'Coba: $word',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                backgroundColor: AppColors.paleMist,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: AppColors.border),
                ),
                onPressed: () {
                  _cashierCtrl.onTranscriptReceived(word, triggerSign: true);
                },
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
