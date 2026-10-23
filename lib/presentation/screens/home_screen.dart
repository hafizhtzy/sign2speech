import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/status_badge.dart';
import '../../features/cashier_assistance/widgets/cashier_assistant_sheet.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _activeQuickPhrase;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();
    final tts = Get.find<BisindoTtsService>();

    return Obx(() {
      // Rebuild dynamically when themeMode changes
      settings.themeMode.value;

      return Scaffold(
        backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ResponsiveContentWrapper(
            maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.sign_language_rounded,
                              size: 22,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.appTitle.tr,
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                AppStrings.appSubtitle.tr,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: settings.selectedSignLanguage.value,
                          variant: BadgeVariant.active,
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(
                          label: settings.selectedRole.value,
                          variant: BadgeVariant.neutral,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Greeting Banner with Left Accent Border
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.homeGreeting.tr,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.homeGreetingDesc.tr,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.waving_hand_rounded,
                          size: 28,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pintasan Kalimat Kasir (Quick Chips) ────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.homeCashierShortcuts.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.homeTapToSpeak.tr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Obx(() {
                final isEn = settings.selectedAppLanguage.value == 'en';
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickOrderChip(
                        tts: tts,
                        isEn: isEn,
                        chipLabel: '☕ Pesan Kopi',
                        spokenPhrase: 'Saya mau pesan kopi',
                        chipLabelEn: '☕ Order Coffee',
                        spokenPhraseEn: 'I would like to order coffee',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOrderChip(
                        tts: tts,
                        isEn: isEn,
                        chipLabel: '🧊 Less Ice',
                        spokenPhrase: 'Tolong esnya sedikit saja ya',
                        chipLabelEn: '🧊 Less Ice',
                        spokenPhraseEn: 'Please give me less ice',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOrderChip(
                        tts: tts,
                        isEn: isEn,
                        chipLabel: '🍯 Kurang Gula',
                        spokenPhrase: 'Tolong kurangi gulanya ya',
                        chipLabelEn: '🍯 Less Sugar',
                        spokenPhraseEn: 'Please make it with less sugar',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOrderChip(
                        tts: tts,
                        isEn: isEn,
                        chipLabel: '💳 Bayar QRIS',
                        spokenPhrase: 'Saya ingin bayar menggunakan QRIS',
                        chipLabelEn: '💳 Pay with QRIS',
                        spokenPhraseEn: 'I want to pay using QRIS',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOrderChip(
                        tts: tts,
                        isEn: isEn,
                        chipLabel: '🛍️ Bawa Pulang',
                        spokenPhrase: 'Tolong dibungkus untuk dibawa pulang',
                        chipLabelEn: '🛍️ Takeaway',
                        spokenPhraseEn: 'Please pack it for takeaway',
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ── Alat Pintar Kasir & Layar Pelanggan ──────────────
              AppCard(
                onTap: () => CashierAssistantSheet.show(context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppStrings.cashierAssistantTitle.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.matcha.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FITUR KASIR',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.matcha,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.cashierAssistantSubtitle.tr,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Mode Penerjemah Utama ────────────────────────────────────
              Text(
                AppStrings.homeMainModes.tr,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              if (context.isLargeScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        title: 'Sign to Speech',
                        subtitle: AppStrings.homeSignToSpeechDesc.tr,
                        tag: AppStrings.homeSignToSpeechBadge.tr,
                        color: AppColors.isDark ? AppColors.surface : AppColors.primary,
                        textColor: AppColors.isDark ? AppColors.ink : AppColors.textOnDark,
                        tagBgColor: AppColors.isDark
                            ? AppColors.paleMist
                            : AppColors.textOnDark.withValues(alpha: 0.14),
                        dividerColor: AppColors.isDark
                            ? AppColors.border
                            : AppColors.textOnDark.withValues(alpha: 0.20),
                        icon: Icons.camera_alt_rounded,
                        onTap: () => Get.toNamed(AppRoutes.signToSpeechCamera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFeatureCard(
                        title: 'Speech to Sign',
                        subtitle: AppStrings.homeSpeechToSignDesc.tr,
                        tag: AppStrings.homeSpeechToSignBadge.tr,
                        color: AppColors.isDark ? AppColors.surface : AppColors.secondary,
                        textColor: AppColors.isDark ? AppColors.ink : AppColors.textOnDark,
                        tagBgColor: AppColors.isDark
                            ? AppColors.secondary.withValues(alpha: 0.16)
                            : AppColors.textOnDark.withValues(alpha: 0.16),
                        dividerColor: AppColors.isDark
                            ? AppColors.border
                            : AppColors.textOnDark.withValues(alpha: 0.25),
                        icon: Icons.mic_rounded,
                        onTap: () => Get.toNamed(AppRoutes.speechToSignMic),
                      ),
                    ),
                  ],
                )
              else ...[
                _buildFeatureCard(
                  title: 'Sign to Speech',
                  subtitle: AppStrings.homeSignToSpeechDesc.tr,
                  tag: AppStrings.homeSignToSpeechBadge.tr,
                  color: AppColors.isDark ? AppColors.surface : AppColors.primary,
                  textColor: AppColors.isDark ? AppColors.ink : AppColors.textOnDark,
                  tagBgColor: AppColors.isDark
                      ? AppColors.paleMist
                      : AppColors.textOnDark.withValues(alpha: 0.14),
                  dividerColor: AppColors.isDark
                      ? AppColors.border
                      : AppColors.textOnDark.withValues(alpha: 0.20),
                  icon: Icons.camera_alt_rounded,
                  onTap: () => Get.toNamed(AppRoutes.signToSpeechCamera),
                ),
                const SizedBox(height: 14),
                _buildFeatureCard(
                  title: 'Speech to Sign',
                  subtitle: AppStrings.homeSpeechToSignDesc.tr,
                  tag: AppStrings.homeSpeechToSignBadge.tr,
                  color: AppColors.isDark ? AppColors.surface : AppColors.secondary,
                  textColor: AppColors.isDark ? AppColors.ink : AppColors.textOnDark,
                  tagBgColor: AppColors.isDark
                      ? AppColors.secondary.withValues(alpha: 0.16)
                      : AppColors.textOnDark.withValues(alpha: 0.16),
                  dividerColor: AppColors.isDark
                      ? AppColors.border
                      : AppColors.textOnDark.withValues(alpha: 0.25),
                  icon: Icons.mic_rounded,
                  onTap: () => Get.toNamed(AppRoutes.speechToSignMic),
                ),
              ],
              const SizedBox(height: 24),

              // Quick Categories Shortcut (Katalog Isyarat Kafe)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.homeCafeCatalog.tr,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.signLibrary),
                    child: Text(
                      AppStrings.homeViewAll.tr,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryPill(
                      'Minuman & Menu',
                      Icons.coffee_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Takaran (Es/Gula)',
                      Icons.tune_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Kasir & Bayar',
                      Icons.point_of_sale_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Sapaan Kafe',
                      Icons.waving_hand_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Bawa Pulang',
                      Icons.shopping_bag_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Recent History Teaser
              Obx(() {
                final recent = history.items.take(2).toList();
                if (recent.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.homeRecentConversation.tr,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.history),
                          child: Text(
                            AppStrings.navHistory.tr,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recent.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onTap: () => Get.toNamed(AppRoutes.history),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.direction.index == 0
                                      ? Icons.sign_language_rounded
                                      : Icons.record_voice_over_rounded,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.translatedContent,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      item.signLanguageType,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
    });
  }

  Widget _buildQuickOrderChip({
    required BisindoTtsService tts,
    required bool isEn,
    required String chipLabel,
    required String spokenPhrase,
    required String chipLabelEn,
    required String spokenPhraseEn,
  }) {
    final activeLabel = isEn ? chipLabelEn : chipLabel;
    final phraseToSpeak = isEn ? spokenPhraseEn : spokenPhrase;
    final langCode = isEn ? 'en-US' : 'id-ID';
    final isActive = _activeQuickPhrase == chipLabel;

    return GestureDetector(
      onTap: () async {
        setState(() {
          _activeQuickPhrase = chipLabel;
        });
        await tts.speak(phraseToSpeak, languageCode: langCode);
        Get.snackbar(
          AppStrings.spokenVoiceSnackbar.tr,
          phraseToSpeak,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: AppColors.textOnDark,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _activeQuickPhrase = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.secondary : AppColors.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          activeLabel,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.textOnDark : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
    required Color textColor,
    required Color tagBgColor,
    required Color dividerColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.isDark ? AppColors.border : Colors.transparent,
          width: 1,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tagBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: textColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w400,
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              // Cafe Ticket Dashed Divider Detail
              LayoutBuilder(
                builder: (context, constraints) {
                  final boxWidth =
                      constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
                  const dashWidth = 5.0;
                  const dashSpace = 4.0;
                  final dashCount =
                      (boxWidth / (dashWidth + dashSpace)).floor().clamp(1, 100);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(dashCount, (_) {
                        return SizedBox(
                          width: dashWidth,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: dividerColor),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Text(
                    AppStrings.startNow.tr,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: textColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String title, IconData icon) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.signLibrary),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
