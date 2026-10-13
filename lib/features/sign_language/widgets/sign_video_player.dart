import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_cache_service.dart';

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
  });

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _playerError;

  /// Increments on every (re)initialization so stale async inits are dropped.
  int _initToken = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _initializePlayer() async {
    final token = ++_initToken;
    final old = _controller;
    // Dipanggil dari initState/didUpdateWidget yang selalu diikuti build,
    // jadi cukup assign langsung (setState di initState memicu assert).
    _controller = null;
    _isInitialized = false;
    _playerError = null;
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
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('[SignVideoPlayer] init gagal ($source): $e');
      await controller?.dispose();
      if (token == _initToken && mounted) {
        setState(() {
          _isInitialized = false;
          _playerError = 'Video tidak dapat diputar.';
        });
      }
    }
  }

  @override
  void dispose() {
    _initToken++;
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
          // Video viewport
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: AppColors.ink,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isInitialized && _controller != null)
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio > 0
                              ? _controller!.value.aspectRatio
                              : 16 / 10,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    else if (widget.isDownloading)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: AppColors.secondary,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Mengunduh dari hajicare-sign.web.app...',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.downloadProgress > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${(widget.downloadProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: AppColors.surface.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (widget.errorMessage != null ||
                        _playerError != null)
                      Padding(
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
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.isLoading)
                      const CircularProgressIndicator(color: AppColors.surface)
                    else
                      Column(
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

                    // Offline / Cache / Online Source Badge (Top-Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOfflineAsset
                              ? const Color(0xFF1B5E20).withValues(alpha: 0.85)
                              : (isLocalCache
                                  ? AppColors.secondary.withValues(alpha: 0.90)
                                  : AppColors.primary.withValues(alpha: 0.85)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: 0.25),
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
                                      : Icons.cloud_download_rounded),
                              size: 14,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOfflineAsset
                                  ? 'Video Offline'
                                  : (isLocalCache
                                      ? 'Tersimpan di Cache'
                                      : 'hajicare-sign.web.app'),
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Active Word Overlay (Bottom-Left)
                    if (activeEntry != null)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activeEntry.label,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 14,
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

          // Sequential playlist chips
          if (widget.playlist.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.playlist.length, (index) {
                    final item = widget.playlist[index];
                    final isActive = index == widget.activeWordIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: isActive,
                        onSelected: (_) => widget.onWordSelected?.call(index),
                        selectedColor: AppColors.secondary,
                        backgroundColor: AppColors.paleMist,
                        labelStyle: TextStyle(
                          color: isActive ? AppColors.surface : AppColors.ink,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

          // Playback controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_rounded),
                      color: AppColors.ink,
                      tooltip: 'Putar Ulang',
                      onPressed: () {
                        _controller?.seekTo(Duration.zero);
                        _controller?.play();
                        widget.onReplay?.call();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isLooping
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                      ),
                      color: widget.isLooping
                          ? AppColors.secondary
                          : AppColors.muted,
                      tooltip: 'Ulangi Otomatis',
                      onPressed: widget.onToggleLoop,
                    ),
                  ],
                ),

                // Speed buttons (0.75x, 1.0x, 1.25x)
                Row(
                  children: [0.75, 1.0, 1.25].map((speed) {
                    final isSelected = widget.playbackSpeed == speed;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: () => widget.onSpeedChanged?.call(speed),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.softFjord
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
}
