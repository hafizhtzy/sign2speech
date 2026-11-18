import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_cache_service.dart';

/// Editorial full-bleed portrait video player card inspired by minimalist
/// media showcase layouts. Eliminates harsh letterbox bars, redundant badges,
/// and empty dead space while providing tactile circular playback controls.
class ImmersiveSignVideoCard extends StatefulWidget {
  final List<SignVideoEntry> playlist;
  final int activeWordIndex;
  final String videoSource;
  final String spokenPhrase;
  final String signLanguageLabel;
  final bool isLoading;
  final bool isDownloading;
  final double downloadProgress;
  final double playbackSpeed;
  final bool isLooping;
  final bool isSaved;
  final String? errorMessage;
  final double? cardHeight;
  final ValueChanged<int>? onWordSelected;
  final VoidCallback? onVideoCompleted;
  final VoidCallback? onToggleLoop;
  final VoidCallback? onSave;
  final VoidCallback? onSpeakAgain;
  final VoidCallback? onDownload;

  const ImmersiveSignVideoCard({
    super.key,
    required this.playlist,
    required this.activeWordIndex,
    required this.videoSource,
    required this.spokenPhrase,
    required this.signLanguageLabel,
    this.isLoading = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.playbackSpeed = 1.0,
    this.isLooping = true,
    this.isSaved = false,
    this.errorMessage,
    this.cardHeight,
    this.onWordSelected,
    this.onVideoCompleted,
    this.onToggleLoop,
    this.onSave,
    this.onSpeakAgain,
    this.onDownload,
  });

  @override
  State<ImmersiveSignVideoCard> createState() => _ImmersiveSignVideoCardState();
}

