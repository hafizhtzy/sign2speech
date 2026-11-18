import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/auth/controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../features/customer/screens/customer_checkout_screen.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/status_badge.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/models/sign_language_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();

    return Obx(() {
      // Rebuild dynamically when themeMode or auth state changes
      settings.themeMode.value;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        auth.currentProfile.value;
        auth.sessionState.value;
      }

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          body: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Dual-layer Organic Wave Header (Avatar, App Logo, BISINDO/SIBI & POS Actions)
                  _buildWaveHeader(context, settings),

                // 2. Responsive Content Container
                ResponsiveContentWrapper(
                  maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search Bar below the wave
                      _buildQuickSearchBar(context),
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
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        AppStrings.appTitle.tr,
                                        maxLines: 1,
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                      Obx(
                                        () => StatusBadge(
                                          label: settings.selectedRole.value,
                                          variant: BadgeVariant.neutral,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
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
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.25,
                                  ),
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

                      // ── Alat Pintar Kasir (CASHIER) / Admin / Order Menu & Meja (Guest & CUSTOMER) ──
                      Builder(
                        builder: (context) {
                          final auth = Get.isRegistered<AuthController>()
                              ? Get.find<AuthController>()
                              : null;
                          final isCashierRole =
                              auth != null && auth.isAuthenticated && auth.isCashier;
                          final isAdminRole =
                              auth != null && auth.isAuthenticated && auth.isAdmin;

                          final cardTitle = isCashierRole
                              ? AppStrings.cashierAssistantTitle.tr
                              : isAdminRole
                                  ? AppStrings.adminDashboardTitle.tr
                                  : AppStrings.customerOrderCardTitle.tr;
                          final cardSubtitle = isCashierRole
                              ? AppStrings.cashierAssistantSubtitle.tr
                              : isAdminRole
                                  ? AppStrings.authRoleAdmin.tr
                                  : AppStrings.customerOrderCardSubtitle.tr;
                          final cardIcon = isCashierRole
                              ? Icons.point_of_sale_rounded
                              : isAdminRole
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.local_cafe_rounded;

                          return AppCard(
                            key: const Key('home_order_or_cashier_card'),
                            onTap: () {
                              if (isCashierRole) {
                                Get.toNamed(AppRoutes.cafeCashierCounter);
                              } else if (isAdminRole) {
                                Get.toNamed(AppRoutes.adminDashboard);
                              } else if (auth != null && !auth.isAuthenticated) {
                                Get.toNamed(AppRoutes.login);
                              } else {
                                final hasRoute = Get.routeTree.routes.any(
                                  (r) => r.name == AppRoutes.customerCheckout,
                                );
                                if (hasRoute) {
                                  Get.toNamed(AppRoutes.customerCheckout);
                                } else {
                                  Get.to(
                                    () => const CustomerCheckoutScreen(),
                                    routeName: AppRoutes.customerCheckout,
                                    transition: Transition.rightToLeft,
                                  );
                                }
                              }
                            },
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    cardIcon,
                                    color: AppColors.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cardTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.titleMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cardSubtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          );
                        },
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
                              child: _buildPopoutFeatureCard(
                                title: 'Sign to Speech',
                                subtitle: AppStrings.homeSignToSpeechDesc.tr,
                                tag: AppStrings.homeSignToSpeechBadge.tr,
                                imageAsset:
                                    'assets/komponen_img/3d_camera_card.png',
                                color: AppColors.isDark
                                    ? AppColors.surface
                                    : AppColors.primary,
                                textColor: AppColors.isDark
                                    ? AppColors.ink
                                    : AppColors.textOnDark,
                                topRightIcon: Icons.auto_awesome_rounded,
                                onTap: () =>
                                    Get.toNamed(AppRoutes.signToSpeechCamera),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPopoutFeatureCard(
                                title: 'Speech to Sign',
                                subtitle: AppStrings.homeSpeechToSignDesc.tr,
                                tag: AppStrings.homeSpeechToSignBadge.tr,
                                imageAsset:
                                    'assets/komponen_img/3d_mic_card.png',
                                color: AppColors.isDark
                                    ? AppColors.surface
                                    : AppColors.secondary,
                                textColor: AppColors.isDark
                                    ? AppColors.ink
                                    : AppColors.textOnDark,
                                topRightIcon: Icons.graphic_eq_rounded,
                                onTap: () =>
                                    Get.toNamed(AppRoutes.speechToSignMic),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildPopoutFeatureCard(
                          title: 'Sign to Speech',
                          subtitle: AppStrings.homeSignToSpeechDesc.tr,
                          tag: AppStrings.homeSignToSpeechBadge.tr,
                          imageAsset: 'assets/komponen_img/3d_camera_card.png',
                          color: AppColors.isDark
                              ? AppColors.surface
                              : AppColors.primary,
                          textColor: AppColors.isDark
                              ? AppColors.ink
                              : AppColors.textOnDark,
                          topRightIcon: Icons.auto_awesome_rounded,
                          onTap: () =>
                              Get.toNamed(AppRoutes.signToSpeechCamera),
                        ),
                        const SizedBox(height: 10),
                        _buildPopoutFeatureCard(
                          title: 'Speech to Sign',
                          subtitle: AppStrings.homeSpeechToSignDesc.tr,
                          tag: AppStrings.homeSpeechToSignBadge.tr,
                          imageAsset: 'assets/komponen_img/3d_mic_card.png',
                          color: AppColors.isDark
                              ? AppColors.surface
                              : AppColors.secondary,
                          textColor: AppColors.isDark
                              ? AppColors.ink
                              : AppColors.textOnDark,
                          topRightIcon: Icons.graphic_eq_rounded,
                          onTap: () => Get.toNamed(AppRoutes.speechToSignMic),
                        ),
                      ],
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
                                Expanded(
                                  child: Text(
                                    AppStrings.homeRecentConversation.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.history),
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.translatedContent,
                                              style: AppTypography.titleSmall
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink,
                                                  ),
                                            ),
                                            Text(
                                              item.signLanguageType,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
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
                      const SizedBox(height: 104),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }

  Widget _buildPopoutFeatureCard({
    required String title,
    required String subtitle,
    required String tag,
    required String imageAsset,
    required Color color,
    required Color textColor,
    required IconData topRightIcon,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark;
    final buttonTextColor = color == AppColors.surface
        ? AppColors.primary
        : color;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Card Container
          Material(
            color: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: isDark ? AppColors.border : Colors.transparent,
                width: 1,
              ),
            ),
            elevation: 0,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.08 : 0.24),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 84, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tag Code / Type
                      Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: textColor.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Main Title & Action Button Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withValues(alpha: 0.85),
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Unique Curved White Pill Button (Reference style)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                bottomLeft: Radius.circular(22),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppStrings.homeActionStart.tr,
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: buttonTextColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: buttonTextColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Top-Left 3D Popout Object (Camera 3D / Mic 3D)
          Positioned(
            top: -28,
            left: 14,
            child: IgnorePointer(
              child: SizedBox(
                width: 108,
                height: 108,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),

          // 3. Top-Right Glassmorphic Icon Pill
          Positioned(
            top: 14,
            right: 16,
            child: IgnorePointer(
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(topRightIcon, color: textColor, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DUAL-LAYER ORGANIC WAVE HEADER ──────────────────────────────────────────
  Widget _buildWaveHeader(BuildContext context, SettingsController settings) {
    final topPadding = MediaQuery.of(context).padding.top;
    const bodyH = 114.0;
    final headerHeight = topPadding + bodyH;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Organic S-Wave Background (Matching Reference Image 2 Geometry)
          Positioned.fill(
            child: CustomPaint(
              painter: DualWaveHeaderPainter(
                topPadding: topPadding,
                backWaveColor: isDark
                    ? AppColors.darkBgSurface
                    : AppColors.secondary.withValues(alpha: 0.35),
                frontWaveColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.primary,
                isDark: isDark,
              ),
            ),
          ),

          // 2. Left: User Profile Avatar Nested Under the Left Arch Pocket
          Positioned(
            top: topPadding + 30.0,
            left: 24,
            child: _buildAvatarButton(context, settings),
          ),

          // 3. Center: Sign2Speech Squircle Tile Inside the Central Wave Belly
          Positioned(
            top: topPadding + 24.0,
            left: 0,
            right: 0,
            child: Center(child: _buildAppLogoTile(context)),
          ),

          // 4. Right: BISINDO/SIBI Selector Cleanly Inside the Right Espresso Area
          Positioned(
            top: topPadding + 28.0,
            right: 22,
            child: _buildRightActionButtons(context, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarButton(BuildContext context, SettingsController settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Profil Pengguna dan Pengaturan',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(AppRoutes.settings);
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDark ? AppColors.darkBgSurface : AppColors.primary,
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.secondary.withValues(alpha: 0.40),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    AppAssets.roleTemanTuli,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.matcha,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCanvas : AppColors.canvas,
                      width: 2.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogoTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Logo Sign2Speech',
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.11),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.18),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Transform.scale(
            scale: 1.32,
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.06),
              colorBlendMode: BlendMode.plus,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.sign_language_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightActionButtons(
    BuildContext context,
    SettingsController settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Pilih model bahasa isyarat',
      button: true,
      child: GestureDetector(
        onTap: () => _showSignLanguageDialog(context, settings),
        child: Container(
          height: 42,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.22),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sign_language_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Obx(
                () => Text(
                  settings.selectedSignLanguage.value,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── QUICK SEARCH BAR (BELOW THE WAVE) ───────────────────────────────────────
  Widget _buildQuickSearchBar(BuildContext context) {
    return Semantics(
      label: 'Bilah pencarian cepat isyarat dan menu kafe',
      button: true,
      child: GestureDetector(
        onTap: () => _showQuickSearchSheet(context),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.secondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.homeWaveSearchHint.tr,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SIGN LANGUAGE MODEL SELECTION DIALOG (CENTER) ───────────────────────────
  void _showSignLanguageDialog(
    BuildContext context,
    SettingsController settings,
  ) {
    HapticFeedback.lightImpact();
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.45 : 0.14,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sign_language_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.homeSelectSignLanguageDialog.tr,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.homeSelectSignLanguageDesc.tr,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: BISINDO
              Obx(() {
                final isSelected =
                    settings.selectedSignLanguage.value == 'BISINDO';
                return _buildSignOptionTile(
                  title: AppStrings.homeSignBisindoTitle.tr,
                  badge: 'ALAMI • 2 TANGAN',
                  description: AppStrings.homeSignBisindoDesc.tr,
                  isSelected: isSelected,
                  badgeColor: AppColors.secondary,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await settings.setSignLanguage('BISINDO');
                    if (Get.isRegistered<SignLanguageController>()) {
                      Get.find<SignLanguageController>().switchModel(
                        SignLanguageModel.bisindo,
                      );
                    }
                    Get.back();
                    AppSnackbar.success(
                      title: 'Model Isyarat Diperbarui',
                      message: 'Model aktif sekarang: BISINDO',
                      duration: const Duration(seconds: 2),
                    );
                  },
                );
              }),
              const SizedBox(height: 12),

              // Option 2: SIBI
              Obx(() {
                final isSelected =
                    settings.selectedSignLanguage.value == 'SIBI';
                return _buildSignOptionTile(
                  title: AppStrings.homeSignSibiTitle.tr,
                  badge: 'BAKU • 1 TANGAN',
                  description: AppStrings.homeSignSibiDesc.tr,
                  isSelected: isSelected,
                  badgeColor: AppColors.amber,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await settings.setSignLanguage('SIBI');
                    if (Get.isRegistered<SignLanguageController>()) {
                      Get.find<SignLanguageController>().switchModel(
                        SignLanguageModel.sibi,
                      );
                    }
                    Get.back();
                    AppSnackbar.success(
                      title: 'Model Isyarat Diperbarui',
                      message: 'Model aktif sekarang: SIBI',
                      duration: const Duration(seconds: 2),
                    );
                  },
                );
              }),
              const SizedBox(height: 20),

              // Close button
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Tutup',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOptionTile({
    required String title,
    required String badge,
    required String description,
    required bool isSelected,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.bgSurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.muted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: AppColors.onPrimary,
                          size: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: AppTypography.labelSmall.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
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

  // ── QUICK SEARCH MODAL BOTTOM SHEET ─────────────────────────────────────────
  void _showQuickSearchSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final searchCtrl = TextEditingController();
    final history = Get.find<HistoryController>();

    final signWords = <Map<String, String>>[
      {'word': 'Halo', 'desc': 'Sapaan ramah kafe'},
      {'word': 'Kopi', 'desc': 'Kosakata dasar kafe'},
      {'word': 'Terima Kasih', 'desc': 'Ucapan terima kasih'},
      {'word': 'Air', 'desc': 'Air putih / mineral'},
      {'word': 'Susu', 'desc': 'Susu segar / oat milk'},
      {'word': 'Mandi', 'desc': 'Aktivitas harian'},
      {'word': 'Minum', 'desc': 'Pesanan minuman'},
      {'word': 'Tuli', 'desc': 'Budaya & Komunitas Tuli'},
      {'word': 'Makan', 'desc': 'Makanan / snack kafe'},
      {'word': 'Bantu', 'desc': 'Minta bantuan barista'},
      {'word': 'Dimana', 'desc': 'Tanya lokasi kasir/meja'},
      {'word': 'Apa Kabar', 'desc': 'Sapaan hangat'},
      {'word': 'Lapar', 'desc': 'Kebutuhan makan'},
      {'word': 'Haus', 'desc': 'Kebutuhan minum'},
      {'word': 'Sakit', 'desc': 'Kondisi kesehatan'},
      {'word': 'Berapa', 'desc': 'Tanya harga pesanan'},
    ];

    final cafeMenus = <Map<String, String>>[
      {'name': 'Oat Cappuccino', 'price': 'Rp 32.000', 'tag': 'HOT / ICED'},
      {'name': 'Iced Oat Caramel Latte', 'price': 'Rp 35.000', 'tag': 'ICED'},
      {
        'name': 'Double Shot Kopi Susu Aren',
        'price': 'Rp 28.000',
        'tag': 'ICED',
      },
      {'name': 'Low-Acid Oat Latte', 'price': 'Rp 34.000', 'tag': 'HOT'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchCtrl.text.trim().toLowerCase();

            final filteredSigns = query.isEmpty
                ? <Map<String, String>>[]
                : signWords
                      .where((s) => s['word']!.toLowerCase().contains(query))
                      .toList();

            final filteredMenus = query.isEmpty
                ? <Map<String, String>>[]
                : cafeMenus
                      .where((m) => m['name']!.toLowerCase().contains(query))
                      .toList();

            final filteredHistory = query.isEmpty
                ? <dynamic>[]
                : history.items
                      .where(
                        (h) =>
                            h.originalContent.toLowerCase().contains(query) ||
                            h.translatedContent.toLowerCase().contains(query),
                      )
                      .take(3)
                      .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: AppStrings.homeWaveSearchHint.tr,
                                hintStyle: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.muted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          if (searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                searchCtrl.clear();
                                setModalState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.border.withValues(
                                    alpha: 0.6,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content Results
                  Expanded(
                    child: query.isEmpty
                        ? _buildPopularSearchSuggestions((selected) {
                            searchCtrl.text = selected;
                            setModalState(() {});
                          })
                        : _buildSearchResultsList(
                            context: context,
                            query: query,
                            signs: filteredSigns,
                            menus: filteredMenus,
                            histories: filteredHistory,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPopularSearchSuggestions(Function(String) onSelect) {
    final chips = [
      'Oat Cappuccino',
      'Halo',
      'Terima Kasih',
      'Less Ice',
      'Double Shot Kopi Susu',
      'QRIS',
      'Air',
      'Bantu',
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text(
          'Pencarian Populer di Kafe',
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: chips.map((c) {
            return GestureDetector(
              onTap: () => onSelect(c),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList({
    required BuildContext context,
    required String query,
    required List<Map<String, String>> signs,
    required List<Map<String, String>> menus,
    required List<dynamic> histories,
  }) {
    if (signs.isEmpty && menus.isEmpty && histories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                AppStrings.homeQuickSearchEmpty.tr,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Category 1: Pustaka Isyarat
        if (signs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppStrings.homeQuickSearchSignCategory.tr,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
          ...signs.map((s) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sign_language_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              title: Text(
                s['word']!,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                s['desc']!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.speechToSignResult, arguments: s['word']);
              },
            );
          }),
          const SizedBox(height: 14),
        ],

        // Category 2: Menu Kafe
        if (menus.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppStrings.homeQuickSearchMenuCategory.tr,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.matcha,
              ),
            ),
          ),
          ...menus.map((m) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.matcha.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_cafe_rounded,
                  color: AppColors.matcha,
                  size: 20,
                ),
              ),
              title: Text(
                m['name']!,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                m['price']!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m['tag']!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.cafeCashierCounter);
              },
            );
          }),
        ],
      ],
    );
  }
}

// ── CUSTOM PAINTER: ORGANIC S-WAVE HEADER (MATCHING REFERENCE IMAGE 2) ──────
class DualWaveHeaderPainter extends CustomPainter {
  final double topPadding;
  final Color backWaveColor;
  final Color frontWaveColor;
  final bool isDark;

  DualWaveHeaderPainter({
    this.topPadding = 0.0,
    required this.backWaveColor,
    required this.frontWaveColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final top = topPadding;
    final bodyH = (size.height - top).clamp(80.0, 200.0);

    // ── LAYER 1: MAIN ESPRESSO / DARK S-WAVE (Reference Image 2 Contour) ────
    final frontPaint = Paint()
      ..color = frontWaveColor
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, top + bodyH * 0.40)
      // 1. High smooth dome arch over the left Avatar pocket
      ..cubicTo(
        w * 0.04,
        top + bodyH * 0.24,
        w * 0.09,
        top + bodyH * 0.20,
        w * 0.14,
        top + bodyH * 0.20,
      )
      // 2. Smooth C2 S-curve sweeping down into the wide central belly
      ..cubicTo(
        w * 0.25,
        top + bodyH * 0.20,
        w * 0.33,
        top + bodyH * 0.90,
        w * 0.48,
        top + bodyH * 0.90,
      )
      // 3. Gentle rise from the central belly to the soft right crest
      ..cubicTo(
        w * 0.60,
        top + bodyH * 0.90,
        w * 0.65,
        top + bodyH * 0.72,
        w * 0.75,
        top + bodyH * 0.72,
      )
      // 4. Gentle downward slope to the right edge (keeps SIBI button 100% inside dark header)
      ..cubicTo(
        w * 0.84,
        top + bodyH * 0.72,
        w * 0.93,
        top + bodyH * 0.81,
        w,
        top + bodyH * 0.90,
      )
      ..lineTo(w, 0)
      ..close();

    // Soft ambient shadow under the wave
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.32 : 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(frontPath, shadowPaint);

    canvas.drawPath(frontPath, frontPaint);

    // ── LAYER 2: DELICATE UPPER-LEFT ACCENT LINE (Inside Dark Header) ───────
    final upperAccentPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.14 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final upperAccentPath = Path()
      ..moveTo(0, top + bodyH * 0.28)
      ..cubicTo(
        w * 0.04,
        top + bodyH * 0.12,
        w * 0.09,
        top + bodyH * 0.09,
        w * 0.14,
        top + bodyH * 0.09,
      )
      ..cubicTo(
        w * 0.25,
        top + bodyH * 0.09,
        w * 0.33,
        top + bodyH * 0.90,
        w * 0.48,
        top + bodyH * 0.90,
      );

    canvas.drawPath(upperAccentPath, upperAccentPaint);

    // ── LAYER 3: SUBTLE LOWER-RIGHT CONTOUR WHISPER LINE (On Canvas Side) ───
    final lowerWhisperPaint = Paint()
      ..color = backWaveColor.withValues(alpha: isDark ? 0.25 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final lowerWhisperPath = Path()
      ..moveTo(w * 0.48, top + bodyH * 0.90)
      ..cubicTo(
        w * 0.60,
        top + bodyH * 0.90,
        w * 0.65,
        top + bodyH * 0.78,
        w * 0.75,
        top + bodyH * 0.78,
      )
      ..cubicTo(
        w * 0.84,
        top + bodyH * 0.78,
        w * 0.93,
        top + bodyH * 0.86,
        w,
        top + bodyH * 0.95,
      );

    canvas.drawPath(lowerWhisperPath, lowerWhisperPaint);
  }

  @override
  bool shouldRepaint(covariant DualWaveHeaderPainter oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.backWaveColor != backWaveColor ||
        oldDelegate.frontWaveColor != frontWaveColor ||
        oldDelegate.isDark != isDark;
  }
}
