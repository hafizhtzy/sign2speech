import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/sign_translation_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Get.find<HistoryController>();
    final tts = Get.find<BisindoTtsService>();
    final settings = Get.find<SettingsController>();
    final translationService = Get.find<SignTranslationService>();

    return Obx(() {
      settings.themeMode.value;
      return Scaffold(
        backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          AppStrings.historyTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: AppStrings.historyClearAll.tr,
            onPressed: () {
              if (history.items.isEmpty) return;
              Get.defaultDialog(
                backgroundColor: AppColors.surface,
                radius: 20,
                title: AppStrings.historyConfirmClear.tr,
                titleStyle: AppTypography.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                middleText: AppStrings.historyConfirmDesc.tr,
                middleTextStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
                textConfirm: AppStrings.delete.tr,
                textCancel: AppStrings.cancel.tr,
                cancelTextColor: AppColors.ink,
                confirmTextColor: AppColors.isDark
                    ? AppColors.darkCanvas
                    : AppColors.textOnDark,
                buttonColor: AppColors.error,
                onConfirm: () {
                  history.clearAll();
                  Get.back();
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
          child: Column(
            children: [
              // Filter Tabs Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Obx(
                  () => Row(
                    children: [
                      _buildFilterTab(history, 0, AppStrings.libraryCategoryAll.tr),
                      const SizedBox(width: 8),
                      _buildFilterTab(history, 1, 'Sign to Speech'),
                      const SizedBox(width: 8),
                      _buildFilterTab(history, 2, 'Speech to Sign'),
                    ],
                  ),
                ),
              ),

              // Content List
              Expanded(
                child: Obx(() {
                  final list = history.filteredItems;

                  if (list.isEmpty) {
                    // Offset for floating bottom nav bar on compact screens so
                    // the empty state sits dead-center in the visible page area.
                    final bottomClearance = context.isLargeScreen
                        ? MediaQuery.paddingOf(context).bottom + 24.0
                        : MediaQuery.paddingOf(context).bottom + 114.0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: bottomClearance),
                      child: EmptyStateView(
                        title: AppStrings.historyEmptyTitle.tr,
                        subtitle: AppStrings.historyEmptyDesc.tr,
                        icon: Icons.history_toggle_off_rounded,
                        actionLabel: AppStrings.historyStartTranslation.tr,
                        onAction: () =>
                            _handleStartTranslation(context, history),
                      ),
                    );
                  }

                  if (context.isLargeScreen) {
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 114),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 460,
                        mainAxisExtent: 196,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) => _buildHistoryCard(
                        context,
                        list[index],
                        history,
                        tts,
                        settings,
                        translationService,
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 114),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildHistoryCard(
                      context,
                      list[index],
                      history,
                      tts,
                      settings,
                      translationService,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
    });
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryItem item,
    HistoryController history,
    BisindoTtsService tts,
    SettingsController settings,
    SignTranslationService translationService,
  ) {
    final isS2S = item.direction == TranslationDirection.signToSpeech;


                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.bgSurface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isS2S
                                            ? Icons.sign_language_rounded
                                            : Icons.record_voice_over_rounded,
                                        size: 18,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        isS2S ? 'Sign to Speech' : 'Speech to Sign',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        item.signLanguageType,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => history.deleteEntry(item.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final isEn =
                                  settings.selectedAppLanguage.value == 'en';
                              final englishText = translationService
                                  .translateToEnglish(item.translatedContent);
                              final displayText =
                                  isEn ? englishText : item.translatedContent;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (isEn &&
                                      englishText != item.translatedContent) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '${AppStrings.originalSign.tr}: ${item.translatedContent}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ] else if (item.originalContent.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${AppStrings.sourceText.tr}: ${item.originalContent}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(item.timestamp),
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (isS2S)
                                TextButton.icon(
                                  onPressed: () {
                                    final isEn =
                                        settings.selectedAppLanguage.value == 'en';
                                    final textToSpeak = isEn
                                        ? translationService
                                            .translateToEnglish(item.translatedContent)
                                        : item.translatedContent;
                                    tts.speak(
                                      textToSpeak,
                                      languageCode: isEn ? 'en-US' : 'id-ID',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.volume_up_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    AppStrings.playVoice.tr,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () {
                                    final ttsCtrl =
                                        Get.find<TextToSignController>();
                                    ttsCtrl.recognizedWords.value =
                                        item.originalContent;
                                    ttsCtrl.processVoiceInput(
                                      item.originalContent,
                                    );
                                    Get.toNamed(AppRoutes.speechToSignResult);
                                  },
                                  icon: const Icon(
                                    Icons.play_circle_outline,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Putar Video',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
  }


  Widget _buildFilterTab(HistoryController history, int index, String title) {
    final isSelected = history.selectedFilterIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => history.setFilter(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.onPrimary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  void _handleStartTranslation(
    BuildContext context,
    HistoryController history,
  ) {
    switch (history.selectedFilterIndex.value) {
      case 1:
        Get.toNamed(AppRoutes.signToSpeechCamera);
      case 2:
        Get.toNamed(AppRoutes.speechToSignMic);
      default:
        _showTranslationModeSheet(context);
    }
  }

  void _showTranslationModeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveBreakpoints.maxFormWidth,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.homeMainModes.tr,
                    textAlign: .center,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTranslationModeOption(
                    icon: Icons.videocam_rounded,
                    accentColor: AppColors.primary,
                    title: 'Sign to Speech',
                    subtitle: AppStrings.homeSignToSpeechDesc.tr,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Get.toNamed(AppRoutes.signToSpeechCamera);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTranslationModeOption(
                    icon: Icons.mic_rounded,
                    accentColor: AppColors.secondary,
                    title: 'Speech to Sign',
                    subtitle: AppStrings.homeSpeechToSignDesc.tr,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Get.toNamed(AppRoutes.speechToSignMic);
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

  Widget _buildTranslationModeOption({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute';
  }
}
