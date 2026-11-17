import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/sign_language_cache_service.dart';
import '../widgets/settings_option_sheet.dart';

/// Redesigned SettingsScreen conforming to the modern grouped-card reference design.
/// Features a prominent user profile banner, categorized grouped cards with rounded corners,
/// inline audio/video adjustments, and responsive multi-device layouts.
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
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: AppColors.muted,
                size: 22,
              ),
              tooltip: AppStrings.settingsSectionSupportAbout.tr,
              onPressed: () => _showAboutAppDialog(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: ResponsiveContentWrapper(
            maxWidth: ResponsiveBreakpoints.maxContentWidth,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 114),
              child:
                  (context.isExpanded &&
                      MediaQuery.sizeOf(context).height >= 550)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileCard(context, settings),
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                AppStrings.settingsSectionPreferences.tr,
                              ),
                              _buildPreferencesCard(context, settings),
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                AppStrings.settingsSectionGeneral.tr,
                              ),
                              _buildGeneralCard(context, settings),
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                AppStrings.settingsSectionSupportAbout.tr,
                              ),
                              _buildSupportAboutCard(context),
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
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                AppStrings.settingsSectionVideo.tr,
                              ),
                              _buildVideoCard(context, settings),
                              const SizedBox(height: 20),
                              _buildSectionHeader(
                                AppStrings.settingsSectionStorage.tr,
                              ),
                              _buildStorageConnectionCard(
                                context,
                                cacheService,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Profile Card (Matches reference design)
                        _buildProfileCard(context, settings),
                        const SizedBox(height: 20),

                        // 1. Preferensi Bahasa & Peran
                        _buildSectionHeader(
                          AppStrings.settingsSectionPreferences.tr,
                        ),
                        _buildPreferencesCard(context, settings),
                        const SizedBox(height: 20),

                        // 2. Umum & Tampilan
                        _buildSectionHeader(
                          AppStrings.settingsSectionGeneral.tr,
                        ),
                        _buildGeneralCard(context, settings),
                        const SizedBox(height: 20),

                        // 3. Audio TTS (Inline Sliders)
                        _buildSectionHeader(AppStrings.settingsSectionTts.tr),
                        _buildTtsCard(settings, tts),
                        const SizedBox(height: 20),

                        // 4. Video Peragaan Isyarat
                        _buildSectionHeader(AppStrings.settingsSectionVideo.tr),
                        _buildVideoCard(context, settings),
                        const SizedBox(height: 20),

                        // 5. Penyimpanan & Koneksi Data
                        _buildSectionHeader(
                          AppStrings.settingsSectionStorage.tr,
                        ),
                        _buildStorageConnectionCard(context, cacheService),
                        const SizedBox(height: 20),

                        // 6. Bantuan & Tentang Aplikasi
                        _buildSectionHeader(
                          AppStrings.settingsSectionSupportAbout.tr,
                        ),
                        _buildSupportAboutCard(context),
                        const SizedBox(height: 104),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ── HEADER SECTION OUTSIDE CARD ───────────────────────────────────────────
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

  // ── 0. PROFILE CARD (MATCHES REFERENCE CARD) ──────────────────────────────
  Widget _buildProfileCard(BuildContext context, SettingsController settings) {
    final role = settings.selectedRole.value;
    final isDeaf = role == 'Teman Tuli' || role == AppStrings.roleDeaf.tr;
    final signLang = settings.selectedSignLanguage.value;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Circular Avatar with Role Icon & Status Indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isDeaf
                        ? Icons.hearing_disabled_rounded
                        : Icons.hearing_rounded,
                    size: 28,
                    color: AppColors.secondary,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.matcha,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // User Name & Role Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppStrings.settingsProfileSubtitle.tr} • $signLang',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Edit Profile / Role Action Link
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _openRoleSheet(context, settings);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.settingsProfileEditRole.tr,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. PREFERENCES GROUP CARD ─────────────────────────────────────────────
  Widget _buildPreferencesCard(
    BuildContext context,
    SettingsController settings,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // 1.1 Peran Komunikasi
          Obx(() {
            final role = settings.selectedRole.value;
            final isDeaf =
                role == 'Teman Tuli' || role == AppStrings.roleDeaf.tr;
            return _buildSettingsRowItem(
              icon: isDeaf
                  ? Icons.hearing_disabled_rounded
                  : Icons.hearing_rounded,
              title: AppStrings.settingsRole.tr,
              subtitle: AppStrings.settingsRoleDesc.tr,
              valueText: isDeaf
                  ? AppStrings.roleDeaf.tr
                  : AppStrings.roleHearing.tr,
              badgeText: isDeaf ? 'Prioritas Kamera' : 'Prioritas Suara',
              onTap: () => _openRoleSheet(context, settings),
            );
          }),
          Divider(
            color: AppColors.borderSoft,
            height: 1,
            indent: 52,
            endIndent: 16,
          ),

          // 1.2 Bahasa Isyarat Aktif
          Obx(() {
            final lang = settings.selectedSignLanguage.value;
            return _buildSettingsRowItem(
              icon: Icons.sign_language_rounded,
              title: AppStrings.settingsSignLanguage.tr,
              subtitle: AppStrings.settingsSignLanguageDesc.tr,
              valueText: lang,
              badgeText: lang == 'BISINDO' ? 'Alami' : 'Formal',
              onTap: () => _openSignLanguageSheet(context, settings),
            );
          }),
        ],
      ),
    );
  }

  // ── 2. GENERAL GROUP CARD ─────────────────────────────────────────────────
  Widget _buildGeneralCard(BuildContext context, SettingsController settings) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // 2.1 Bahasa Aplikasi
          Obx(() {
            final isEn = settings.selectedAppLanguage.value == 'en';
            return _buildSettingsRowItem(
              icon: Icons.language_rounded,
              title: AppStrings.settingsAppLanguage.tr,
              subtitle: AppStrings.settingsAppLanguageDesc.tr,
              valueText: isEn
                  ? AppStrings.langEnglish.tr
                  : AppStrings.langIndonesian.tr,
              badgeText: isEn ? 'EN' : 'ID',
              onTap: () => _openLanguageSheet(context, settings),
            );
          }),
          Divider(
            color: AppColors.borderSoft,
            height: 1,
            indent: 52,
            endIndent: 16,
          ),

          // 2.2 Tema Tampilan
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

            return _buildSettingsRowItem(
              icon: modeIcon,
              title: AppStrings.settingsThemeMode.tr,
              subtitle: AppStrings.settingsThemeModeDesc.tr,
              valueText: currentText,
              badgeText: mode == ThemeMode.dark ? 'AMOLED' : null,
              onTap: () => _openThemeSheet(context, settings),
            );
          }),
          Divider(
            color: AppColors.borderSoft,
            height: 1,
            indent: 52,
            endIndent: 16,
          ),

          // 2.3 Pintasan Meja Kasir
          _buildSettingsRowItem(
            icon: Icons.point_of_sale_rounded,
            title: AppStrings.cashierAssistantTitle.tr,
            subtitle: AppStrings.cashierAssistantSubtitle.tr,
            valueText: 'Buka',
            onTap: () {
              HapticFeedback.lightImpact();
              Get.toNamed(AppRoutes.cafeCashierCounter);
            },
          ),
        ],
      ),
    );
  }

  // ── 3. TTS AUDIO CARD ─────────────────────────────────────────────────────
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
              Obx(
                () => Container(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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

  // ── 4. VIDEO SPEED CARD ───────────────────────────────────────────────────
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
              Obx(
                () => Container(
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
                ),
              ),
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

  // ── 5. STORAGE & CONNECTION GROUP CARD ────────────────────────────────────
  Widget _buildStorageConnectionCard(
    BuildContext context,
    SignLanguageCacheService cacheService,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // 5.1 Storage & Cache
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                const SizedBox(height: 4),
                Text(
                  AppStrings.settingsOfflineStorageDesc.tr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await cacheService.clearCache();
                    AppSnackbar.success(
                      title: AppStrings.settingsClearCache.tr,
                      message: AppStrings.settingsCacheCleared.tr,
                      icon: Icons.delete_sweep_rounded,
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
          ),
          Divider(
            color: AppColors.borderSoft,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          // 5.2 Supabase Cloud Sync Status
          _buildSettingsRowItem(
            icon: Icons.cloud_done_rounded,
            iconColor: AppColors.matcha,
            title: AppStrings.settingsSupabaseConnection.tr,
            subtitle: AppStrings.settingsSupabaseDesc.tr,
            valueText: 'Terhubung',
            badgeText: 'Online',
            onTap: () {
              AppSnackbar.info(
                title: AppStrings.settingsSupabaseConnection.tr,
                message:
                    'Supabase PostgreSQL & Storage aktif dan tersinkronisasi.',
                icon: Icons.cloud_done_rounded,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 6. SUPPORT & ABOUT GROUP CARD ─────────────────────────────────────────
  Widget _buildSupportAboutCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // 6.1 Panduan Onboarding
          _buildSettingsRowItem(
            icon: Icons.school_outlined,
            title: AppStrings.settingsGuideTitle.tr,
            subtitle: AppStrings.settingsGuideDesc.tr,
            valueText: 'Buka',
            onTap: () {
              HapticFeedback.lightImpact();
              Get.offAllNamed(AppRoutes.onboarding1);
            },
          ),
          Divider(
            color: AppColors.borderSoft,
            height: 1,
            indent: 52,
            endIndent: 16,
          ),

          // 6.2 Versi Aplikasi & Detail
          _buildSettingsRowItem(
            icon: Icons.info_outline_rounded,
            title: AppStrings.settingsAboutVersion.tr,
            subtitle: AppStrings.settingsAboutPrivacyDesc.tr,
            valueText: 'v2.3.0',
            badgeText: 'Stable',
            onTap: () => _showAboutAppDialog(context),
          ),
        ],
      ),
    );
  }

  // ── REUSABLE GROUP ROW ITEM ───────────────────────────────────────────────
  Widget _buildSettingsRowItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? valueText,
    String? badgeText,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title ${valueText ?? ""}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.secondary).withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? AppColors.secondary,
                  ),
                ),
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
                              color: (iconColor ?? AppColors.secondary)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: iconColor ?? AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
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
                  ],
                ),
              ),
              if (valueText != null) ...[
                const SizedBox(width: 8),
                Text(
                  valueText,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ABOUT APP DIALOG ──────────────────────────────────────────────────────
  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign2Speech',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi: v2.3.0 (Inclusive Cafe Edition)',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi jembatan komunikasi inklusif dua arah antara Teman Tuli dan Teman Dengar di kafe modern.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Privasi & Keamanan: Ekstraksi fitur MediaPipe dan model AI MotionGRU berjalan 100% lokal pada perangkat pengguna.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Tutup',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
          subtitle:
              'Antarmuka aplikasi dan sintesis suara dalam Bahasa Indonesia',
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

  void _openSignLanguageSheet(
    BuildContext context,
    SettingsController settings,
  ) {
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
          subtitle:
              'Bahasa Isyarat Indonesia alamiah (dua tangan, ekspresi visual)',
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
          subtitle:
              'Sistem Isyarat Bahasa Indonesia (sistem tata bahasa berimbuhan)',
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
    final isDeaf =
        currentRole == 'Teman Tuli' || currentRole == AppStrings.roleDeaf.tr;

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
}
