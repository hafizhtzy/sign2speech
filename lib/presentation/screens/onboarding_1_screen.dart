import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/services/bisindo_classifier_service.dart';
import '../widgets/onboarding_selection_cards.dart';

/// Unified 5-Step Modern Onboarding Experience with zero dead space.
/// Features:
/// 1. Top Bar: Back / Language Toggle, Skip button, and an edge-to-edge
///    5-segment progress bar filling in real time with finger gesture drag.
/// 2. Slide 1: Large illustrated hero character with ambient warm radial glow.
/// 3. Slide 2: Interactive Hero Showcase: Voice AI soundwave & 3D Camera.
/// 4. Slide 3: Interactive Hero Showcase: Artisanal cafe order ticket & POS card.
/// 5. Slide 4: Role Selection (Teman Tuli / Teman Dengar) with 3D Popout Cards.
/// 6. Slide 5: Sign Language Selection (BISINDO / SIBI) with 3D Popout Cards.
/// 7. Bottom Bar: Sticky full-width stadium pill button at the bottom.
class Onboarding1Screen extends StatefulWidget {
  final int initialPage;

  const Onboarding1Screen({super.key, this.initialPage = 0});

  @override
  State<Onboarding1Screen> createState() => _Onboarding1ScreenState();
}

class _Onboarding1ScreenState extends State<Onboarding1Screen> {
  static const int _totalPages = 5;

