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

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

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

      final isLarge = context.isLargeScreen;
      final isExpanded = context.isExpanded;
      final screens = _getScreens(dynamicKey);

      if (isLarge) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          floatingActionButton: const CashierFab(extended: true),
          body: Row(
            children: [
              NavigationRail(
                backgroundColor: AppColors.surface,
                selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              extended: isExpanded,
              labelType: isExpanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              minWidth: 80,
              minExtendedWidth: 210,
              indicatorColor: AppColors.secondary.withValues(alpha: 0.16),
              selectedIconTheme: IconThemeData(
                color: AppColors.primary,
                size: 24,
              ),
              unselectedIconTheme: IconThemeData(
                color: AppColors.muted,
                size: 22,
              ),
              selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    if (isExpanded) ...[
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
            VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: IndexedStack(
                key: ValueKey('rail_stack_$dynamicKey'),
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: const CashierFab(),
      body: IndexedStack(
        key: ValueKey('shell_stack_$dynamicKey'),
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: AppStrings.navHome.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              activeIcon: const Icon(Icons.history_rounded),
              label: AppStrings.navHistory.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_outlined),
              activeIcon: const Icon(Icons.menu_book_rounded),
              label: AppStrings.navLibrary.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings_rounded),
              label: AppStrings.navSettings.tr,
            ),
          ],
        ),
      ),
    );
    });
  }
}
