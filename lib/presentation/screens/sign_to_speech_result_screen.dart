import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/bisindo_recognition_controller.dart';

class SignToSpeechResultScreen extends StatelessWidget {
  const SignToSpeechResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recCtrl = Get.find<BisindoRecognitionController>();
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();

    final isEn = settings.selectedAppLanguage.value == 'en';
    final rawText = recCtrl.fullTranscriptText.isEmpty
        ? 'Halo, terima kasih. Saya mau bayar menggunakan QRIS.'
        : recCtrl.fullTranscriptText;
    final englishText = recCtrl.translationService.translateToEnglish(rawText);
    final displayText = isEn ? englishText : rawText;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          isEn ? 'Sign to Speech Result' : 'Hasil Sign to Speech',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Result Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(
                          label: settings.selectedSignLanguage.value,
                          variant: BadgeVariant.active,
                        ),
                        StatusBadge(
                          label: isEn
                              ? 'English (en-US)'
                              : 'Bahasa Indonesia (id-ID)',
                          variant: BadgeVariant.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayText,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                    if (isEn) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Isyarat Asli: $rawText',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Audio Trigger Row
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => recCtrl.replayLastOrFullTranscript(),
                          icon: const Icon(Icons.volume_up_rounded, size: 20),
                          label: Text(
                            isEn ? 'Play Voice' : 'Putar Suara',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnDark,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.textOnDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: displayText));
                            Get.snackbar(
                              isEn ? 'Copied' : 'Disalin',
                              isEn
                                  ? 'Translation copied to clipboard'
                                  : 'Teks terjemahan berhasil disalin ke papan klip',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surface,
                              colorText: AppColors.ink,
                              margin: const EdgeInsets.all(16),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(
                            isEn ? 'Copy Text' : 'Salin Teks',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bottom Actions
              AppSecondaryButton(
                label: isEn ? 'Save to History' : 'Simpan ke Riwayat',
                icon: Icons.bookmark_border_rounded,
                onPressed: () {
                  history.addHistoryEntry(
                    original: isEn
                        ? 'Sign Gesture ($rawText)'
                        : 'Gestur Kamera',
                    translated: displayText,
                    direction: TranslationDirection.signToSpeech,
                    signLanguage: settings.selectedSignLanguage.value,
                  );
                  Get.snackbar(
                    isEn ? 'Saved' : 'Tersimpan',
                    isEn
                        ? 'Translation saved to History'
                        : 'Terjemahan berhasil disimpan ke Riwayat',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.surface,
                    colorText: AppColors.ink,
                    margin: const EdgeInsets.all(16),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: 'Kembali ke Kamera',
                icon: Icons.camera_alt_rounded,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
