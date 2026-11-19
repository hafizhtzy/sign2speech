import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/controllers/auth_controller.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../presentation/screens/settings_screen.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_catalog_and_inventory_views.dart';
import '../widgets/admin_overview_and_reports_views.dart';
import '../widgets/admin_videos_staff_audit_views.dart';

/// Responsive 13-Section Admin Dashboard Shell (`Phase 8`).
///
/// Sections:
/// 1. Overview
/// 2. Products
/// 3. Categories
/// 4. Inventory
/// 5. Orders
/// 6. Transactions
/// 7. Sales Reports
/// 8. Sign Language Videos
/// 9. Staff Management
/// 10. Activity Logs
/// 11. Settings
/// 12. Profile
/// 13. Logout
class AdminDashboardScreen extends StatefulWidget {
  final AdminDashboardController? controller;

  const AdminDashboardScreen({super.key, this.controller});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardController _controller;

  static const List<(AdminSection, IconData, String)> _operationsNavItems = [
    (AdminSection.overview, Icons.dashboard_rounded, AppStrings.adminNavOverview),
    (AdminSection.orders, Icons.receipt_long_rounded, AppStrings.adminNavOrders),
    (AdminSection.products, Icons.local_cafe_rounded, AppStrings.adminNavProducts),
    (AdminSection.categories, Icons.category_rounded, AppStrings.adminNavCategories),
    (AdminSection.inventory, Icons.inventory_2_rounded, AppStrings.adminNavInventory),
  ];

  static const List<(AdminSection, IconData, String)> _financeA11yNavItems = [
    (AdminSection.transactions, Icons.payments_rounded, AppStrings.adminNavTransactions),
    (AdminSection.salesReports, Icons.analytics_rounded, AppStrings.adminNavSalesReports),
    (AdminSection.signVideos, Icons.video_library_rounded, AppStrings.adminNavSignVideos),
  ];

