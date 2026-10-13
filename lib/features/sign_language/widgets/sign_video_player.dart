import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/sign_video_entry.dart';

class SignVideoPlayer extends StatefulWidget {
  final List<SignVideoEntry> playlist;
  final int activeWordIndex;
  final String videoSource;
  final bool isLoading;
  final double playbackSpeed;
  final bool isLooping;
  final ValueChanged<int>? onWordSelected;
  final ValueChanged<double>? onSpeedChanged;
  final VoidCallback? onToggleLoop;
  final VoidCallback? onReplay;

  const SignVideoPlayer({
    super.key,
    required this.playlist,
    required this.activeWordIndex,
    required this.videoSource,
    this.isLoading = false,
    this.playbackSpeed = 1.0,
    this.isLooping = true,
    this.onWordSelected,
    this.onSpeedChanged,
    this.onToggleLoop,
    this.onReplay,
  });

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

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
    } else if (oldWidget.playbackSpeed != widget.playbackSpeed &&
        _controller != null) {
      _controller!.setPlaybackSpeed(widget.playbackSpeed);
    }
  }

  Future<void> _initializePlayer() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;

    if (widget.videoSource.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    try {
      if (widget.videoSource.startsWith('assets/')) {
        _controller = VideoPlayerController.asset(widget.videoSource);
      } else if (widget.videoSource.startsWith('http://') ||
          widget.videoSource.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoSource),
        );
      } else {
        _controller = VideoPlayerController.file(File(widget.videoSource));
      }

      await _controller!.initialize();
      await _controller!.setPlaybackSpeed(widget.playbackSpeed);
      await _controller!.setLooping(widget.isLooping);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
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
                      VideoPlayer(_controller!)
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

                    // Offline / Source Badge (Top-Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.videoSource.startsWith('assets/')
                                  ? Icons.offline_pin
                                  : Icons.cloud_done,
                              size: 14,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.videoSource.startsWith('assets/')
                                  ? 'Offline Tier 1'
                                  : 'Tersedia',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                            'x',
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
