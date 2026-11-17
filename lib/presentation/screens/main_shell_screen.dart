import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cashier_fab.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'sign_library_screen.dart';
import '../widgets/floating_pill_nav_bar.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  List<Widget> _getScreens(String dynamicKey) => [
    HomeScreen(key: ValueKey('home_$dynamicKey')),
    HistoryScreen(key: ValueKey('history_$dynamicKey')),
    SignLibraryScreen(key: ValueKey('library_$dynamicKey')),
    SettingsScreen(key: ValueKey('settings_$dynamicKey')),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final settings = Get.isRegistered<SettingsController>()
          ? Get.find<SettingsController>()
          : null;
      final isDark = settings?.isDarkMode ?? false;
      final themeKey = '${settings?.themeMode.value.name}_$isDark';
      final langKey = settings?.selectedAppLanguage.value ?? 'id';
      final dynamicKey = '${themeKey}_$langKey';

      final size = MediaQuery.sizeOf(context);
      final isShortLandscape = size.height < 520;
      final orientation = MediaQuery.orientationOf(context);
      final isLandscape = orientation == Orientation.landscape;
      final isLarge = context.isLargeScreen;
      final shouldExtendRail = context.isExpanded && !isShortLandscape;
      final screens = _getScreens(dynamicKey);

      if (isLarge) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          floatingActionButton: const CashierFab(extended: true),
          body: Row(
            children: [
              Container(
                color: AppColors.surface,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  right: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isLandscape ? 12.0 : 4.0,
                      right: isLandscape ? 6.0 : 0.0,
                    ),
                    child: NavigationRail(
                      backgroundColor: AppColors.surface,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _onTabSelected,
                      extended: shouldExtendRail,
                      labelType: shouldExtendRail
                          ? NavigationRailLabelType.none
                          : (isShortLandscape
                                ? NavigationRailLabelType.selected
                                : NavigationRailLabelType.all),
                      minWidth: isShortLandscape ? 72 : 80,
                      minExtendedWidth: 210,
                      indicatorColor: AppColors.secondary.withValues(
                        alpha: 0.16,
                      ),
                      selectedIconTheme: IconThemeData(
                        color: AppColors.primary,
                        size: isShortLandscape ? 22 : 24,
                      ),
                      unselectedIconTheme: IconThemeData(
                        color: AppColors.muted,
                        size: isShortLandscape ? 20 : 22,
                      ),
                      selectedLabelTextStyle: AppTypography.labelMedium
                          .copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                      unselectedLabelTextStyle: AppTypography.labelMedium
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                      leading: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isShortLandscape ? 8 : 20,
                          horizontal: isLandscape ? 8 : 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isShortLandscape ? 36 : 44,
                              height: isShortLandscape ? 36 : 44,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.sign_language_rounded,
                                  size: isShortLandscape ? 18 : 22,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            if (shouldExtendRail) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  AppStrings.appTitle.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home_rounded),
                          label: Text(AppStrings.navHome.tr),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.history_outlined),
                          selectedIcon: const Icon(Icons.history_rounded),
                          label: Text(AppStrings.navHistory.tr),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.menu_book_outlined),
                          selectedIcon: const Icon(Icons.menu_book_rounded),
                          label: Text(AppStrings.navLibrary.tr),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings_rounded),
                          label: Text(AppStrings.navSettings.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
              Expanded(
                child: SafeArea(
                  left: false,
                  top: false,
                  bottom: false,
                  child: AnimatedIndexedStack(
                    key: ValueKey('rail_stack_$dynamicKey'),
                    index: _currentIndex,
                    children: screens,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        extendBody: true,
        backgroundColor: AppColors.canvas,
        floatingActionButton: const CashierFab(),
        body: AnimatedIndexedStack(
          key: ValueKey('shell_stack_$dynamicKey'),
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: FloatingPillNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: [
            FloatingPillNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: AppStrings.navHome.tr,
            ),
            FloatingPillNavItem(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history_rounded,
              label: AppStrings.navHistory.tr,
            ),
            FloatingPillNavItem(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book_rounded,
              label: AppStrings.navLibrary.tr,
            ),
            FloatingPillNavItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: AppStrings.navSettings.tr,
            ),
          ],
        ),
      );
    });
  }
}

/// A high-performance, 60fps-optimized animated index switcher.
/// Provides smooth cross-fade + micro-slide transitions while keeping
/// inactive screens offstage to prevent redundant repaints and widget tree leaks.
class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _prevIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _prevIndex = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _prevIndex = _currentIndex;
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isForward = _currentIndex >= _prevIndex;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final isAnimating = _controller.isAnimating;

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (i) {
            final isCurrent = i == _currentIndex;
            final isPrev = i == _prevIndex;
            final shouldRenderActive = isCurrent || (isAnimating && isPrev);

            if (!shouldRenderActive) {
              return Offstage(offstage: true, child: widget.children[i]);
            }

            final double opacity = isCurrent
                ? _animation.value
                : (1.0 - _animation.value);

            final double slideOffset = isCurrent
                ? (isForward ? 0.04 : -0.04) * (1.0 - _animation.value)
                : (isForward ? -0.04 : 0.04) * _animation.value;

            return Offstage(
              offstage: false,
              child: IgnorePointer(
                ignoring: !isCurrent,
                child: RepaintBoundary(
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(
                        slideOffset * MediaQuery.sizeOf(context).width,
                        0,
                      ),
                      child: widget.children[i],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