  static const List<(AdminSection, IconData, String)> _managementNavItems = [
    (AdminSection.staff, Icons.badge_rounded, AppStrings.adminNavStaff),
    (AdminSection.auditLogs, Icons.policy_rounded, AppStrings.adminNavAuditLogs),
    (AdminSection.settings, Icons.settings_rounded, AppStrings.adminNavSettings),
    (AdminSection.profile, Icons.person_rounded, AppStrings.adminNavProfile),
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        (Get.isRegistered<AdminDashboardController>()
            ? Get.find<AdminDashboardController>()
            : Get.put(AdminDashboardController()));
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.authSignOutConfirmTitle.tr,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.bentoTextLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          AppStrings.authSignOutConfirmDesc.tr,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.bentoCardLight.withOpacity(0.85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancel.tr,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('admin_confirm_logout_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bentoTerracotta,
              foregroundColor: AppColors.bentoTextLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.authSignOutBtn.tr,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.bentoTextLight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().signOut();
      }
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Widget _buildActiveSectionBody() {
    return Obx(() {
      return switch (_controller.activeSection.value) {
        AdminSection.overview => AdminOverviewView(controller: _controller),
        AdminSection.products => AdminProductsView(controller: _controller),
        AdminSection.categories => AdminCategoriesView(controller: _controller),
        AdminSection.inventory => AdminInventoryView(controller: _controller),
        AdminSection.orders || AdminSection.transactions =>
          AdminOrdersTransactionsView(controller: _controller),
        AdminSection.salesReports =>
          AdminSalesReportView(controller: _controller),
        AdminSection.signVideos => AdminSignVideosView(controller: _controller),
        AdminSection.staff => AdminStaffView(controller: _controller),
        AdminSection.auditLogs => AdminAuditLogsView(controller: _controller),
        AdminSection.settings => const SizedBox(
          height: 680,
          child: SettingsScreen(),
        ),
        AdminSection.profile => const AdminProfileView(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = context.isLargeScreen;

    return Scaffold(
      backgroundColor: AppColors.bentoBase,
      appBar: AppBar(
        backgroundColor: AppColors.bentoBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: isLarge ? null : 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bentoCardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                color: AppColors.bentoHoney,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sign2Speech',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.bentoTextLight,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Soft circular Refresh button
          InkWell(
            onTap: _controller.refreshAllAdminData,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.bentoCardDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.bentoTextLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Circular Warm Oat Cream Menu / Drawer button
          if (!isLarge)
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.bentoCardLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.bentoTextDark,
                    size: 20,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 14),
        ],
      ),
      drawer: isLarge ? null : _buildMobileDrawer(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLarge) _buildDesktopSidebar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: ResponsiveContentWrapper(
                  maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
                  child: _buildActiveSectionBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavGroupCard({
    required String titleKey,
    required List<(AdminSection, IconData, String)> items,
    required bool isDrawer,
  }) {
    return Material(
      color: AppColors.bentoCardDark,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                titleKey.tr.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.bentoCardLight.withOpacity(0.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final (section, icon, labelKey) in items)
              Obx(() {
                final isSelected = _controller.activeSection.value == section;
                final isSignVideos = section == AdminSection.signVideos;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: isSelected ? AppColors.bentoHoney : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: Key(isDrawer
                          ? 'admin_drawer_${section.name}'
                          : 'admin_nav_${section.name}'),
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.bentoTextDark
                            : (isSignVideos
                                ? AppColors.bentoMatcha
                                : AppColors.bentoCardLight.withOpacity(0.85)),
                      ),
                      title: Text(
                        labelKey.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: isSelected
                              ? AppColors.bentoTextDark
                              : AppColors.bentoTextLight,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: isSignVideos
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.bentoTextDark
                                    : AppColors.bentoMatcha,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AI',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.bentoMatcha
                                      : AppColors.bentoTextDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        _controller.activeSection.value = section;
                        if (isDrawer) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 260,
      color: AppColors.bentoBase,
      child: Material(
        color: AppColors.bentoBase,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          children: [
            _buildNavGroupCard(
              titleKey: AppStrings.adminGroupOperations,
              items: _operationsNavItems,
              isDrawer: false,
            ),
            const SizedBox(height: 8),
            _buildNavGroupCard(
              titleKey: AppStrings.adminGroupFinanceA11y,
              items: _financeA11yNavItems,
              isDrawer: false,
            ),
            const SizedBox(height: 8),
            _buildNavGroupCard(
              titleKey: AppStrings.adminGroupManagement,
              items: _managementNavItems,
              isDrawer: false,
            ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.bentoTerracotta,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: const Key('admin_sidebar_logout_tile'),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.bentoTextLight,
                  size: 20,
                ),
                title: Text(
                  AppStrings.adminNavLogout.tr,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: _confirmSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppColors.bentoBase,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            // Profile & Brand Header Card
            Material(
              color: AppColors.bentoCardDark,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.bentoHoney,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.bentoTextDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign2Speech Cafe',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.bentoTextLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bentoMatcha.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Administrator',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.bentoMatcha,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Group 1: Operasional Kafe
            _buildNavGroupCard(
              titleKey: AppStrings.adminGroupOperations,
              items: _operationsNavItems,
              isDrawer: true,
            ),
            const SizedBox(height: 8),

            // Group 2: Keuangan & Aksesibilitas
            _buildNavGroupCard(
              titleKey: AppStrings.adminGroupFinanceA11y,
              items: _financeA11yNavItems,
              isDrawer: true,
            ),
            const SizedBox(height: 8),

            // Group 3: Manajemen & Sistem
            _buildNavGroupCard(
              titleKey: AppStrings.adminGroupManagement,
              items: _managementNavItems,
              isDrawer: true,
            ),
            const SizedBox(height: 12),

            // Drawer Footer: Logout (Roasted Terracotta)
            Material(
              color: AppColors.bentoTerracotta,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.bentoTextLight,
                  size: 20,
                ),
                title: Text(
                  AppStrings.adminNavLogout.tr,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmSignOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
