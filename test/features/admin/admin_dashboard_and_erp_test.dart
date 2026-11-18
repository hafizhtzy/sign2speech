import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/auth/models/app_user_role.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/supabase/supabase_result.dart';
import 'package:speech2sign/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:speech2sign/features/admin/data/datasources/admin_report_exporter_service.dart';
import 'package:speech2sign/features/admin/data/datasources/supabase_admin_sign_video_service.dart';
import 'package:speech2sign/features/admin/domain/models/admin_dashboard_metrics.dart';
import 'package:speech2sign/features/admin/domain/models/audit_log_entry.dart';
import 'package:speech2sign/features/admin/domain/models/sign_video_metadata.dart';
import 'package:speech2sign/features/admin/domain/models/staff_member.dart';
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

  group('AdminDashboardMetrics & Financial Integrity (Phase 3.6 & 10)', () {
    test('never fabricates netProfit when has_complete_cost_data is false', () {
      final metricsWithoutCost = AdminDashboardMetrics.fromMap({
        'timezone': 'Asia/Jakarta',
        'start_date': '2026-11-18',
        'end_date': '2026-11-18',
        'gross_sales': 250000,
        'refunded_amount': 30000,
        'net_sales': 220000,
        'success_count': 8,
        'pending_count': 2,
        'failed_count': 1,
        'average_order_value': 27500,
        'units_sold': 10,
        'qris_count': 6,
        'qris_sales': 190000,
        'cash_count': 2,
        'cash_sales': 60000,
        'has_complete_cost_data': false,
        'net_profit': 999999, // Must be ignored when has_complete_cost_data is false
      });

      expect(metricsWithoutCost.timezone, 'Asia/Jakarta');
      expect(metricsWithoutCost.grossSales, 250000);
      expect(metricsWithoutCost.netSales, 220000);
      expect(metricsWithoutCost.hasCompleteCostData, isFalse);
      expect(metricsWithoutCost.netProfit, isNull);

      final metricsWithCost = AdminDashboardMetrics.fromMap({
        'timezone': 'Asia/Jakarta',
        'start_date': '2026-11-18',
        'end_date': '2026-11-18',
        'gross_sales': 250000,
        'refunded_amount': 30000,
        'net_sales': 220000,
        'has_complete_cost_data': true,
        'net_profit': 110000,
      });

      expect(metricsWithCost.hasCompleteCostData, isTrue);
      expect(metricsWithCost.netProfit, 110000);
    });

    test('AdminReportExporterService builds valid CSV and PDF bytes', () async {
      const exporter = AdminReportExporterService();
      const metrics = AdminDashboardMetrics(
        startDate: '2026-11-18',
        endDate: '2026-11-18',
        grossSales: 120000,
        refundedAmount: 20000,
        netSales: 100000,
        successCount: 4,
        averageOrderValue: 25000,
        unitsSold: 5,
        qrisCount: 3,
        qrisSales: 90000,
        cashCount: 1,
        cashSales: 30000,
        hasCompleteCostData: false,
        topProducts: [
          TopSellingProduct(
            productId: 'kopi_susu_oat',
            productName: 'Kopi Susu Oat',
            unitsSold: 4,
            totalRevenue: 112000,
            revenueSharePercent: 93.3,
          ),
        ],
      );

      final csv = exporter.buildCsvReport(metrics);
      expect(csv, contains('Penjualan Kotor (Gross Sales),120000'));
      expect(csv, contains('Penjualan Bersih (Net Sales),100000'));
      expect(csv, contains('Data Harga Modal Belum Lengkap'));
      expect(csv, contains('"Kopi Susu Oat",4,112000,93.3'));

      final pdfBytes = await exporter.buildPdfReportBytes(metrics);
      expect(pdfBytes.length, greaterThan(500));
      // Verify PDF header '%PDF-'
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    });
  });

  group('Sign Language Video Validation (Phase 5.2 & Test F)', () {
    test('rejects non-MP4 file and invalid header bytes, accepts valid MP4 ftyp header', () async {
      final tempDir = Directory.systemTemp.createTempSync('sign_video_test_');
      try {
        final badExtFile = File('${tempDir.path}/fake.txt')
          ..writeAsBytesSync([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70, 1, 2, 3, 4]);
        final badExtRes = await SupabaseAdminSignVideoService.validateVideoFile(
          badExtFile,
        );
        expect(badExtRes, isA<SupabaseFailure<int>>());

        final corruptMp4 = File('${tempDir.path}/corrupt.mp4')
          ..writeAsStringSync('<html>Error</html>');
        final corruptRes =
            await SupabaseAdminSignVideoService.validateVideoFile(corruptMp4);
        expect(corruptRes, isA<SupabaseFailure<int>>());

        final validMp4 = File('${tempDir.path}/valid_sign.mp4')
          ..writeAsBytesSync([
            0x00, 0x00, 0x00, 0x18,
            0x66, 0x74, 0x79, 0x70, // 'ftyp'
            0x69, 0x73, 0x6F, 0x6D, // 'isom'
            0x00, 0x00, 0x02, 0x00,
          ]);
        final validRes = await SupabaseAdminSignVideoService.validateVideoFile(
          validMp4,
        );
        expect(validRes, isA<SupabaseSuccess<int>>());
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('AdminDashboardScreen 13-Section Navigation & UI', () {
    testWidgets('navigates across Overview, Products, Inventory, Sign Videos, Staff, and Audit Logs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const uninitProduct = CoffeeMenuItem(
        id: 'kopi_opname_pending',
        nameId: 'Espresso Belum Opname',
        nameEn: 'Espresso Uninitialized',
        descriptionId: 'Stok belum diinisialisasi',
        descriptionEn: 'Uninitialized',
        basePrice: 22000,
        isStockInitialized: false,
      );

      final videoDraft = SignVideoMetadata(
        id: 'vid-1',
        title: 'Isyarat Pesan Kopi',
        slug: 'pesan_kopi',
        gloss: 'PESAN KOPI',
        languageType: 'BISINDO',
        storagePath: 'videos/bisindo/pesan_kopi.mp4',
        publicationStatus: SignPublicationStatus.draft,
        createdAt: DateTime.utc(2026, 11, 18),
        updatedAt: DateTime.utc(2026, 11, 18),
      );

      final cashier = StaffMember(
        id: 'cash-01',
        email: 'kasir1@sign2speech.id',
        fullName: 'Rina Kasir',
        status: AccountStatus.active,
        ordersProcessed: 12,
        totalHandledSales: 360000,
        createdAt: DateTime.utc(2026, 11, 18),
      );

      final auditLog = AuditLogEntry(
        id: 'log-1',
        actorRole: 'admin',
        actorName: 'Admin Fadli',
        action: 'product_price_updated',
        entityType: 'cafe_menus',
        entityId: 'kopi_susu_oat',
        beforeData: const {'price': 20000},
        afterData: const {'price': 22000},
        createdAt: DateTime.utc(2026, 11, 18),
      );

      final ctrl = Get.put(
        AdminDashboardController(
          initialMetricsForTest: const AdminDashboardMetrics(
            startDate: '2026-11-18',
            endDate: '2026-11-18',
            grossSales: 450000,
            netSales: 450000,
            successCount: 15,
            hasCompleteCostData: false,
            stockSummary: AdminStockSummary(
              activeProducts: 5,
              uninitializedCount: 1,
              totalAvailableStock: 40,
            ),
          ),
          initialProductsForTest: const [uninitProduct],
          initialVideosForTest: [videoDraft],
          initialCashiersForTest: [cashier],
          initialAuditLogsForTest: [auditLog],
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

      // 1. Overview Section
      expect(find.text('Penjualan Kotor (Gross)'), findsOneWidget);
      expect(find.text('Harga Modal Belum Lengkap'), findsOneWidget);

      // 2. Switch to Products Section
      await tester.tap(find.byKey(const Key('admin_nav_products')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Espresso Belum Opname'), findsOneWidget);
      expect(
        find.text(AppStrings.adminStockNotInitializedBadge.tr),
        findsOneWidget,
      );

      // 3. Switch to Inventory Section
      await tester.tap(find.byKey(const Key('admin_nav_inventory')));
      await tester.pumpAndSettle();
      expect(find.text('Stock Opname'), findsOneWidget);

      // 4. Switch to Sign Language Videos Section (verify AI vs Video disclaimer banner)
      await tester.tap(find.byKey(const Key('admin_nav_signVideos')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('admin_video_ai_disclaimer_banner')),
        findsOneWidget,
      );
      expect(find.textContaining('Isyarat Pesan Kopi'), findsOneWidget);

      // 5. Switch to Staff Management Section
      await tester.tap(find.byKey(const Key('admin_nav_staff')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rina Kasir'), findsOneWidget);

      // 6. Switch to Audit Logs Section
      await tester.tap(find.byKey(const Key('admin_nav_auditLogs')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Admin Fadli'), findsOneWidget);
      expect(find.textContaining('product_price_updated'), findsOneWidget);
    });
  });
}
