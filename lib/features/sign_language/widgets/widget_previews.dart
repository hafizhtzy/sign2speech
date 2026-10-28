import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_config.dart';
import 'gesture_candidate_loader.dart';
import 'sign_video_player.dart';

/// Interactive Widget Previews for Sign Language UI components.
/// Can be used with Flutter Widget Previewer or embedded in catalog/preview screens.
class SignLanguageWidgetPreviews {
  SignLanguageWidgetPreviews._();

  /// Preview for GestureCandidateLoader in active reading mode
  static Widget previewGestureCandidateLoaderSigning() {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'),
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppColors.cameraDark,
        body: Center(
          child: GestureCandidateLoader(
            label: 'Halo',
            progress: 0.70,
            isConfirmed: false,
          ),
        ),
      ),
    );
  }

  /// Preview for GestureCandidateLoader in confirmed mode
  static Widget previewGestureCandidateLoaderConfirmed() {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'),
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppColors.cameraDark,
        body: Center(
          child: GestureCandidateLoader(
            label: 'Terima Kasih',
            progress: 1.0,
            isConfirmed: true,
          ),
        ),
      ),
    );
  }

  /// Preview for SignVideoPlayer with online CDN entry
  static Widget previewSignVideoPlayerOnline() {
    final entry = SignVideoEntry(
      id: 'bisindo_baik',
      label: 'Baik',
      aliases: const ['bagus'],
      category: 'salam',
      assetPath: '',
      remoteUrl: '${SignLanguageConfig.defaultBaseUrl}/videos/bisindo/baik_v1.mp4',
    );

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'),
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(16),
            child: SignVideoPlayer(
              playlist: [entry],
              activeWordIndex: 0,
              videoSource: entry.remoteUrl,
              isLoading: false,
              isDownloading: false,
              downloadProgress: 0.0,
              playbackSpeed: 1.0,
              isLooping: false,
              onWordSelected: (_) {},
              onSpeedChanged: (_) {},
              onToggleLoop: () {},
            ),
          ),
        ),
      ),
    );
  }

  /// Preview for SignVideoPlayer in downloading state from CDN
  static Widget previewSignVideoPlayerDownloading() {
    final entry = SignVideoEntry(
      id: 'sibi_halo',
      label: 'Halo',
      aliases: const ['hai'],
      category: 'salam',
      assetPath: '',
      remoteUrl: '${SignLanguageConfig.defaultBaseUrl}/videos/sibi/halo_v1.mp4',
    );

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'),
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(16),
            child: SignVideoPlayer(
              playlist: [entry],
              activeWordIndex: 0,
              videoSource: entry.remoteUrl,
              isLoading: false,
              isDownloading: true,
              downloadProgress: 0.65,
              playbackSpeed: 1.0,
              isLooping: false,
              onWordSelected: (_) {},
              onSpeedChanged: (_) {},
              onToggleLoop: () {},
            ),
          ),
        ),
      ),
    );
  }
}