  late PageController _pageController;
  late int _currentPage;
  String _selectedRole = 'Teman Tuli';
  String _selectedSignLanguage = 'BISINDO';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, _totalPages - 1);
    _pageController = PageController(initialPage: _currentPage);
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      _selectedRole = settings.selectedRole.value;
      _selectedSignLanguage = settings.selectedSignLanguage.value;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      await settings.setRole(_selectedRole);
      await settings.setSignLanguage(_selectedSignLanguage);
      await settings.completeOnboarding();
    }
    if (Get.isRegistered<SignLanguageController>()) {
      final signCtrl = Get.find<SignLanguageController>();
      signCtrl.setModel(
        _selectedSignLanguage == 'BISINDO'
            ? SignLanguageModelType.bisindo
            : SignLanguageModelType.sibi,
      );
    }
    Get.offAllNamed(AppRoutes.mainShell);
  }

  Future<void> _nextPage() async {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _finishOnboarding();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleSkip() async {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      // Jump straight to quick personalization (Pilih Peran)
      await _pageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            children: [
              // ── Top Header: Back / Language, Skip & Real-time Gesture Progress Bar ──
              _buildTopHeader(isDark),

              // ── Slide Content PageView ──────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildSlideContainer(
                      visual: _buildSlide1Visual(isDark),
                      title: AppStrings.onboarding1Title.tr,
                      description: AppStrings.onboarding1Desc.tr,
                    ),
                    _buildSlideContainer(
                      visual: _buildSlide2Visual(isDark),
                      title: AppStrings.onboarding2Title.tr,
                      description: AppStrings.onboarding2Desc.tr,
                      addTopBreathingRoom: true,
                    ),
                    _buildSlideContainer(
                      visual: _buildSlide3Visual(isDark),
                      title: AppStrings.onboarding3Title.tr,
                      description: AppStrings.onboarding3Desc.tr,
                      addTopBreathingRoom: true,
                    ),
                    OnboardingRoleStepContent(
                      selectedRole: _selectedRole,
                      onSelectRole: (role) {
                        setState(() => _selectedRole = role);
                        if (Get.isRegistered<SettingsController>()) {
                          Get.find<SettingsController>().setRole(role);
                        }
                      },
                    ),
                    OnboardingSignLanguageStepContent(
                      selectedLanguage: _selectedSignLanguage,
                      onSelectLanguage: (lang) {
                        setState(() => _selectedSignLanguage = lang);
                        if (Get.isRegistered<SettingsController>()) {
                          Get.find<SettingsController>().setSignLanguage(lang);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ── Bottom Action Button (Full-width Sleek Pill) ───────────────
              _buildBottomButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header: Back/Language, Skip & Real-time Segmented Progress Track ─────
  Widget _buildTopHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final double page =
            _pageController.hasClients && _pageController.page != null
            ? _pageController.page!
            : _currentPage.toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row above the line: Back button / Language & Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    // Back Button if page > 0.15, otherwise Language Selector Chip
                    if (page > 0.15)
                      IconButton(
                        onPressed: _prevPage,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.ink,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 22,
                        tooltip: 'Kembali',
                      )
                    else
                      _buildLanguageChip(isDark),

                    const Spacer(),

                    // "Lewati" (Skip) text button
                    TextButton(
                      onPressed: _handleSkip,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.skip.tr,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Edge-to-Edge 5-Segment Progress Track that fills in real time with gesture
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 4,
                width: double.infinity,
                child: Row(
                  children: List.generate(_totalPages, (index) {
                    final double segmentFill = index == 0
                        ? 1.0
                        : (page - (index - 1)).clamp(0.0, 1.0);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: segmentFill,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  // ── Language Toggle Pill (ID / EN) ──────────────────────────────────────────
  Widget _buildLanguageChip(bool isDark) {
    if (!Get.isRegistered<SettingsController>()) {
      return const SizedBox.shrink();
    }
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final currentLang = settings.selectedAppLanguage.value;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          settings.setAppLanguage(currentLang == 'en' ? 'id' : 'en');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLang == 'en' ? '🇺🇸 EN' : '🇮🇩 ID',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.muted),
            ],
          ),
        ),
      );
    });
  }

  // ── Slide Wrapper with Defensive Anti-Overflow Scroll ─────────────────────
  Widget _buildSlideContainer({
    required Widget visual,
    required String title,
    required String description,
    bool addTopBreathingRoom = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double topPadding = addTopBreathingRoom
            ? (constraints.maxHeight * 0.07).clamp(24.0, 56.0)
            : 4.0;
        const double bottomPadding = 4.0;
        final double minContentHeight =
            (constraints.maxHeight - topPadding - bottomPadding).clamp(
              0.0,
              double.infinity,
            );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Visual Artwork Section (expands generously)
                visual,

                // Bottom Text Hierarchy Section
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          fontSize: 25,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.muted,
                            height: 1.45,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bottom Action Button: Full-width Dark Stadium Pill ─────────────────────
  Widget _buildBottomButton(bool isDark) {
    final isLast = _currentPage >= _totalPages - 1;
    final foregroundColor = isDark
        ? AppColors.darkCanvas
        : AppColors.textOnDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor: foregroundColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: .center,
            children: [
              Flexible(
                child: Text(
                  isLast ? AppStrings.startUsingApp.tr : AppStrings.next.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: foregroundColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 18,
                color: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SLIDE 1: Large Expressive Illustrated Character with Ambient Radial Glow ──
  Widget _buildSlide1Visual(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final visualHeight = (screenHeight * 0.46).clamp(320.0, 420.0);

        return SizedBox(
          height: visualHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft Warm Radial Ambient Glow (ensures high contrast in Light & Dark)
              Container(
                width: visualHeight * 0.88,
                height: visualHeight * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark
                          ? AppColors.secondary.withValues(alpha: 0.24)
                          : AppColors.secondary.withValues(alpha: 0.12)),
                      Colors.transparent,
                    ],
                    stops: const [0.38, 1.0],
                  ),
                ),
              ),

              // 2. Large Hero Character Illustration (Clean cutout, large & prominent)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Image.asset(
                    AppAssets.onboardingHeroChar,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 3. Floating Accent Pill Left: [📷 Kamera AI Real-time]
              Positioned(
                left: 6,
                top: visualHeight * 0.32,
                child: _buildFloatingHeroChip(
                  isDark: isDark,
                  icon: Icons.camera_alt_outlined,
                  label: AppStrings.onboardingChipCamera.tr,
                ),
              ),

              // 4. Floating Accent Pill Right: [👋 BISINDO & SIBI]
              Positioned(
                right: 6,
                top: visualHeight * 0.48,
                child: _buildFloatingHeroChip(
                  isDark: isDark,
                  icon: Icons.sign_language_rounded,
                  label: AppStrings.onboardingChipSign.tr,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── SLIDE 2: Interactive Hero Showcase (Kamera AI & Suara Lisan Dua Arah) ──
  Widget _buildSlide2Visual(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final visualHeight = (screenHeight * 0.48).clamp(340.0, 430.0);
        final cardMaxWidth = (constraints.maxWidth * 0.80).clamp(250.0, 330.0);

        return SizedBox(
          height: visualHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient warm circular glow
              Container(
                width: visualHeight * 0.90,
                height: visualHeight * 0.90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark
                          ? AppColors.secondary.withValues(alpha: 0.22)
                          : AppColors.secondary.withValues(alpha: 0.12)),
                      Colors.transparent,
                    ],
                    stops: const [0.38, 1.0],
                  ),
                ),
              ),

              // Scattered Diamond Sparkles
              Positioned(
                top: 18,
                right: 24,
                child: _buildSparkleWidget(
                  size: 20,
                  color: isDark ? AppColors.darkSecondary : AppColors.amber,
                ),
              ),
              Positioned(
                bottom: 24,
                left: 18,
                child: _buildSparkleWidget(
                  size: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.secondary,
                ),
              ),

              // 1. Top-Left Floating Speech Dialogue Bubble (Barista)
              Positioned(
                left: 8,
                top: visualHeight * 0.04,
                child: Container(
                  width: cardMaxWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : AppColors.surface)
                        .withValues(alpha: 0.96),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                      bottomLeft: Radius.circular(6),
                    ),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.07,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.record_voice_over_rounded,
                                  size: 12,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppStrings.onboardingSlide2CashierVoice.tr,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Mini animated soundwave bars
                          Row(
                            children: List.generate(4, (i) {
                              final heights = [8.0, 15.0, 11.0, 7.0];
                              return Container(
                                width: 2.5,
                                height: heights[i],
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        AppStrings.onboardingSlide2VoiceGreeting.tr,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontSize: 12.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Center Hero 3D Camera / Vision Showcase
              Positioned(
                top: visualHeight * 0.33,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Elevated 3D Camera Visual
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkBgSurface
                            : AppColors.bgSurface,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(
                              alpha: isDark ? 0.40 : 0.18,
                            ),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppAssets.camera3d,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 50,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Live AI Gesture Recognition Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withValues(alpha: isDark ? 0.92 : 0.96),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.14,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 15,
                            color: isDark ? AppColors.darkCanvas : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.onboardingSlide2RealtimeDetection.tr,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.darkCanvas
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom-Right Floating Translation Card (Teman Tuli Response)
              Positioned(
                right: 8,
                bottom: visualHeight * 0.03,
                child: Container(
                  width: cardMaxWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : AppColors.surface)
                        .withValues(alpha: 0.96),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(6),
                    ),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.07,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: AppColors.matcha,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            AppStrings.onboardingSlide2VoiceTranslation.tr,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.0,
                              color: AppColors.matcha,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.volume_up_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.onboardingSlide2VoiceSample.tr,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontSize: 12.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── SLIDE 3: Interactive Hero Showcase (Katalog & Komunitas Kafe Inklusif) ──
  Widget _buildSlide3Visual(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final visualHeight = (screenHeight * 0.48).clamp(340.0, 430.0);
        final cardMaxWidth = (constraints.maxWidth * 0.80).clamp(250.0, 330.0);

        return SizedBox(
          height: visualHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft warm radial glow
              Container(
                width: visualHeight * 0.90,
                height: visualHeight * 0.90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark
                          ? AppColors.secondary.withValues(alpha: 0.22)
                          : AppColors.secondary.withValues(alpha: 0.12)),
                      Colors.transparent,
                    ],
                    stops: const [0.38, 1.0],
                  ),
                ),
              ),

              // Scattered Sparkles
              Positioned(
                top: 20,
                left: 20,
                child: _buildSparkleWidget(
                  size: 20,
                  color: isDark ? AppColors.darkSecondary : AppColors.amber,
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: _buildSparkleWidget(
                  size: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.secondary,
                ),
              ),

              // 1. Top-Right Floating Order Ticket Card
              Positioned(
                right: 8,
                top: visualHeight * 0.04,
                child: Container(
                  width: cardMaxWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : AppColors.surface)
                        .withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.07,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.onboardingSlide3OrderTable.tr,
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.matcha.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppStrings.onboardingSlide3OrderReady.tr,
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 9.5,
                                color: AppColors.matcha,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        AppStrings.onboardingMockupOrder.tr,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Center Hero Artisanal Coffee Showcase with Composition Breakdown
              Positioned(
                top: visualHeight * 0.32,
                child: Container(
                  width: (constraints.maxWidth * 0.88).clamp(270.0, 360.0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : AppColors.surface)
                        .withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        blurRadius: 22,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(
                                alpha: 0.16,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.coffee_rounded,
                              size: 24,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.onboardingSlide3CustomCoffee.tr,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppStrings
                                      .onboardingSlide3CustomCoffeeDesc
                                      .tr,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Composition Pills
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildCompositionChip('Microfoam 35%', isDark),
                          _buildCompositionChip('Steamed Oat 35%', isDark),
                          _buildCompositionChip('Espresso 30%', isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Bottom-Left Floating Cashier Assistant Action Card
              Positioned(
                left: 8,
                bottom: visualHeight * 0.03,
                child: Container(
                  width: cardMaxWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: isDark ? 0.92 : 0.96),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.14,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.onboardingSlide3CashierShortcut.tr,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.0,
                                color: isDark
                                    ? AppColors.darkCanvas
                                    : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              AppStrings.onboardingSlide3CashierShortcutDesc.tr,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10.5,
                                color:
                                    (isDark
                                            ? AppColors.darkCanvas
                                            : Colors.white)
                                        .withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helper: 4-Point Diamond Sparkle ───────────────────────────────────────
  Widget _buildSparkleWidget({required double size, required Color color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }

  // ── Helper: Floating Hero Chip ─────────────────────────────────────────────
  Widget _buildFloatingHeroChip({
    required bool isDark,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(
          alpha: 0.92,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.border).withValues(
            alpha: 0.85,
          ),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Composition Chip ───────────────────────────────────────────────
  Widget _buildCompositionChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 9.5,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

/// 4-point diamond starburst custom painter for subtle cafe aesthetic sparkles.
class _SparklePainter extends CustomPainter {
  final Color color;

  const _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}
