import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/settings_option_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final tts = Get.find<BisindoTtsService>();
    final cacheService = Get.find<SignLanguageCacheService>();

    return Obx(() {
      // Rebuild dynamically when themeMode or language changes
      settings.themeMode.value;
      settings.selectedAppLanguage.value;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                              _buildPreferencesCard(context, settings),
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
                              _buildVideoCard(context, settings),
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
                        _buildPreferencesCard(context, settings),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          AppStrings.settingsSectionTts.tr,
                        ),
                        _buildTtsCard(settings, tts),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          AppStrings.settingsSectionVideo.tr,
                        ),
                        _buildVideoCard(context, settings),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.muted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── 1. PREFERENCES CARD (BOTTOM SHEET TRIGGER TILES) ──────────────────────
  Widget _buildPreferencesCard(
    BuildContext context,
    SettingsController settings,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 1.1 Bahasa Aplikasi
          Obx(() {
            final isEn = settings.selectedAppLanguage.value == 'en';
            return _buildSelectionTile(
              context: context,
              icon: Icons.language_rounded,
              title: AppStrings.settingsAppLanguage.tr,
              subtitle: AppStrings.settingsAppLanguageDesc.tr,
              valueText: isEn ? AppStrings.langEnglish.tr : AppStrings.langIndonesian.tr,
              badgeText: isEn ? 'EN' : 'ID',
              onTap: () => _openLanguageSheet(context, settings),
            );
          }),
          Divider(color: AppColors.borderSoft, height: 1),

          // 1.2 Bahasa Isyarat Aktif
          Obx(() {
            final lang = settings.selectedSignLanguage.value;
            return _buildSelectionTile(
              context: context,
              icon: Icons.sign_language_rounded,
              title: AppStrings.settingsSignLanguage.tr,
              subtitle: AppStrings.settingsSignLanguageDesc.tr,
              valueText: lang,
              badgeText: lang == 'BISINDO' ? 'Alami' : 'Resmi',
              onTap: () => _openSignLanguageSheet(context, settings),
            );
          }),
          Divider(color: AppColors.borderSoft, height: 1),

          // 1.3 Peran Komunikasi
          Obx(() {
            final role = settings.selectedRole.value;
            final isDeaf = role == 'Teman Tuli' || role == AppStrings.roleDeaf.tr;
            return _buildSelectionTile(
              context: context,
              icon: isDeaf
                  ? Icons.hearing_disabled_rounded
                  : Icons.hearing_rounded,
              title: AppStrings.settingsRole.tr,
              subtitle: AppStrings.settingsRoleDesc.tr,
              valueText: isDeaf ? AppStrings.roleDeaf.tr : AppStrings.roleHearing.tr,
              badgeText: isDeaf ? 'Prioritas Kamera' : 'Prioritas Suara',
              onTap: () => _openRoleSheet(context, settings),
            );
          }),
          Divider(color: AppColors.borderSoft, height: 1),

          // 1.4 Tema Tampilan (Instagram AMOLED / Light / System)
          Obx(() {
            final mode = settings.themeMode.value;
            final currentText = mode == ThemeMode.light
                ? AppStrings.themeModeLight.tr
                : mode == ThemeMode.dark
                    ? AppStrings.themeModeDark.tr
                    : AppStrings.themeModeSystem.tr;

            final modeIcon = mode == ThemeMode.light
                ? Icons.wb_sunny_rounded
                : mode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.brightness_auto_rounded;

            return _buildSelectionTile(
              context: context,
              icon: modeIcon,
              title: AppStrings.settingsThemeMode.tr,
              subtitle: AppStrings.settingsThemeModeDesc.tr,
              valueText: currentText,
              badgeText: mode == ThemeMode.dark ? 'AMOLED' : null,
              onTap: () => _openThemeSheet(context, settings),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String valueText,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueText,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL BOTTOM SHEETS ───────────────────────────────────────────────────

  void _openLanguageSheet(BuildContext context, SettingsController settings) {
    SettingsOptionSheet.show<String>(
      context: context,
      title: AppStrings.settingsAppLanguage.tr,
      subtitle: AppStrings.settingsAppLanguageDesc.tr,
      titleIcon: Icons.language_rounded,
      selectedValue: settings.selectedAppLanguage.value,
      options: [
        SettingsOptionItem(
          value: 'id',
          title: AppStrings.langIndonesian.tr,
          subtitle: 'Antarmuka aplikasi dan sintesis suara dalam Bahasa Indonesia',
          icon: Icons.flag_circle_rounded,
          trailingBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ID',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        SettingsOptionItem(
          value: 'en',
          title: AppStrings.langEnglish.tr,
          subtitle: 'App interface and synthesized speech in English',
          icon: Icons.public_rounded,
          trailingBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'EN',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ],
      onSelected: (code) {
        settings.setAppLanguage(code);
      },
    );
  }

  void _openSignLanguageSheet(BuildContext context, SettingsController settings) {
    SettingsOptionSheet.show<String>(
      context: context,
      title: AppStrings.settingsSignLanguage.tr,
      subtitle: AppStrings.settingsSignLanguageDesc.tr,
      titleIcon: Icons.sign_language_rounded,
      selectedValue: settings.selectedSignLanguage.value,
      options: [
        SettingsOptionItem(
          value: 'BISINDO',
          title: 'BISINDO',
          subtitle: 'Bahasa Isyarat Indonesia alamiah (dua tangan, ekspresi visual)',
          icon: Icons.sign_language_rounded,
          trailingBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.matcha.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Populer',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.matcha,
              ),
            ),
          ),
        ),
        SettingsOptionItem(
          value: 'SIBI',
          title: 'SIBI',
          subtitle: 'Sistem Isyarat Bahasa Indonesia (sistem tata bahasa berimbuhan)',
          icon: Icons.pan_tool_rounded,
          trailingBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Formal',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ],
      onSelected: (lang) {
        settings.setSignLanguage(lang);
      },
    );
  }

  void _openRoleSheet(BuildContext context, SettingsController settings) {
    final currentRole = settings.selectedRole.value;
    final isDeaf = currentRole == 'Teman Tuli' || currentRole == AppStrings.roleDeaf.tr;

    SettingsOptionSheet.show<String>(
      context: context,
      title: AppStrings.settingsRole.tr,
      subtitle: AppStrings.settingsRoleDesc.tr,
      titleIcon: Icons.people_alt_rounded,
      selectedValue: isDeaf ? 'Teman Tuli' : 'Teman Dengar',
      options: [
        SettingsOptionItem(
          value: 'Teman Tuli',
          title: AppStrings.roleDeaf.tr,
          subtitle: 'Komunikasi visual: prioritas fitur Sign-to-Speech kamera & layar hadap kasir',
          icon: Icons.hearing_disabled_rounded,
        ),
        SettingsOptionItem(
          value: 'Teman Dengar',
          title: AppStrings.roleHearing.tr,
          subtitle: 'Komunikasi audio: prioritas Speech-to-Sign suara & kamus isyarat',
          icon: Icons.hearing_rounded,
        ),
      ],
      onSelected: (role) {
        settings.setRole(role);
      },
    );
  }

  void _openThemeSheet(BuildContext context, SettingsController settings) {
    SettingsOptionSheet.show<ThemeMode>(
      context: context,
      title: AppStrings.settingsThemeMode.tr,
      subtitle: AppStrings.settingsThemeModeDesc.tr,
      titleIcon: Icons.palette_rounded,
      selectedValue: settings.themeMode.value,
      options: [
        SettingsOptionItem(
          value: ThemeMode.system,
          title: AppStrings.themeModeSystem.tr,
          subtitle: 'Otomatis mengikuti preferensi tema terang atau gelap di perangkat Anda',
          icon: Icons.brightness_auto_rounded,
        ),
        SettingsOptionItem(
          value: ThemeMode.light,
          title: AppStrings.themeModeLight.tr,
          subtitle: 'Nuansa Cafe Espresso & Warm Oat Milk (#FDFBF7) yang nyaman dan hangat',
          icon: Icons.wb_sunny_rounded,
          visualPreview: _buildThemePreviewSwatch(
            canvas: const Color(0xFFFDFBF7),
            surface: const Color(0xFFFFFFFF),
            primary: const Color(0xFF2C1E18),
            secondary: const Color(0xFF8C5A3C),
            label: 'Cafe Warm Oat Milk / Espresso',
          ),
        ),
        SettingsOptionItem(
          value: ThemeMode.dark,
          title: AppStrings.themeModeDark.tr,
          subtitle: 'Instagram AMOLED Minimalist True Black (#000000) hemat daya & elegan',
          icon: Icons.dark_mode_rounded,
          visualPreview: _buildThemePreviewSwatch(
            canvas: const Color(0xFF000000),
            surface: const Color(0xFF121212),
            primary: const Color(0xFFF5F5F5),
            secondary: const Color(0xFFD49B78),
            label: 'Instagram AMOLED Dark Mode',
          ),
        ),
      ],
      onSelected: (mode) {
        settings.setThemeMode(mode);
      },
    );
  }

  Widget _buildThemePreviewSwatch({
    required Color canvas,
    required Color surface,
    required Color primary,
    required Color secondary,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: surface == Colors.white
              ? const Color(0xFFE6DCD2)
              : const Color(0xFF262626),
        ),
      ),
      child: Row(
        children: [
          _buildSwatchDot(canvas, 'Canvas'),
          const SizedBox(width: 6),
          _buildSwatchDot(surface, 'Card'),
          const SizedBox(width: 6),
          _buildSwatchDot(primary, 'Brand'),
          const SizedBox(width: 6),
          _buildSwatchDot(secondary, 'Accent'),
          const Spacer(),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchDot(Color color, String label) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }

  // ── 2. TTS AUDIO CARD ─────────────────────────────────────────────────────
  Widget _buildTtsCard(SettingsController settings, BisindoTtsService tts) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.settingsTtsSpeed.tr,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      AppStrings.settingsTtsSpeedDesc.tr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${settings.ttsSpeed.value.toStringAsFixed(2)}x',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 14),

          // Speed Slider
          Obx(
            () => Slider(
              value: settings.ttsSpeed.value,
              min: 0.5,
              max: 1.5,
              divisions: 8,
              label: '${settings.ttsSpeed.value.toStringAsFixed(2)}x',
              activeColor: AppColors.secondary,
              inactiveColor: AppColors.border,
              thumbColor: AppColors.secondary,
              onChanged: (val) => settings.setTtsSpeed(val),
            ),
          ),

          // Speed Quick Preset Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetChip('0.75x', 0.75, settings),
              const SizedBox(width: 8),
              _buildPresetChip('1.0x (Normal)', 1.0, settings),
              const SizedBox(width: 8),
              _buildPresetChip('1.25x', 1.25, settings),
            ],
          ),
          const SizedBox(height: 14),

          // Test Speech Button
          ElevatedButton.icon(
            onPressed: () => settings.testTtsVoice(),
            icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
            label: Text(
              AppStrings.settingsTestVoice.tr,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    double value,
    SettingsController settings,
  ) {
    return Obx(() {
      final isSelected = (settings.ttsSpeed.value - value).abs() < 0.05;
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          settings.setTtsSpeed(value);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondary.withValues(alpha: 0.15)
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.secondary : AppColors.muted,
            ),
          ),
        ),
      );
    });
  }

  // ── 3. VIDEO SPEED CARD ───────────────────────────────────────────────────
  Widget _buildVideoCard(BuildContext context, SettingsController settings) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.slow_motion_video_rounded,
                  size: 20,
                  color: AppColors.matcha,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.settingsVideoSpeed.tr,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      AppStrings.settingsVideoSpeedDesc.tr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${settings.videoSpeed.value.toStringAsFixed(2)}x',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.matcha,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVideoSpeedChip('0.5x', 0.5, settings),
              _buildVideoSpeedChip('0.75x', 0.75, settings),
              _buildVideoSpeedChip('1.0x (Normal)', 1.0, settings),
              _buildVideoSpeedChip('1.25x', 1.25, settings),
              _buildVideoSpeedChip('1.5x', 1.5, settings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSpeedChip(
    String label,
    double value,
    SettingsController settings,
  ) {
    return Obx(() {
      final isSelected = (settings.videoSpeed.value - value).abs() < 0.05;
      return InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          settings.setVideoSpeed(value);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.matcha.withValues(alpha: 0.15)
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.matcha : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.matcha : AppColors.muted,
            ),
          ),
        ),
      );
    });
  }

  // ── 4. STORAGE CARD ───────────────────────────────────────────────────────
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tier 1 + Tier 2 Aktif',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.matcha,
                  ),
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
              HapticFeedback.mediumImpact();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 42),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. ABOUT CARD ─────────────────────────────────────────────────────────
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'v2.3.0 (Inclusive Cafe Edition)',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
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
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.offAllNamed(AppRoutes.onboarding1);
            },
            icon: const Icon(Icons.school_rounded, size: 18),
            label: Text(
              'Buka Ulang Panduan Onboarding',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 42),
            ),
          ),
        ],
      ),
    );
  }
}
