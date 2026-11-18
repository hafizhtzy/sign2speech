import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_layout.dart';

/// Home-inspired 3D Popout selection card used across Onboarding & standalone
/// Role / Sign Language selection screens.
/// Features a floating 3D popout object breaking out of the top-left edge,
/// smooth elevation/color transition on selection, high-contrast Light & AMOLED
/// Dark Mode tokens, and tactile press feedback.
class PopoutSelectionCard extends StatefulWidget {
  final String tag;
  final String title;
  final String? secondaryTitle;
  final String description;
  final String? imageAsset;
  final IconData? icon3d;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const PopoutSelectionCard({
    super.key,
    required this.tag,
    required this.title,
    this.secondaryTitle,
    required this.description,
    this.imageAsset,
    this.icon3d,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<PopoutSelectionCard> createState() => _PopoutSelectionCardState();
}

class _PopoutSelectionCardState extends State<PopoutSelectionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final isSelected = widget.isSelected;

    // Active card uses rich espresso/caramel in light mode and elevated bordered
    // surface with warm glow in AMOLED dark mode.
    final Color cardBg = isSelected
        ? (isDark ? AppColors.darkBgSurface : widget.accentColor)
        : AppColors.surface;
    final Color primaryTextColor = isSelected
        ? (isDark ? AppColors.darkInk : AppColors.textOnDark)
        : AppColors.ink;
    final Color secondaryTextColor = isSelected
        ? (isDark
              ? AppColors.darkMuted
              : AppColors.textOnDark.withValues(alpha: 0.84))
        : AppColors.muted;
    final Color tagColor = isSelected
        ? (isDark
              ? AppColors.darkSecondary
              : AppColors.textOnDark.withValues(alpha: 0.82))
        : widget.accentColor;
    final Color borderColor = isSelected
        ? (isDark ? widget.accentColor : Colors.transparent)
        : AppColors.border;

    return Semantics(
      selected: isSelected,
      button: true,
      label: widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Unique Asymmetric Editorial Card (Larger Top-Left Sweep)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 68, 22, 22),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(48),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(36),
                    ),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(
                                alpha: isSelected ? 0.42 : 0.25,
                              )
                            : (isSelected
                                  ? widget.accentColor.withValues(alpha: 0.24)
                                  : AppColors.lightPrimary.withValues(
                                      alpha: 0.05,
                                    )),
                        blurRadius: isSelected ? 20 : 12,
                        offset: Offset(0, isSelected ? 8 : 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      // Tag Badge
                      Text(
                        '#${widget.tag}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Card Title
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                          fontSize: 22,
                        ),
                      ),

                      // Optional Secondary Subtitle (e.g. full sign language name)
                      if (widget.secondaryTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.secondaryTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkSecondary
                                      : AppColors.textOnDark.withValues(
                                          alpha: 0.90,
                                        ))
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        widget.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: secondaryTextColor,
                          height: 1.4,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Top-Left Pure Transparent Cutout PNG (Zero Background / Border)
                Positioned(
                  top: -32,
                  left: 16,
                  child: IgnorePointer(
                    child: AnimatedScale(
                      scale: isSelected ? 1.07 : 0.98,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      child: widget.imageAsset != null
                          ? SizedBox(
                              width: 96,
                              height: 96,
                              child: Image.asset(
                                widget.imageAsset!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildSculpted3dOrb(
                                      icon:
                                          widget.icon3d ??
                                          Icons.sign_language_rounded,
                                      accent: widget.accentColor,
                                      isSelected: isSelected,
                                      isDark: isDark,
                                    ),
                              ),
                            )
                          : _buildSculpted3dOrb(
                              icon: widget.icon3d ?? Icons.front_hand_rounded,
                              accent: widget.accentColor,
                              isSelected: isSelected,
                              isDark: isDark,
                            ),
                    ),
                  ),
                ),