class _ImmersiveSignVideoCardState extends State<ImmersiveSignVideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasNotifiedCompletion = false;
  String? _playerError;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _initToken = 0;

  /// Only enable native ExoPlayer/AVPlayer single-clip looping when there is
  /// at most 1 video in the playlist. For multi-word playlists (e.g. "Pesan" ->
  /// "Kopi"), each clip must complete naturally so we can auto-advance to the
  /// next word (and loop the whole sentence once the final word ends).
  bool get _shouldLoopSingleClip =>
      widget.isLooping && widget.playlist.length <= 1;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ImmersiveSignVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _initializePlayer();
      return;
    }
    final c = _controller;
    if (c == null || !_isInitialized) return;

    // Handle consecutive identical clips in a playlist (e.g. "Kopi Kopi")
    if (oldWidget.activeWordIndex != widget.activeWordIndex) {
      _restartCurrentController();
      return;
    }

    if (oldWidget.playbackSpeed != widget.playbackSpeed) {
      c.setPlaybackSpeed(widget.playbackSpeed);
    }
    final oldSingleLoop = oldWidget.isLooping && oldWidget.playlist.length <= 1;
    if (oldSingleLoop != _shouldLoopSingleClip) {
      c.setLooping(_shouldLoopSingleClip);
    }
  }

  Future<void> _restartCurrentController() async {
    final c = _controller;
    if (c == null || !_isInitialized) return;
    _hasNotifiedCompletion = false;
    await c.setLooping(_shouldLoopSingleClip);
    await c.setPlaybackSpeed(widget.playbackSpeed);
    await c.seekTo(Duration.zero);
    await c.play();
    if (mounted) {
      setState(() {
        _isPlaying = true;
        _position = Duration.zero;
      });
    }
  }

  void _videoListener() {
    final c = _controller;
    if (c == null || !mounted || !c.value.isInitialized) return;
    final playing = c.value.isPlaying;
    final pos = c.value.position;
    final dur = c.value.duration;

    // Reset completion guard if the user scrubs back before the end
    if (_hasNotifiedCompletion &&
        dur > Duration.zero &&
        pos < dur - const Duration(milliseconds: 200)) {
      _hasNotifiedCompletion = false;
    }

    final bool reachedEnd =
        c.value.isCompleted ||
        (dur > Duration.zero &&
            pos > Duration.zero &&
            !playing &&
            pos >= dur - const Duration(milliseconds: 80));

    if (!_shouldLoopSingleClip &&
        reachedEnd &&
        !_hasNotifiedCompletion &&
        widget.onVideoCompleted != null) {
      _hasNotifiedCompletion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onVideoCompleted?.call();
        }
      });
    }

    if (playing != _isPlaying ||
        dur != _duration ||
        (pos.inMilliseconds - _position.inMilliseconds).abs() >= 100) {
      setState(() {
        _isPlaying = playing;
        _position = pos;
        _duration = dur;
      });
    }
  }

  Future<void> _initializePlayer() async {
    final token = ++_initToken;
    final old = _controller;
    old?.removeListener(_videoListener);

    _controller = null;
    _isInitialized = false;
    _isPlaying = false;
    _hasNotifiedCompletion = false;
    _playerError = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    await old?.dispose();

    final source = widget.videoSource;
    if (source.isEmpty || token != _initToken) return;

    VideoPlayerController? controller;
    try {
      if (source.startsWith('assets/')) {
        controller = VideoPlayerController.asset(source);
      } else if (source.startsWith('http://') ||
          source.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(source));
      } else {
        final file = File(source);
        if (!await SignLanguageCacheService.isValidMp4File(file)) {
          throw const FileSystemException('File video rusak atau tidak ada');
        }
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();
      if (token != _initToken || !mounted) {
        await controller.dispose();
        return;
      }
      await controller.setPlaybackSpeed(widget.playbackSpeed);
      await controller.setLooping(_shouldLoopSingleClip);
      await controller.play();

      if (token != _initToken || !mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(_videoListener);
      setState(() {
        _controller = controller;
        _isInitialized = true;
        _isPlaying = controller!.value.isPlaying;
        _position = controller.value.position;
        _duration = controller.value.duration;
      });
    } catch (e) {
      debugPrint('[ImmersiveSignVideoCard] init gagal ($source): $e');
      controller?.removeListener(_videoListener);
      await controller?.dispose();
      if (token == _initToken && mounted) {
        setState(() {
          _isInitialized = false;
          _isPlaying = false;
          _playerError = 'Video tidak dapat diputar.';
        });
      }
    }
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _isPlaying = false);
    } else {
      final atEnd =
          c.value.isCompleted ||
          (_duration > Duration.zero &&
              _position >= _duration - const Duration(milliseconds: 80));
      if (atEnd) {
        if (widget.playlist.length > 1 &&
            widget.activeWordIndex >= widget.playlist.length - 1 &&
            widget.onWordSelected != null) {
          widget.onWordSelected!.call(0);
          return;
        }
        _hasNotifiedCompletion = false;
        c.seekTo(Duration.zero);
      }
      c.play();
      setState(() => _isPlaying = true);
    }
  }

  void _replay() {
    HapticFeedback.lightImpact();
    if (widget.playlist.length > 1 &&
        widget.activeWordIndex > 0 &&
        widget.onWordSelected != null &&
        _hasNotifiedCompletion) {
      widget.onWordSelected!.call(0);
      return;
    }
    final c = _controller;
    if (c == null || !_isInitialized) return;
    _hasNotifiedCompletion = false;
    c.seekTo(Duration.zero);
    c.play();
    setState(() => _isPlaying = true);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _initToken++;
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEntry =
        (widget.playlist.isNotEmpty &&
            widget.activeWordIndex < widget.playlist.length)
        ? widget.playlist[widget.activeWordIndex]
        : null;

    final isOfflineAsset = widget.videoSource.startsWith('assets/');
    final isLocalCache =
        !isOfflineAsset &&
        !widget.videoSource.startsWith('http://') &&
        !widget.videoSource.startsWith('https://') &&
        widget.videoSource.isNotEmpty;

    final String heroWord = activeEntry?.label ??
        (widget.spokenPhrase.trim().isNotEmpty
            ? widget.spokenPhrase.trim()
            : 'Peragaan Isyarat');
    final String cleanPhrase = widget.spokenPhrase.trim();
    final bool showPhraseSubtitle =
        cleanPhrase.isNotEmpty &&
        cleanPhrase.toLowerCase() != heroWord.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenHeight = MediaQuery.sizeOf(context).height;
        final double cardHeight =
            widget.cardHeight ?? (screenHeight * 0.53).clamp(350.0, 500.0);

        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            // ── 1. Full-Bleed Editorial Hero Video Card ──────────────────────
            Container(
              height: cardHeight,
              decoration: BoxDecoration(
                color: AppColors.cameraDark,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.isDark
                      ? AppColors.darkBorderSoft
                      : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppColors.isDark ? 0.45 : 0.14,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1.1 Edge-to-Edge Video / State Layer (Zero White Bars!)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildVideoLayer(activeEntry),
                  ),

                  // 1.2 Subtle Top Scrim for Top Glass Pills
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 84,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 1.3 Bottom Cinematic Gradient Scrim + Editorial Caption
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.35, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.52),
                            Colors.black.withValues(alpha: 0.90),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 46, 22, 18),
                        child: Column(
                          crossAxisAlignment: .start,
                          mainAxisSize: .min,
                          children: [
                            // Status Eyebrow (Like "● Online" in reference)
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isPlaying
                                        ? AppColors.darkMatcha
                                        : AppColors.darkAmber,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    '${widget.signLanguageLabel.toUpperCase()} • ${AppStrings.speechSpokenText.tr.replaceAll(':', '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (_isInitialized)
                                  Text(
                                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Bold Editorial Active Sign Word
                            Text(
                              heroWord,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),

                            // Full Spoken Sentence Subtitle (only when distinct)
                            if (showPhraseSubtitle) ...[
                              const SizedBox(height: 4),
                              Text(
                                '"$cleanPhrase"',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Sleek Interactive Scrubber Bar
                            if (_isInitialized && _controller != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: VideoProgressIndicator(
                                  _controller!,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  colors: VideoProgressColors(
                                    playedColor: AppColors.darkSecondary,
                                    bufferedColor: Colors.white.withValues(
                                      alpha: 0.28,
                                    ),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),

                            // Interactive Multi-Word Pill Switcher (when > 1 word)
                            if (widget.playlist.length > 1) ...[
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: List.generate(
                                    widget.playlist.length,
                                    (index) {
                                      final entry = widget.playlist[index];
                                      final isActive =
                                          index == widget.activeWordIndex;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            widget.onWordSelected?.call(index);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppColors.darkSecondary
                                                  : Colors.white.withValues(
                                                      alpha: 0.14,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              entry.label,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                    color: isActive
                                                        ? AppColors.darkCanvas
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.88,
                                                              ),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 1.4 Top Floating Glass Pills (Status + Source)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        // Left: Playing / Paused Glass Pill
                        if (_isInitialized && !widget.isDownloading)
                          _buildGlassPill(
                            dotColor: _isPlaying
                                ? AppColors.darkMatcha
                                : AppColors.darkAmber,
                            label: _isPlaying
                                ? AppStrings.signVideoStatusPlaying.tr
                                : AppStrings.signVideoStatusPaused.tr,
                          )
                        else
                          const SizedBox.shrink(),

                        // Right: Offline / Cached / Online Glass Pill
                        _buildGlassPill(
                          dotColor: isOfflineAsset
                              ? AppColors.darkMatcha
                              : (isLocalCache
                                    ? AppColors.darkSecondary
                                    : AppColors.darkAmber),
                          label: widget.isDownloading
                              ? AppStrings.signVideoDownloading.tr
                              : (isOfflineAsset
                                    ? AppStrings.signVideoOfflineBadge.tr
                                    : (isLocalCache
                                          ? AppStrings.signVideoCachedBadge.tr
                                          : AppStrings
                                                .signVideoOnlineBadge
                                                .tr)),
                        ),
                      ],
                    ),
                  ),

                  // 1.5 Centered Frosted Play Icon when Paused
                  if (_isInitialized && !_isPlaying && !widget.isDownloading)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.46),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1.6,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── 2. Circular Tactile Control Dock (Reference Image 2 Style) ───
            Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                _buildCircularControl(
                  icon: Icons.replay_rounded,
                  label: AppStrings.signVideoReplay.tr,
                  onTap: _replay,
                ),
                _buildCircularControl(
                  icon: _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: _isPlaying
                      ? AppStrings.signVideoPause.tr
                      : AppStrings.signVideoPlay.tr,
                  isHero: true,
                  onTap: _togglePlayPause,
                ),
                _buildCircularControl(
                  icon: widget.isLooping && widget.playlist.length <= 1
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  label: AppStrings.signVideoLoop.tr,
                  isActive: widget.isLooping,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onToggleLoop?.call();
                  },
                ),
                if (widget.onSave != null)
                  _buildCircularControl(
                    icon: widget.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: AppStrings.save.tr,
                    isActive: widget.isSaved,
                    activeColor: AppColors.matcha,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSave?.call();
                    },
                  ),
              ],
            ),

            if (widget.onSpeakAgain != null) ...[
              const SizedBox(height: 20),

              // ── 3. Full-Width Thumb-Zone Primary Action Pill ─────────────────
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onSpeakAgain?.call();
                  },
                  icon: Icon(Icons.mic_rounded, size: 20, color: AppColors.ink),
                  label: Text(
                    AppStrings.speechSpeakAgain.tr,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.border, width: 1.2),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildVideoLayer(SignVideoEntry? activeEntry) {
    if (widget.isDownloading) {
      return Container(
        key: const ValueKey('immersive_downloading'),
        color: AppColors.cameraDark,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.cloud_download_rounded,
              size: 46,
              color: AppColors.darkSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.signVideoDownloadingTitle.tr,
              textAlign: .center,
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: widget.downloadProgress > 0
                    ? widget.downloadProgress
                    : null,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                color: AppColors.darkSecondary,
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }

    if (_isInitialized && _controller != null) {
      final size = _controller!.value.size;
      final videoWidth = size.width > 0 ? size.width : 16.0;
      final videoHeight = size.height > 0 ? size.height : 9.0;

      return GestureDetector(
        key: const ValueKey('immersive_video_active'),
        onTap: _togglePlayPause,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }

    if (widget.errorMessage != null || _playerError != null) {
      return Container(
        key: const ValueKey('immersive_error'),
        color: AppColors.cameraDark,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 12),
            Text(
              widget.errorMessage ?? _playerError!,
              textAlign: .center,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isLoading) {
      return const Center(
        key: ValueKey('immersive_loading'),
        child: CircularProgressIndicator(color: AppColors.darkSecondary),
      );
    }

    return Center(
      key: const ValueKey('immersive_placeholder'),
      child: Icon(
        Icons.sign_language_rounded,
        size: 64,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildGlassPill({required Color dotColor, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularControl({
    required IconData icon,
    required String label,
    bool isHero = false,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final double diameter = isHero ? 62 : 52;
    final Color highlight = activeColor ?? AppColors.secondary;
    final Color bgColor = isHero
        ? AppColors.primary
        : (isActive ? highlight.withValues(alpha: 0.16) : AppColors.surface);
    final Color fgColor = isHero
        ? AppColors.onPrimary
        : (isActive ? highlight : AppColors.ink);
    final Color borderColor = isHero
        ? Colors.transparent
        : (isActive ? highlight : AppColors.border);

    return Column(
      mainAxisSize: .min,
      children: [
        Semantics(
          label: label,
          button: true,
          child: Material(
            color: bgColor,
            shape: CircleBorder(
              side: BorderSide(color: borderColor, width: isActive ? 1.5 : 1.1),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: Center(
                  child: Icon(
                    icon,
                    size: isHero ? 30 : 22,
                    color: fgColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? highlight : AppColors.muted,
            fontWeight: isHero || isActive ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
