import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_cache_service.dart';
import '../services/sign_language_config.dart';

class SignVideoPlayer extends StatefulWidget {
  final List<SignVideoEntry> playlist;
  final int activeWordIndex;
  final String videoSource;
  final bool isLoading;
  final bool isDownloading;
  final double downloadProgress;
  final double playbackSpeed;
  final bool isLooping;
  final ValueChanged<int>? onWordSelected;
  final ValueChanged<double>? onSpeedChanged;
  final VoidCallback? onToggleLoop;
  final VoidCallback? onReplay;

  /// Pesan error dari controller (mis. video belum tersedia di server).
  final String? errorMessage;

  /// Callback opsional untuk mengunduh video online secara langsung ke penyimpanan lokal.
  final VoidCallback? onDownload;

  /// Callback opsional saat status putar/jeda berubah.
  final ValueChanged<bool>? onPlayPauseChanged;

  const SignVideoPlayer({
    super.key,
    required this.playlist,
    required this.activeWordIndex,
    required this.videoSource,
    this.isLoading = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.playbackSpeed = 1.0,
    this.isLooping = true,
    this.onWordSelected,
    this.onSpeedChanged,
    this.onToggleLoop,
    this.onReplay,
    this.errorMessage,
    this.onDownload,
    this.onPlayPauseChanged,
  });

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _playerError;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseOpacityAnimation;

