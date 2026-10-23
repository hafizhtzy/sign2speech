import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';

/// HajiCare-Inspired Interactive Onboarding Experience.
/// Features a fluid 3-slide PageView, animated progress pill indicator,
/// instant language switcher, 2D editorial illustrations, and smooth role setup transition.
class Onboarding1Screen extends StatefulWidget {
  final int initialPage;

  const Onboarding1Screen({
    super.key,
    this.initialPage = 0,
  });

  @override
  State<Onboarding1Screen> createState() => _Onboarding1ScreenState();
}

class _Onboarding1ScreenState extends State<Onboarding1Screen> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Get.toNamed(AppRoutes.chooseRole);
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            children: [
              // ── Top Header: Step Indicator & Language Switcher & Skip ────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dynamic Animated Progress Indicator (HajiCare Pill Style)
                    Row(
                      children: List.generate(3, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 30 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // Actions: Language Toggle & Skip
                    Row(
                      children: [
                        _buildLanguageToggle(),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Get.toNamed(AppRoutes.chooseRole);
                          },
                          child: Text(
                            AppStrings.skip.tr,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                    // Slide 1: Welcome & Inclusive Vision
                    _buildSlide(
                      imageAsset: AppAssets.onboardingWoman,
                      title: AppStrings.onboarding1Title.tr,
                      description: AppStrings.onboarding1Desc.tr,
                      chips: [
                        _FeatureChipData(
                          label: 'Kamera AI Real-time',
                          icon: Icons.camera_alt_outlined,
                          color: AppColors.secondary,
                        ),
                        _FeatureChipData(
                          label: 'Suara Alami Indonesia',
                          icon: Icons.record_voice_over_outlined,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),

                    // Slide 2: Two-way Offline Signs
                    _buildSlide(
                      imageAsset: AppAssets.onboardingMan,
                      title: AppStrings.onboarding2Title.tr,
                      description: AppStrings.onboarding2Desc.tr,
                      chips: [
                        _FeatureChipData(
                          label: 'Offline-First Siap Pakai',
                          icon: Icons.offline_pin_outlined,
                          color: AppColors.matcha,
                        ),
                        _FeatureChipData(
                          label: 'Aman & Privat On-Device',
                          icon: Icons.lock_outline_rounded,
                          color: AppColors.matcha,
                        ),
                      ],
                    ),

                    // Slide 3: Smart Cashier & 180 Flip Display
                    _buildSlide(
                      customIllustration: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.point_of_sale_rounded,
                                    size: 40,
                                    color: AppColors.amber,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Icon(
                                  Icons.sync_alt_rounded,
                                  size: 26,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 18),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.screen_rotation_rounded,
                                    size: 40,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'Smart Cashier & 180° Flip Display',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: AppStrings.onboarding3Title.tr,
                      description: AppStrings.onboarding3Desc.tr,
                      chips: [
                        _FeatureChipData(
                          label: AppStrings.onboardingBadgePresets.tr,
                          icon: Icons.dialpad_rounded,
                          color: AppColors.amber,
                        ),
                        _FeatureChipData(
                          label: AppStrings.onboardingBadgeFlipScreen.tr,
                          icon: Icons.screen_rotation_rounded,
                          color: AppColors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Bottom Action Bar ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    if (_currentPage > 0) ...[
                      SizedBox(
                        width: 90,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _prevPage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: BorderSide(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                            shape: const StadiumBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AppPrimaryButton(
                        label: _currentPage >= 1
                            ? AppStrings.startNow.tr
                            : AppStrings.next.tr,
                        icon: _currentPage >= 1
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: _nextPage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    if (!Get.isRegistered<SettingsController>()) {
      return const SizedBox.shrink();
    }
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final isEn = settings.selectedAppLanguage.value == 'en';
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          settings.setAppLanguage(isEn ? 'id' : 'en');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn ? '🇬🇧 EN' : '🇮🇩 ID',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.swap_horiz, size: 14, color: AppColors.muted),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSlide({
    String? imageAsset,
    Widget? customIllustration,
    required String title,
    required String description,
    required List<_FeatureChipData> chips,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2D Editorial Illustration Frame
          Center(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: customIllustration ??
                  (imageAsset != null
                      ? Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          cacheWidth: 500,
                        )
                      : const SizedBox.shrink()),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Feature Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((chip) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chip.icon, size: 16, color: chip.color),
                    const SizedBox(width: 8),
                    Text(
                      chip.label,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FeatureChipData {
  final String label;
  final IconData icon;
  final Color color;

  const _FeatureChipData({
    required this.label,
    required this.icon,
    required this.color,
  });
}
