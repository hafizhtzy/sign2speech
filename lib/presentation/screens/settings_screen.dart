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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 132),
              child:
                  (context.isExpanded &&
                      MediaQuery.sizeOf(context).height >= 550)
                  ? Row(
                      crossAxisAlignment: .start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: .stretch,
                            children: [
                              _buildProfileCard(context, settings),
                              const SizedBox(height: 28),
                              _buildSectionHeader(
                                AppStrings.settingsSectionPreferences.tr,
                              ),
                              _buildPreferencesCard(context, settings),
                              const SizedBox(height: 28),
                              _buildSectionHeader(
                                AppStrings.settingsSectionGeneral.tr,
                              ),
                              _buildGeneralCard(context, settings),
                              const SizedBox(height: 28),
                              _buildSectionHeader(
                                AppStrings.settingsSectionSupportAbout.tr,
                              ),
                              _buildSupportAboutCard(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: .stretch,
                            children: [
                              _buildSectionHeader(
                                AppStrings.settingsSectionTts.tr,
                              ),
                              _buildTtsCard(settings, tts),
                              const SizedBox(height: 28),
                              _buildSectionHeader(
                                AppStrings.settingsSectionVideo.tr,
                              ),
                              _buildVideoCard(context, settings),
                              const SizedBox(height: 28),
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
                      crossAxisAlignment: .stretch,
                      children: [
                        _buildProfileCard(context, settings),
                        const SizedBox(height: 28),

                        _buildSectionHeader(
                          AppStrings.settingsSectionPreferences.tr,
                        ),
                        _buildPreferencesCard(context, settings),
                        const SizedBox(height: 28),

                        _buildSectionHeader(
                          AppStrings.settingsSectionGeneral.tr,
                        ),
                        _buildGeneralCard(context, settings),
                        const SizedBox(height: 28),

                        _buildSectionHeader(AppStrings.settingsSectionTts.tr),
                        _buildTtsCard(settings, tts),
                        const SizedBox(height: 28),

                        _buildSectionHeader(AppStrings.settingsSectionVideo.tr),
                        _buildVideoCard(context, settings),
                        const SizedBox(height: 28),

                        _buildSectionHeader(
                          AppStrings.settingsSectionStorage.tr,
                        ),
                        _buildStorageConnectionCard(context, cacheService),
                        const SizedBox(height: 28),

                        _buildSectionHeader(
                          AppStrings.settingsSectionSupportAbout.tr,
                        ),
                        _buildSupportAboutCard(context),
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
      padding: const EdgeInsets.only(bottom: 10, left: 6),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.35,
        ),
      ),
    );
  }

  Widget _buildRowDivider() {
    return Divider(
      color: AppColors.borderSoft.withValues(alpha: 0.7),
      height: 1,
      indent: 68,
      endIndent: 20,
    );
  }

  // ── 0. PROFILE CARD (MINIMALIST & TAPPABLE) ───────────────────────────────
  Widget _buildProfileCard(BuildContext context, SettingsController settings) {
    final role = settings.selectedRole.value;
    final isDeaf = role == 'Teman Tuli' || role == AppStrings.roleDeaf.tr;
    final signLang = settings.selectedSignLanguage.value;

    return AppCard(
      padding: const EdgeInsets.all(20),
      onTap: () {
        HapticFeedback.lightImpact();
        _openRoleSheet(context, settings);
      },
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                isDeaf
                    ? Icons.hearing_disabled_rounded
                    : Icons.hearing_rounded,
                size: 26,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
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
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.settingsProfileSubtitle.tr} • $signLang',
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
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.muted,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Obx(() {
            final role = settings.selectedRole.value;
            final isDeaf =
                role == 'Teman Tuli' || role == AppStrings.roleDeaf.tr;
            return _buildSettingsRowItem(
              icon: isDeaf
                  ? Icons.hearing_disabled_rounded
                  : Icons.hearing_rounded,
              title: AppStrings.settingsRole.tr,
              valueText: isDeaf
                  ? AppStrings.roleDeaf.tr
                  : AppStrings.roleHearing.tr,
              onTap: () => _openRoleSheet(context, settings),
            );
          }),
          _buildRowDivider(),
          Obx(() {
            final lang = settings.selectedSignLanguage.value;
            return _buildSettingsRowItem(
              icon: Icons.sign_language_rounded,
              title: AppStrings.settingsSignLanguage.tr,
              valueText: lang,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Obx(() {
            final isEn = settings.selectedAppLanguage.value == 'en';
            return _buildSettingsRowItem(
              icon: Icons.language_rounded,
              title: AppStrings.settingsAppLanguage.tr,
              valueText: isEn
                  ? AppStrings.langEnglish.tr
                  : AppStrings.langIndonesian.tr,
              onTap: () => _openLanguageSheet(context, settings),
            );
          }),
          _buildRowDivider(),
          Obx(() {
            final mode = settings.themeMode.value;
            final currentText = switch (mode) {
              ThemeMode.light => AppStrings.themeModeLight.tr,
              ThemeMode.dark => AppStrings.themeModeDark.tr,
              ThemeMode.system => AppStrings.themeModeSystem.tr,
            };
            final modeIcon = switch (mode) {
              ThemeMode.light => Icons.wb_sunny_rounded,
              ThemeMode.dark => Icons.dark_mode_rounded,
              ThemeMode.system => Icons.brightness_auto_rounded,
            };

            return _buildSettingsRowItem(
              icon: modeIcon,
              title: AppStrings.settingsThemeMode.tr,
              valueText: currentText,
              onTap: () => _openThemeSheet(context, settings),
            );
          }),
          _buildRowDivider(),
          _buildSettingsRowItem(
            icon: Icons.point_of_sale_rounded,
            title: AppStrings.cashierAssistantTitle.tr,
            onTap: () {
              HapticFeedback.lightImpact();
              Get.toNamed(AppRoutes.cafeCashierCounter);
            },
          ),
        ],
      ),
    );
  }

  // ── 3. TTS AUDIO CARD (CLEAN SLIDER ONLY) ─────────────────────────────────
  Widget _buildTtsCard(SettingsController settings, BisindoTtsService tts) {
    final isDark = AppColors.isDark;
    final buttonFg = isDark ? AppColors.darkCanvas : AppColors.textOnDark;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      AppStrings.settingsTtsSpeed.tr,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.settingsTtsSpeedDesc.tr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => Text(
                  '${settings.ttsSpeed.value.toStringAsFixed(2)}x',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: AppColors.secondary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.secondary,
                overlayColor: AppColors.secondary.withValues(alpha: 0.14),
              ),
              child: Slider(
                value: settings.ttsSpeed.value,
                min: 0.5,
                max: 1.5,
                divisions: 8,
                label: '${settings.ttsSpeed.value.toStringAsFixed(2)}x',
                onChanged: (val) => settings.setTtsSpeed(val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => settings.testTtsVoice(),
            icon: Icon(
              Icons.play_circle_fill_rounded,
              size: 20,
              color: buttonFg,
            ),
            label: Text(
              AppStrings.settingsTestVoice.tr,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: buttonFg,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: buttonFg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. VIDEO SPEED CARD (CLEAN SLIDER — ZERO CRAMPED CHIPS) ───────────────
  Widget _buildVideoCard(BuildContext context, SettingsController settings) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.slow_motion_video_rounded,
                  size: 20,
                  color: AppColors.matcha,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      AppStrings.settingsVideoSpeed.tr,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.settingsVideoSpeedDesc.tr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => Text(
                  '${settings.videoSpeed.value.toStringAsFixed(2)}x',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.matcha,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: AppColors.matcha,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.matcha,
                overlayColor: AppColors.matcha.withValues(alpha: 0.14),
              ),
              child: Slider(
                value: settings.videoSpeed.value.clamp(0.5, 1.5),
                min: 0.5,
                max: 1.5,
                divisions: 4,
                label: '${settings.videoSpeed.value.toStringAsFixed(2)}x',
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  settings.setVideoSpeed(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. STORAGE & CONNECTION GROUP CARD ────────────────────────────────────
  Widget _buildStorageConnectionCard(
    BuildContext context,
    SignLanguageCacheService cacheService,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  AppStrings.settingsOfflineStorage.tr,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.settingsOfflineStorageDesc.tr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.borderSoft.withValues(alpha: 0.7),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          _buildSettingsRowItem(
            icon: Icons.cloud_done_rounded,
            iconColor: AppColors.matcha,
            title: AppStrings.settingsSupabaseConnection.tr,
            valueText: 'Terhubung',
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _buildSettingsRowItem(
            icon: Icons.school_outlined,
            title: AppStrings.settingsGuideTitle.tr,
            onTap: () {
              HapticFeedback.lightImpact();
              Get.offAllNamed(AppRoutes.onboarding1);
            },
          ),
          _buildRowDivider(),
          _buildSettingsRowItem(
            icon: Icons.info_outline_rounded,
            title: AppStrings.settingsAboutVersion.tr,
            valueText: 'v2.3.0',
            onTap: () => _showAboutAppDialog(context),
          ),
        ],
      ),
    );
  }

  // ── REUSABLE CLEAN MINIMALIST ROW ITEM ────────────────────────────────────
  Widget _buildSettingsRowItem({
    required IconData icon,
    required String title,
    String? valueText,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title ${valueText ?? ""}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.secondary).withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(11),
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
                  child: Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (valueText != null) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    flex: 0,
                    child: Text(
                      valueText,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted.withValues(alpha: 0.75),
                ),
              ],
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 1.2),
        ),
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