  /// Increments on every (re)initialization so stale async inits are dropped.
  int _initToken = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseScaleAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _pulseOpacityAnimation = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _initializePlayer();
  }

  @override
  void didUpdateWidget(SignVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _initializePlayer();
      return;
    }
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (oldWidget.playbackSpeed != widget.playbackSpeed) {
      c.setPlaybackSpeed(widget.playbackSpeed);
    }
    if (oldWidget.isLooping != widget.isLooping) {
      c.setLooping(widget.isLooping);
    }
  }

  void _videoListener() {
    final c = _controller;
    if (c == null || !mounted || !c.value.isInitialized) return;
    final isPlaying = c.value.isPlaying;
    final pos = c.value.position;
    final dur = c.value.duration;

    if (isPlaying != _isPlaying ||
        dur != _duration ||
        (pos.inMilliseconds - _position.inMilliseconds).abs() >= 100) {
      setState(() {
        _isPlaying = isPlaying;
        _position = pos;
        _duration = dur;
      });
    }
  }

  Future<void> _initializePlayer() async {
    final token = ++_initToken;
    final old = _controller;
    old?.removeListener(_videoListener);

    // Dipanggil dari initState/didUpdateWidget yang selalu diikuti build,
    // jadi cukup assign langsung (setState di initState memicu assert).
    _controller = null;
    _isInitialized = false;
    _playerError = null;
    _isPlaying = false;
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
      await controller.setLooping(widget.isLooping);
      await controller.play();

      if (token != _initToken || !mounted) {
        await controller.dispose();
        return;
      }

      final active = controller;
      active.addListener(_videoListener);
      setState(() {
        _controller = active;
        _isInitialized = true;
        _isPlaying = active.value.isPlaying;
        _position = active.value.position;
        _duration = active.value.duration;
      });
      widget.onPlayPauseChanged?.call(_isPlaying);
    } catch (e) {
      debugPrint('[SignVideoPlayer] init gagal ($source): $e');
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
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _isPlaying = false);
      widget.onPlayPauseChanged?.call(false);
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        c.seekTo(Duration.zero);
      }
      c.play();
      setState(() => _isPlaying = true);
      widget.onPlayPauseChanged?.call(true);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _initToken++;
    _pulseController.dispose();
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
    final isOnline =
        !isOfflineAsset && !isLocalCache && widget.videoSource.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Video Viewport Area ─────────────────────────────────────────────
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: AppColors.ink,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Viewport content with smooth animated transition
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: _buildCurrentViewportContent(activeEntry),
                    ),

                    // Centered Big Play Button when Paused
                    if (_isInitialized && !_isPlaying && !widget.isDownloading)
                      Positioned.fill(
                        child: Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Status Indicator Badge (Top-Left)
                    if (_isInitialized && !widget.isDownloading)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlaying
                                    ? Icons.play_circle_filled_rounded
                                    : Icons.pause_circle_filled_rounded,
                                size: 12,
                                color: _isPlaying
                                    ? AppColors.matcha
                                    : AppColors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isPlaying
                                    ? AppStrings.signVideoStatusPlaying.tr
                                    : AppStrings.signVideoStatusPaused.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Offline / Cache / Online Source Badge (Top-Right)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: widget.isDownloading
                            ? Container(
                                key: const ValueKey('top_badge_downloading'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.90),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      AppStrings.signVideoDownloading.tr,
                                      style: TextStyle(
                                        color: AppColors.surface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                key: const ValueKey('top_badge_idle'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOfflineAsset
                                          ? AppColors.matcha
                                              .withValues(alpha: 0.90)
                                          : (isLocalCache
                                              ? AppColors.secondary
                                                  .withValues(alpha: 0.90)
                                              : AppColors.amber
                                                  .withValues(alpha: 0.90)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.surface
                                            .withValues(alpha: 0.30),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOfflineAsset
                                              ? Icons.offline_pin_rounded
                                              : (isLocalCache
                                                  ? Icons.folder_special_rounded
                                                  : Icons
                                                      .cloud_download_rounded),
                                          size: 12,
                                          color: AppColors.surface,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOfflineAsset
                                              ? AppStrings
                                                  .signVideoOfflineBadge.tr
                                              : (isLocalCache
                                                  ? AppStrings
                                                      .signVideoCachedBadge.tr
                                                  : AppStrings
                                                      .signVideoOnlineBadge.tr),
                                          style: TextStyle(
                                            color: AppColors.surface,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOnline &&
                                      widget.onDownload != null) ...[
                                    const SizedBox(width: 5),
                                    InkWell(
                                      onTap: widget.onDownload,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.download_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              AppStrings
                                                  .signVideoDownloadAction.tr,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),

                    // Active Word Overlay (Bottom-Left)
                    if (activeEntry != null && !widget.isDownloading)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            activeEntry.label,
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Timeline Scrubber & Indicators ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Interactive Scrubber Bar
                if (_isInitialized && _controller != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      colors: VideoProgressColors(
                        playedColor: AppColors.secondary,
                        bufferedColor:
                            AppColors.secondary.withValues(alpha: 0.25),
                        backgroundColor: AppColors.paleMist,
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.paleMist,
                    ),
                  ),
                const SizedBox(height: 3),
                // Indicator Status and Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isPlaying ? AppColors.matcha : AppColors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _isPlaying
                                  ? AppStrings.signVideoStatusPlaying.tr
                                  : AppStrings.signVideoStatusPaused.tr,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: AppTypography.labelSmall.copyWith(
                                color:
                                    _isPlaying ? AppColors.matcha : AppColors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Sequential Playlist Chips ──────────────────────────────────────
          if (widget.playlist.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(widget.playlist.length, (index) {
                    final item = widget.playlist[index];
                    final isActive = index == widget.activeWordIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: isActive,
                        onSelected: (_) => widget.onWordSelected?.call(index),
                        selectedColor: AppColors.secondary,
                        backgroundColor: AppColors.paleMist,
                        labelStyle: TextStyle(
                          color:
                              isActive ? AppColors.textOnDark : AppColors.ink,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isActive
                                ? AppColors.secondary
                                : AppColors.border,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

          // ── Playback Controls Row (Play/Pause, Replay, Loop, Speed) ─────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play / Pause Toggle Button
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 26,
                      ),
                      color: AppColors.primary,
                      tooltip: _isPlaying
                          ? AppStrings.signVideoPause.tr
                          : AppStrings.signVideoPlay.tr,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _togglePlayPause,
                    ),
                    // Replay Button
                    IconButton(
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      color: AppColors.ink,
                      tooltip: AppStrings.signVideoReplay.tr,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _controller?.seekTo(Duration.zero);
                        _controller?.play();
                        setState(() => _isPlaying = true);
                        widget.onReplay?.call();
                      },
                    ),
                    // Loop Toggle Button
                    IconButton(
                      icon: Icon(
                        widget.isLooping
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        size: 20,
                      ),
                      color: widget.isLooping
                          ? AppColors.secondary
                          : AppColors.muted,
                      tooltip: AppStrings.signVideoLoop.tr,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: widget.onToggleLoop,
                    ),
                  ],
                ),

                // Speed buttons (0.75x, 1.0x, 1.25x)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [0.75, 1.0, 1.25].map((speed) {
                    final isSelected = widget.playbackSpeed == speed;
                    return Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: InkWell(
                        onTap: () => widget.onSpeedChanged?.call(speed),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${speed}x',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentViewportContent(SignVideoEntry? activeEntry) {
    if (widget.isDownloading) {
      return _buildDownloadingView();
    }
    if (_isInitialized && _controller != null) {
      return GestureDetector(
        key: const ValueKey('video_player_active'),
        onTap: _togglePlayPause,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio > 0
                ? _controller!.value.aspectRatio
                : 16 / 10,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    if (widget.errorMessage != null || _playerError != null) {
      return Container(
        key: const ValueKey('video_error_state'),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 44,
              color: AppColors.surface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              widget.errorMessage ?? _playerError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }
    if (widget.isLoading) {
      return Container(
        key: const ValueKey('video_loading_state'),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: AppColors.surface),
      );
    }
    return Container(
      key: const ValueKey('video_placeholder_state'),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sign_language_rounded,
            size: 56,
            color: AppColors.surface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            activeEntry?.label ?? 'Peragaan Isyarat',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingView() {
    return Container(
      key: const ValueKey('video_downloading_overlay'),
      color: AppColors.cameraDark,
      alignment: Alignment.center,
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.40),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Breathing Animated Download Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => Transform.scale(
                          scale: _pulseScaleAnimation.value,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary.withValues(
                                alpha: _pulseOpacityAnimation.value * 0.22,
                              ),
                              border: Border.all(
                                color: AppColors.secondary.withValues(
                                  alpha: _pulseOpacityAnimation.value * 0.50,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cloud_download_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title Text
                  Text(
                    AppStrings.signVideoDownloadingTitle.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Host Domain / Info
                  Text(
                    SignLanguageConfig.hostDomain.isNotEmpty
                        ? 'Mengunduh dari ${SignLanguageConfig.hostDomain}...'
                        : AppStrings.signVideoDownloadingDesc.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.70),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Smooth Tween-interpolated Progress Bar
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: (widget.downloadProgress > 0)
                          ? widget.downloadProgress.clamp(0.0, 1.0)
                          : 0.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      final hasProgress = widget.downloadProgress > 0;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 170,
                              height: 6,
                              child: hasProgress
                                  ? LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: AppColors.surface
                                          .withValues(alpha: 0.18),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.secondary,
                                      ),
                                    )
                                  : LinearProgressIndicator(
                                      backgroundColor: AppColors.surface
                                          .withValues(alpha: 0.18),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.secondary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasProgress
                                ? '${(widget.downloadProgress * 100).toInt()}%'
                                : AppStrings.signVideoDownloading.tr,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

