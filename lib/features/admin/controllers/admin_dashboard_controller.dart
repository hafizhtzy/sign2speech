import 'dart:io';

import 'package:get/get.dart';

import '../../../core/auth/models/app_user_role.dart';
import '../../../core/supabase/supabase_result.dart';
import '../../cafe_pos/domain/models/cafe_order_ticket.dart';
import '../../cafe_pos/domain/models/coffee_menu_item.dart';
import '../../customer/domain/models/qris_payment_record.dart';
import '../data/datasources/admin_report_exporter_service.dart';
import '../data/datasources/supabase_admin_erp_service.dart';
import '../data/datasources/supabase_admin_sign_video_service.dart';
import '../data/datasources/supabase_admin_staff_service.dart';
import '../domain/models/admin_dashboard_metrics.dart';
import '../domain/models/audit_log_entry.dart';
import '../domain/models/inventory_movement_entry.dart';
import '../domain/models/product_category.dart';
import '../domain/models/sign_video_metadata.dart';
import '../domain/models/staff_member.dart';

enum AdminSection {
  overview,
  products,
  categories,
  inventory,
  orders,
  transactions,
  salesReports,
  signVideos,
  staff,
  auditLogs,
  settings,
  profile,
}

enum AdminReportPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  custom,
}

/// Central GetX Controller for the 13-section Admin Dashboard & ERP Management.
class AdminDashboardController extends GetxController {
  final SupabaseAdminErpService _erpService;
  final SupabaseAdminSignVideoService _videoService;
  final SupabaseAdminStaffService _staffService;
  final AdminReportExporterService _exporterService;

  final Rx<AdminSection> activeSection = AdminSection.overview.obs;
  final Rx<AdminReportPeriod> selectedPeriod = AdminReportPeriod.today.obs;
  final Rx<DateTime> customStartDate = DateTime.now().obs;
  final Rx<DateTime> customEndDate = DateTime.now().obs;

  final Rx<AdminDashboardMetrics> metrics = const AdminDashboardMetrics(
    startDate: '2026-11-18',
    endDate: '2026-11-18',
  ).obs;

  final RxList<CoffeeMenuItem> products = <CoffeeMenuItem>[].obs;
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxList<InventoryMovementEntry> movements =
      <InventoryMovementEntry>[].obs;
  final RxList<LowStockReportEntry> lowStockReports =
      <LowStockReportEntry>[].obs;
  final RxList<CafeOrderTicket> orders = <CafeOrderTicket>[].obs;
  final RxList<QrisPaymentRecord> payments = <QrisPaymentRecord>[].obs;
  final RxList<SignVideoMetadata> signVideos = <SignVideoMetadata>[].obs;
  final RxList<StaffMember> cashiers = <StaffMember>[].obs;
  final RxList<AuditLogEntry> auditLogs = <AuditLogEntry>[].obs;

  // Filters & UI state
  final RxString productSearchQuery = ''.obs;
  final RxString productCategoryFilter = 'all'.obs;
  final RxString productStockFilter = 'all'.obs; // 'all', 'uninitialized', 'low', 'out', 'archived'
  final RxString videoSearchQuery = ''.obs;
  final RxString videoLangFilter = 'all'.obs; // 'all', 'BISINDO', 'SIBI'
  final RxString staffSearchQuery = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isUploadingVideo = false.obs;
  final RxBool cancelVideoUploadRequested = false.obs;
  final RxString errorMessage = ''.obs;

  AdminDashboardController({
    SupabaseAdminErpService? erpService,
    SupabaseAdminSignVideoService? videoService,
    SupabaseAdminStaffService? staffService,
    AdminReportExporterService? exporterService,
    AdminDashboardMetrics? initialMetricsForTest,
    List<CoffeeMenuItem>? initialProductsForTest,
    List<SignVideoMetadata>? initialVideosForTest,
    List<StaffMember>? initialCashiersForTest,
    List<AuditLogEntry>? initialAuditLogsForTest,
  }) : _erpService = erpService ?? SupabaseAdminErpService(),
       _videoService = videoService ?? SupabaseAdminSignVideoService(),
       _staffService = staffService ?? SupabaseAdminStaffService(),
       _exporterService =
           exporterService ?? const AdminReportExporterService() {
    if (initialMetricsForTest != null) {
      metrics.value = initialMetricsForTest;
    }
    if (initialProductsForTest != null) {
      products.assignAll(initialProductsForTest);
    }
    if (initialVideosForTest != null) {
      signVideos.assignAll(initialVideosForTest);
    }
    if (initialCashiersForTest != null) {
      cashiers.assignAll(initialCashiersForTest);
    }
    if (initialAuditLogsForTest != null) {
      auditLogs.assignAll(initialAuditLogsForTest);
    }
  }

