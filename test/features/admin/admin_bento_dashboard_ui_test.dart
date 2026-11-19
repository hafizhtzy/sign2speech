import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:speech2sign/features/admin/domain/models/admin_dashboard_metrics.dart';
import 'package:speech2sign/features/admin/screens/admin_dashboard_screen.dart';

import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    AppTranslations.ensureLoaded();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  const dummyProduct = CoffeeMenuItem(
    id: 'kopi-1',
    nameId: 'Kopi Susu Oat',
    nameEn: 'Oat Milk Coffee',
    category: 'Coffee',
    descriptionId: 'Kopi susu oat nikmat',
    descriptionEn: 'Delicious oat milk coffee',
    basePrice: 25000,
    costPrice: 15000,
    stockOnHand: 20,
    isStockInitialized: true,
  );

  group('Warm Color-Block Bento UI & Responsiveness Test', () {
    testWidgets('renders cleanly on 360px mobile screen without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctrl = Get.put(
        AdminDashboardController(
          initialProductsForTest: const [dummyProduct],
          initialMetricsForTest: const AdminDashboardMetrics(
            startDate: '2026-11-19',
            endDate: '2026-11-19',
            grossSales: 520000,
            refundedAmount: 20000,
            netSales: 500000,
            successCount: 18,
            pendingCount: 2,
            failedCount: 1,
            averageOrderValue: 28888,
            unitsSold: 24,
            qrisCount: 12,
            qrisSales: 350000,
            cashCount: 6,
            cashSales: 150000,
            hasCompleteCostData: true,
            netProfit: 215000,
            stockSummary: AdminStockSummary(
              activeProducts: 12,
              totalAvailableStock: 185,
              lowStockCount: 2,
              outOfStockCount: 1,
              uninitializedCount: 2,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: AdminDashboardScreen(controller: ctrl),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar title
      expect(find.text('Sign2Speech'), findsOneWidget);

      // Hero Block
      expect(find.text('Penjualan Bersih (Net)'), findsOneWidget);
      expect(find.text('Penjualan Kotor (Gross)'), findsOneWidget);

      // Row 2: AOV & Sign-to-Speech
      expect(find.text('Rata-rata Order (AOV)'), findsOneWidget);
      expect(find.text('Sign-to-Speech'), findsOneWidget);
      expect(find.textContaining('Kamus &'), findsOneWidget);

      // Row 3: Transaction status
      expect(find.text('Transaksi Sukses'), findsOneWidget);
      expect(find.text('Pending: 2'), findsOneWidget);
      expect(find.text('Gagal: 1'), findsOneWidget);

      // Row 4: Payment & Net profit
      expect(find.text('Metode Bayar'), findsOneWidget);
      expect(find.textContaining('QRIS:'), findsOneWidget);
      expect(find.textContaining('Tunai:'), findsOneWidget);
      expect(find.text('Estimasi Laba Bersih'), findsOneWidget);

      // Row 5: Stock Monitoring
      expect(find.text('Monitoring Stok Kafe'), findsOneWidget);
      expect(find.text('Wajib Stock Opname: 2'), findsOneWidget);
      expect(find.text('Aktif: 12'), findsOneWidget);
      expect(find.text('Stok: 185'), findsOneWidget);
      expect(find.text('Hampir Habis: 2'), findsOneWidget);
      expect(find.text('Habis: 1'), findsOneWidget);

      // Verify Drawer opens and contains 3 grouped categories
      final menuBtn = find.byIcon(Icons.menu_rounded);
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.adminGroupOperations.tr.toUpperCase()),
          findsOneWidget);
      expect(find.text(AppStrings.adminGroupFinanceA11y.tr.toUpperCase()),
          findsOneWidget);
      expect(find.byKey(const Key('admin_drawer_overview')), findsOneWidget);
      expect(find.byKey(const Key('admin_drawer_signVideos')), findsOneWidget);

      // Scroll to bottom of drawer to reveal logout button
      await tester.scrollUntilVisible(
        find.text(AppStrings.adminNavLogout.tr),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(AppStrings.adminNavLogout.tr), findsOneWidget);

      // No assertion failure or overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows HPP Belum Diisi and Atur HPP CTA when cost data is incomplete',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctrl = Get.put(
        AdminDashboardController(
          initialProductsForTest: const [dummyProduct],
          initialMetricsForTest: const AdminDashboardMetrics(
            startDate: '2026-11-19',
            endDate: '2026-11-19',
            grossSales: 100000,
            netSales: 100000,
            hasCompleteCostData: false,
            stockSummary: AdminStockSummary(
              activeProducts: 5,
              totalAvailableStock: 50,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: AdminDashboardScreen(controller: ctrl),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HPP Belum Diisi'), findsOneWidget);
      expect(find.text('Harga Modal Belum Lengkap'), findsOneWidget);
      expect(find.text('Atur HPP →'), findsOneWidget);

      // Tap Atur HPP button -> navigates to Products
      await tester.tap(find.text('Atur HPP →'));
      await tester.pumpAndSettle();
      expect(ctrl.activeSection.value, AdminSection.products);

      // Verify Products view renders with bento styling on mobile screen
      expect(find.text(AppStrings.adminNavProducts.tr), findsWidgets);
      expect(find.byKey(const Key('admin_add_product_btn')), findsOneWidget);
      expect(find.text('Kopi Susu Oat'), findsOneWidget);
      expect(find.textContaining('Rp 25.000'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Navigate to Profile view
      ctrl.activeSection.value = AdminSection.profile;
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.adminNavProfile.tr), findsOneWidget);
      expect(find.text(AppStrings.save.tr), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Navigate to Orders view
      ctrl.activeSection.value = AdminSection.orders;
      await tester.pumpAndSettle();
      expect(find.text('Transaksi & Pembayaran'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Navigate to Sign Videos view
      ctrl.activeSection.value = AdminSection.signVideos;
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.adminNavSignVideos.tr), findsOneWidget);
      expect(find.byKey(const Key('admin_video_ai_disclaimer_banner')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Navigate to Inventory view
      ctrl.activeSection.value = AdminSection.inventory;
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.adminNavInventory.tr), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
