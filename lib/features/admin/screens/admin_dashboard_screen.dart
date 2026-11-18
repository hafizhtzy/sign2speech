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

  static const List<(AdminSection, IconData, String)> _navItems = [
    (AdminSection.overview, Icons.dashboard_outlined, AppStrings.adminNavOverview),
    (AdminSection.products, Icons.local_cafe_outlined, AppStrings.adminNavProducts),
    (AdminSection.categories, Icons.category_outlined, AppStrings.adminNavCategories),
    (AdminSection.inventory, Icons.inventory_2_outlined, AppStrings.adminNavInventory),
    (AdminSection.orders, Icons.receipt_long_outlined, AppStrings.adminNavOrders),
    (AdminSection.transactions, Icons.payments_outlined, AppStrings.adminNavTransactions),
    (AdminSection.salesReports, Icons.analytics_outlined, AppStrings.adminNavSalesReports),
    (AdminSection.signVideos, Icons.video_library_outlined, AppStrings.adminNavSignVideos),
    (AdminSection.staff, Icons.badge_outlined, AppStrings.adminNavStaff),
    (AdminSection.auditLogs, Icons.policy_outlined, AppStrings.adminNavAuditLogs),
    (AdminSection.settings, Icons.settings_outlined, AppStrings.adminNavSettings),
    (AdminSection.profile, Icons.person_outline_rounded, AppStrings.adminNavProfile),
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
        title: Text(AppStrings.authSignOutConfirmTitle.tr),
        content: Text(AppStrings.authSignOutConfirmDesc.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
            key: const Key('admin_confirm_logout_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.authSignOutBtn.tr),
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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppStrings.adminDashboardTitle.tr,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang Data',
            onPressed: _controller.refreshAllAdminData,
            icon: Icon(Icons.refresh_rounded, color: AppColors.ink),
          ),
          IconButton(
            key: const Key('admin_appbar_logout_btn'),
            tooltip: AppStrings.adminNavLogout.tr,
            onPressed: _confirmSignOut,
            icon: Icon(Icons.logout_rounded, color: AppColors.error),
          ),
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
                padding: const EdgeInsets.all(20),
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

  Widget _buildDesktopSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Material(
        color: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          children: [
          for (final (section, icon, labelKey) in _navItems)
            Obx(() {
              final selected = _controller.activeSection.value == section;
              return ListTile(
                key: Key('admin_nav_${section.name}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selected: selected,
                selectedTileColor: AppColors.primary,
                leading: Icon(
                  icon,
                  color: selected ? AppColors.textOnDark : AppColors.ink,
                ),
                title: Text(
                  labelKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: selected ? AppColors.textOnDark : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _controller.activeSection.value = section,
              );
            }),
          const Divider(),
          ListTile(
            key: const Key('admin_sidebar_logout_tile'),
            leading: Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              AppStrings.adminNavLogout.tr,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: _confirmSignOut,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final (section, icon, labelKey) in _navItems)
              Obx(() {
                final selected = _controller.activeSection.value == section;
                return ListTile(
                  key: Key('admin_drawer_${section.name}'),
                  selected: selected,
                  leading: Icon(icon, color: AppColors.ink),
                  title: Text(labelKey.tr),
                  onTap: () {
                    _controller.activeSection.value = section;
                    Navigator.of(context).pop();
                  },
                );
              }),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(AppStrings.adminNavLogout.tr),
              onTap: () {
                Navigator.of(context).pop();
                _confirmSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