  /// Computes the current time in `Asia/Jakarta` (UTC+7) without relying on device local offset.
  DateTime get nowJakarta =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  (DateTime, DateTime) get resolvedDateRange {
    final now = nowJakarta;
    final today = DateTime.utc(now.year, now.month, now.day);
    return switch (selectedPeriod.value) {
      AdminReportPeriod.today => (today, today),
      AdminReportPeriod.yesterday => (
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 1)),
      ),
      AdminReportPeriod.last7Days => (
        today.subtract(const Duration(days: 6)),
        today,
      ),
      AdminReportPeriod.last30Days => (
        today.subtract(const Duration(days: 29)),
        today,
      ),
      AdminReportPeriod.thisMonth => (
        DateTime.utc(now.year, now.month, 1),
        today,
      ),
      AdminReportPeriod.custom => (
        customStartDate.value,
        customEndDate.value,
      ),
    };
  }

  List<CoffeeMenuItem> get filteredProducts {
    final q = productSearchQuery.value.trim().toLowerCase();
    final cat = productCategoryFilter.value;
    final stockF = productStockFilter.value;

    return products.where((item) {
      if (stockF == 'archived') {
        if (!item.isArchived) return false;
      } else if (item.isArchived) {
        return false;
      }

      if (cat != 'all' && item.category != cat) return false;
      if (stockF == 'uninitialized' && item.isStockInitialized) return false;
      if (stockF == 'low' && !item.isLowStock) return false;
      if (stockF == 'out' && !item.isOutOfStock) return false;

      if (q.isNotEmpty) {
        final matchName = item.nameId.toLowerCase().contains(q);
        final matchSku = (item.sku ?? '').toLowerCase().contains(q);
        if (!matchName && !matchSku) return false;
      }
      return true;
    }).toList();
  }

  List<SignVideoMetadata> get filteredVideos {
    final q = videoSearchQuery.value.trim().toLowerCase();
    final lang = videoLangFilter.value;
    return signVideos.where((v) {
      if (lang != 'all' && v.languageType.toUpperCase() != lang) return false;
      if (q.isNotEmpty) {
        return v.title.toLowerCase().contains(q) ||
            v.gloss.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<StaffMember> get filteredCashiers {
    final q = staffSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return cashiers;
    return cashiers
        .where(
          (c) =>
              c.fullName.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (products.isEmpty) {
      refreshAllAdminData();
    }
  }

  Future<void> refreshAllAdminData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait([
        loadMetricsForSelectedPeriod(),
        loadCategoriesAndProducts(),
        loadInventoryData(),
        loadOrdersAndPayments(),
        loadSignVideos(),
        loadCashiers(),
        loadAuditLogs(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setReportPeriod(
    AdminReportPeriod period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    selectedPeriod.value = period;
    if (customStart != null) customStartDate.value = customStart;
    if (customEnd != null) customEndDate.value = customEnd;
    await loadMetricsForSelectedPeriod();
  }

  Future<void> loadMetricsForSelectedPeriod() async {
    final (start, end) = resolvedDateRange;
    final res = await _erpService.fetchDashboardMetrics(
      startDate: start,
      endDate: end,
    );
    if (res is SupabaseSuccess<AdminDashboardMetrics>) {
      metrics.value = res.data;
    }
  }

  Future<void> loadCategoriesAndProducts() async {
    final catRes = await _erpService.fetchCategories();
    if (catRes is SupabaseSuccess<List<ProductCategory>>) {
      categories.assignAll(catRes.data);
    }
    final prodRes = await _erpService.fetchAllProducts(includeArchived: true);
    if (prodRes is SupabaseSuccess<List<CoffeeMenuItem>>) {
      products.assignAll(prodRes.data);
    }
  }

  Future<void> loadInventoryData() async {
    final movRes = await _erpService.fetchInventoryMovements();
    if (movRes is SupabaseSuccess<List<InventoryMovementEntry>>) {
      movements.assignAll(movRes.data);
    }
    final repRes = await _erpService.fetchLowStockReports();
    if (repRes is SupabaseSuccess<List<LowStockReportEntry>>) {
      lowStockReports.assignAll(repRes.data);
    }
  }

  Future<void> loadOrdersAndPayments() async {
    final ordRes = await _erpService.fetchAllOrders();
    if (ordRes is SupabaseSuccess<List<CafeOrderTicket>>) {
      orders.assignAll(ordRes.data);
    }
    final payRes = await _erpService.fetchAllPayments();
    if (payRes is SupabaseSuccess<List<QrisPaymentRecord>>) {
      payments.assignAll(payRes.data);
    }
  }

  Future<void> loadSignVideos() async {
    final res = await _videoService.fetchVideos();
    if (res is SupabaseSuccess<List<SignVideoMetadata>>) {
      signVideos.assignAll(res.data);
    }
  }

  Future<void> loadCashiers() async {
    final res = await _staffService.listCashiers();
    if (res is SupabaseSuccess<List<StaffMember>>) {
      cashiers.assignAll(res.data);
    }
  }

  Future<void> loadAuditLogs() async {
    final res = await _erpService.fetchAuditLogs();
    if (res is SupabaseSuccess<List<AuditLogEntry>>) {
      auditLogs.assignAll(res.data);
    }
  }

  // ── MUTATIONS (WITH DOUBLE-SUBMIT PROTECTION) ─────────────────────────────

  Future<bool> saveProduct(
    CoffeeMenuItem item, {
    CoffeeMenuItem? previousItem,
    int? initialStockOpname,
    String? opnameReason,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final res = await _erpService.saveProduct(
        item,
        previousItem: previousItem,
        initialStockOpname: initialStockOpname,
        opnameReason: opnameReason,
      );
      return switch (res) {
        SupabaseSuccess() => () {
          loadCategoriesAndProducts();
          loadInventoryData();
          loadAuditLogs();
          return true;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> setProductArchived(CoffeeMenuItem item, bool isArchived) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final res = await _erpService.setProductArchived(
        item: item,
        isArchived: isArchived,
      );
      if (res is SupabaseSuccess<CoffeeMenuItem>) {
        await loadCategoriesAndProducts();
        await loadAuditLogs();
        return true;
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> upsertCategory(ProductCategory category) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final res = await _erpService.upsertCategory(category);
      if (res is SupabaseSuccess<ProductCategory>) {
        await loadCategoriesAndProducts();
        await loadAuditLogs();
        return true;
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> adjustProductStock({
    required String productId,
    required String movementType,
    required int quantityDelta,
    required String reason,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final res = await _erpService.adjustInventory(
        productId: productId,
        movementType: movementType,
        quantityDelta: quantityDelta,
        reason: reason,
      );
      return switch (res) {
        SupabaseSuccess() => () {
          loadCategoriesAndProducts();
          loadInventoryData();
          loadMetricsForSelectedPeriod();
          loadAuditLogs();
          return true;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> uploadSignVideo({
    required File videoFile,
    required String title,
    required String gloss,
    required String languageType,
    required String category,
    String description = '',
    SignPublicationStatus initialStatus = SignPublicationStatus.draft,
  }) async {
    if (isUploadingVideo.value) return false;
    isUploadingVideo.value = true;
    cancelVideoUploadRequested.value = false;
    errorMessage.value = '';
    try {
      final res = await _videoService.uploadAndSaveVideoMetadata(
        videoFile: videoFile,
        title: title,
        gloss: gloss,
        languageType: languageType,
        category: category,
        description: description,
        initialStatus: initialStatus,
        isCancelled: () => cancelVideoUploadRequested.value,
      );
      return switch (res) {
        SupabaseSuccess() => () {
          loadSignVideos();
          loadAuditLogs();
          return true;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return false;
        }(),
      };
    } finally {
      isUploadingVideo.value = false;
    }
  }

  void cancelActiveVideoUpload() {
    cancelVideoUploadRequested.value = true;
  }

  Future<bool> updateSignVideoStatus(
    SignVideoMetadata video,
    SignPublicationStatus newStatus,
  ) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final updated = SignVideoMetadata(
        id: video.id,
        title: video.title,
        slug: video.slug,
        gloss: video.gloss,
        aliases: video.aliases,
        languageType: video.languageType,
        category: video.category,
        description: video.description,
        storageBucket: video.storageBucket,
        storagePath: video.storagePath,
        thumbnailPath: video.thumbnailPath,
        durationSeconds: video.durationSeconds,
        mimeType: video.mimeType,
        fileSizeBytes: video.fileSizeBytes,
        publicationStatus: newStatus,
        createdBy: video.createdBy,
        createdAt: video.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      final res = await _videoService.updateVideoMetadata(updated);
      if (res is SupabaseSuccess<SignVideoMetadata>) {
        await loadSignVideos();
        await loadAuditLogs();
        return true;
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> inviteCashier({
    required String email,
    required String fullName,
    String? phone,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final res = await _staffService.inviteCashier(
        email: email,
        fullName: fullName,
        phone: phone,
      );
      return switch (res) {
        SupabaseSuccess() => () {
          loadCashiers();
          loadAuditLogs();
          return true;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> setCashierStatus({
    required String cashierId,
    required AccountStatus status,
    required String reason,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final res = await _staffService.setCashierStatus(
        cashierId: cashierId,
        targetStatus: status,
        reason: reason,
      );
      if (res is SupabaseSuccess<StaffMember>) {
        await loadCashiers();
        await loadAuditLogs();
        return true;
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> processOrderRefund({
    required String orderId,
    required int amount,
    required String reason,
    bool restockItems = false,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final res = await _erpService.processRefund(
        orderId: orderId,
        amount: amount,
        reason: reason,
        restockItems: restockItems,
      );
      return switch (res) {
        SupabaseSuccess() => () {
          loadOrdersAndPayments();
          loadMetricsForSelectedPeriod();
          loadAuditLogs();
          return true;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return false;
        }(),
      };
    } finally {
      isSubmitting.value = false;
    }
  }

  String buildCurrentCsvReport() =>
      _exporterService.buildCsvReport(metrics.value);

  Future<void> exportCsvReport() =>
      _exporterService.shareCsvReport(metrics.value);

  Future<void> exportPdfReport() =>
      _exporterService.printOrSharePdfReport(metrics.value);
}
