import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/sign_language_cache_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final tts = Get.find<BisindoTtsService>();
    final cacheService = Get.find<SignLanguageCacheService>();

    return Obx(() {
      // Rebuild dynamically when themeMode changes
      settings.themeMode.value;

      return Scaffold(
        backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          AppStrings.settingsTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxContentWidth,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: context.isExpanded
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader(
                              AppStrings.settingsSectionPreferences.tr,
                            ),
                            _buildPreferencesCard(settings),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Tentang Sign2Speech'),
                            _buildAboutCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader(
                              AppStrings.settingsSectionTts.tr,
                            ),
                            _buildTtsCard(settings, tts),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              AppStrings.settingsSectionVideo.tr,
                            ),
                            _buildVideoCard(settings),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              AppStrings.settingsSectionStorage.tr,
                            ),
                            _buildStorageCard(cacheService),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(
                        AppStrings.settingsSectionPreferences.tr,
                      ),
                      _buildPreferencesCard(settings),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        AppStrings.settingsSectionTts.tr,
                      ),
                      _buildTtsCard(settings, tts),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        AppStrings.settingsSectionVideo.tr,
                      ),
                      _buildVideoCard(settings),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        AppStrings.settingsSectionStorage.tr,
                      ),
                      _buildStorageCard(cacheService),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Tentang Sign2Speech'),
                      _buildAboutCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ),
    );
    });
  }

  Widget _buildPreferencesCard(SettingsController settings) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bahasa Aplikasi (Interface Language)
          Obx(
            () => _buildDropdownRow(
              title: AppStrings.settingsAppLanguage.tr,
              subtitle: AppStrings.settingsAppLanguageDesc.tr,
              value: settings.selectedAppLanguage.value == 'id'
                  ? AppStrings.langIndonesian.tr
                  : AppStrings.langEnglish.tr,
              items: [
                AppStrings.langIndonesian.tr,
                AppStrings.langEnglish.tr,
              ],
              onChanged: (val) {
                if (val != null) {
                  final code =
                      val == AppStrings.langEnglish.tr ? 'en' : 'id';
                  settings.setAppLanguage(code);
                }
              },
            ),
          ),
          Divider(color: AppColors.borderSoft, height: 24),

          // Bahasa Isyarat Aktif
          Obx(
            () => _buildDropdownRow(
              title: AppStrings.settingsSignLanguage.tr,
              subtitle: AppStrings.settingsSignLanguageDesc.tr,
              value: settings.selectedSignLanguage.value,
              items: const ['BISINDO', 'SIBI'],
              onChanged: (val) {
                if (val != null) settings.setSignLanguage(val);
              },
            ),
          ),
          Divider(color: AppColors.borderSoft, height: 24),

          // Peran Komunikasi
          Obx(
            () => _buildDropdownRow(
              title: AppStrings.settingsRole.tr,
              subtitle: AppStrings.settingsRoleDesc.tr,
              value: settings.selectedRole.value,
              items: [
                AppStrings.roleDeaf.tr,
                AppStrings.roleHearing.tr,
              ],
              onChanged: (val) {
                if (val != null) settings.setRole(val);
              },
            ),
          ),
          Divider(color: AppColors.borderSoft, height: 24),

          // Tema Tampilan (Instagram Dark Mode / Light / System)
          Obx(
            () {
              final mode = settings.themeMode.value;
              final currentText = mode == ThemeMode.light
                  ? AppStrings.themeModeLight.tr
                  : mode == ThemeMode.dark
                      ? AppStrings.themeModeDark.tr
                      : AppStrings.themeModeSystem.tr;

              return _buildDropdownRow(
                title: AppStrings.settingsThemeMode.tr,
                subtitle: AppStrings.settingsThemeModeDesc.tr,
                value: currentText,
                items: [
                  AppStrings.themeModeSystem.tr,
                  AppStrings.themeModeLight.tr,
                  AppStrings.themeModeDark.tr,
                ],
                onChanged: (val) {
                  if (val != null) {
                    if (val == AppStrings.themeModeLight.tr) {
                      settings.setThemeMode(ThemeMode.light);
                    } else if (val == AppStrings.themeModeDark.tr) {
                      settings.setThemeMode(ThemeMode.dark);
                    } else {
                      settings.setThemeMode(ThemeMode.system);
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTtsCard(SettingsController settings, BisindoTtsService tts) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.settingsTtsSpeed.tr,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.settingsTtsSpeedDesc.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
            ),
          ),
          Obx(
            () => Slider(
              value: settings.ttsSpeed.value,
              min: 0.5,
              max: 1.5,
              divisions: 4,
              label: '${settings.ttsSpeed.value}x',
              activeColor: AppColors.secondary,
              inactiveColor: AppColors.border,
              thumbColor: AppColors.secondary,
              onChanged: (val) => settings.setTtsSpeed(val),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              tts.speak(
                settings.selectedAppLanguage.value == 'id'
                    ? 'Halo! Ini adalah contoh suara Bahasa Indonesia Sign2Speech.'
                    : 'Hello! This is a voice sample for Sign2Speech application.',
              );
            },
            icon: const Icon(Icons.volume_up, size: 18),
            label: Text(
              AppStrings.settingsTestVoice.tr,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textOnDark,
              minimumSize: const Size(double.infinity, 42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(SettingsController settings) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => _buildDropdownRow(
          title: AppStrings.settingsVideoSpeed.tr,
          subtitle: AppStrings.settingsVideoSpeedDesc.tr,
          value: '${settings.videoSpeed.value}x',
          items: const ['0.75x', '1.0x', '1.25x'],
          onChanged: (val) {
            if (val != null) {
              final speed =
                  double.tryParse(val.replaceAll('x', '')) ?? 1.0;
              settings.setVideoSpeed(speed);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStorageCard(SignLanguageCacheService cacheService) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.settingsOfflineStorage.tr,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tier 1 + Tier 2 Aktif',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.matcha,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.settingsOfflineStorageDesc.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await cacheService.clearCache();
              Get.snackbar(
                AppStrings.settingsClearCache.tr,
                AppStrings.settingsCacheCleared.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.surface,
                colorText: AppColors.ink,
                margin: const EdgeInsets.all(16),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              AppStrings.settingsClearCache.tr,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Versi Aplikasi',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'v2.2.0 (Inclusive Cafe Edition)',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Privasi & Keamanan: Pemrosesan kamera dan koordinat MediaPipe berjalan 100% lokal di perangkat tanpa pengunggahan frame ke internet.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              Get.offAllNamed(AppRoutes.onboarding1);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 42),
            ),
            child: Text(
              'Buka Ulang Panduan Onboarding',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveItems = items.contains(value) ? items : [...items, value];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.secondary),
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          items: effectiveItems.map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