                // 3. Top-Right Glassmorphic Selection Status Pill
                Positioned(
                  top: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (isDark
                                  ? widget.accentColor
                                  : Colors.white.withValues(alpha: 0.22))
                            : AppColors.bgSurface,
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? widget.accentColor
                                    : Colors.white.withValues(alpha: 0.50))
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  key: const ValueKey('checked'),
                                  size: 20,
                                  color: isDark
                                      ? AppColors.darkCanvas
                                      : AppColors.textOnDark,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  key: const ValueKey('unchecked'),
                                  size: 16,
                                  color: AppColors.muted.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a glossy 3D floating orb medallion with layered depth shadow &
  /// specular top-left sheen for options without a standalone 3D PNG asset.
  Widget _buildSculpted3dOrb({
    required IconData icon,
    required Color accent,
    required bool isSelected,
    required bool isDark,
  }) {
    final Color baseStart = isSelected
        ? Color.lerp(accent, Colors.white, 0.24)!
        : (isDark ? AppColors.darkBgSurface : AppColors.surface);
    final Color baseEnd = isSelected
        ? accent
        : (isDark ? AppColors.darkBorder : AppColors.bgSurface);

    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseStart, baseEnd],
        ),
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.45)
              : AppColors.border,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isSelected ? 0.36 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 34,
          color: isSelected
              ? (isDark ? AppColors.darkCanvas : AppColors.textOnDark)
              : accent,
        ),
      ),
    );
  }
}

/// Vertically centered, responsive Role Selection content (Teman Tuli vs Teman Dengar)
/// styled with Home's 3D popout cards.
class OnboardingRoleStepContent extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onSelectRole;

  const OnboardingRoleStepContent({
    super.key,
    required this.selectedRole,
    required this.onSelectRole,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = context.isLargeScreen;

    final cardDeaf = PopoutSelectionCard(
      tag: AppStrings.roleDeafBadge.tr,
      title: AppStrings.roleDeafTitle.tr,
      description: AppStrings.roleDeafDesc.tr,
      imageAsset: AppAssets.camera3d,
      accentColor: AppColors.primary,
      isSelected: selectedRole == 'Teman Tuli',
      onTap: () => onSelectRole('Teman Tuli'),
    );

    final cardHearing = PopoutSelectionCard(
      tag: AppStrings.roleHearingBadge.tr,
      title: AppStrings.roleHearingTitle.tr,
      description: AppStrings.roleHearingDesc.tr,
      imageAsset: AppAssets.mic3d,
      accentColor: AppColors.secondary,
      isSelected: selectedRole == 'Teman Dengar',
      onTap: () => onSelectRole('Teman Dengar'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double minHeight = (constraints.maxHeight - 24).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  AppStrings.onboardingRoleHeading.tr,
                  textAlign: .center,
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 25,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    AppStrings.chooseRoleSubtitle.tr,
                    textAlign: .center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                if (isLarge)
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      Expanded(child: cardDeaf),
                      const SizedBox(width: 16),
                      Expanded(child: cardHearing),
                    ],
                  )
                else ...[
                  cardDeaf,
                  const SizedBox(height: 16),
                  cardHearing,
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Vertically centered, responsive Sign Language Selection content (BISINDO vs SIBI)
/// styled with Home's 3D popout cards.
class OnboardingSignLanguageStepContent extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onSelectLanguage;

  const OnboardingSignLanguageStepContent({
    super.key,
    required this.selectedLanguage,
    required this.onSelectLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = context.isLargeScreen;

    final cardBisindo = PopoutSelectionCard(
      tag: AppStrings.signBisindoBadge.tr,
      title: 'BISINDO',
      secondaryTitle: AppStrings.signBisindoFullName.tr,
      description: AppStrings.signBisindoDesc.tr,
      imageAsset: AppAssets.roleTemanTuli,
      accentColor: AppColors.primary,
      isSelected: selectedLanguage == 'BISINDO',
      onTap: () => onSelectLanguage('BISINDO'),
    );

    final cardSibi = PopoutSelectionCard(
      tag: AppStrings.signSibiBadge.tr,
      title: 'SIBI',
      secondaryTitle: AppStrings.signSibiFullName.tr,
      description: AppStrings.signSibiDesc.tr,
      imageAsset: AppAssets.roleTemanDengar,
      accentColor: AppColors.secondary,
      isSelected: selectedLanguage == 'SIBI',
      onTap: () => onSelectLanguage('SIBI'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double minHeight = (constraints.maxHeight - 24).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  AppStrings.chooseLangSubtitle.tr,
                  textAlign: .center,
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 25,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    AppStrings.onboardingLangNote.tr,
                    textAlign: .center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                if (isLarge)
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      Expanded(child: cardBisindo),
                      const SizedBox(width: 16),
                      Expanded(child: cardSibi),
                    ],
                  )
                else ...[
                  cardBisindo,
                  const SizedBox(height: 16),
                  cardSibi,
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
