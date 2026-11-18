import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_result.dart';
import '../../../cafe_pos/domain/models/cafe_order_ticket.dart';
import '../../../cafe_pos/domain/models/coffee_menu_item.dart';
import '../../../customer/domain/models/qris_payment_record.dart';
import '../../domain/models/admin_dashboard_metrics.dart';
import '../../domain/models/audit_log_entry.dart';
import '../../domain/models/inventory_movement_entry.dart';
import '../../domain/models/product_category.dart';

/// Supabase Data Layer service for Admin Dashboard Analytics, Product/Category CRUD,
/// Atomic Inventory Ledger & Stock Opname, Order/Payment Monitoring, Refunds, and Audit Logs.
class SupabaseAdminErpService {
  final SupabaseClient? _customSupabase;

  SupabaseAdminErpService({SupabaseClient? supabase})
    : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _formatDateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ── 1. ANALYTICS & REVENUE DASHBOARD (Asia/Jakarta) ────────────────────────

  Future<SupabaseResult<AdminDashboardMetrics>> fetchDashboardMetrics({
    required DateTime startDate,
    required DateTime endDate,
    bool includeSimulations = false,
  }) async {
    final client = _supabase;
    if (client == null) {
      return SupabaseSuccess(
        AdminDashboardMetrics(
          startDate: _formatDateOnly(startDate),
          endDate: _formatDateOnly(endDate),
        ),
      );
    }
    try {
      final res = await client.rpc(
        'rpc_admin_dashboard_metrics',
        params: <String, dynamic>{
          'p_start_date': _formatDateOnly(startDate),
          'p_end_date': _formatDateOnly(endDate),
          'p_tz': AppConstants.businessTimezone,
          'p_include_simulations': includeSimulations,
        },
      );
      if (res is Map) {
        return SupabaseSuccess(
          AdminDashboardMetrics.fromMap(Map<String, dynamic>.from(res)),
        );
      }
      return SupabaseSuccess(
        AdminDashboardMetrics(
          startDate: _formatDateOnly(startDate),
          endDate: _formatDateOnly(endDate),
        ),
      );
    } catch (e, st) {
      debugPrint('SupabaseAdminErpService.fetchDashboardMetrics error: $e\n$st');
      return SupabaseFailure('Gagal memuat metrik dashboard admin.', e);
    }
  }

  // ── 2. CATEGORIES CRUD ─────────────────────────────────────────────────────

  Future<SupabaseResult<List<ProductCategory>>> fetchCategories() async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<ProductCategory>[
        ProductCategory(id: 'cat-coffee', slug: 'coffee', nameId: 'Kopi Signature', sortOrder: 1),
        ProductCategory(id: 'cat-non-coffee', slug: 'non_coffee', nameId: 'Non-Kopi & Matcha', sortOrder: 2),
        ProductCategory(id: 'cat-snack', slug: 'snack', nameId: 'Camilan & Pastry', sortOrder: 3),
      ]);
    }
    try {
      final rows = await client
          .from('product_categories')
          .select()
          .order('sort_order', ascending: true);
      final list = rows
          .map((r) => ProductCategory.fromPostgresMap(Map<String, dynamic>.from(r)))
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat daftar kategori.', e);
    }
  }

  Future<SupabaseResult<ProductCategory>> upsertCategory(
    ProductCategory category,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final payload = category.toPostgresMap();
      final row = await client
          .from('product_categories')
          .upsert(payload, onConflict: 'slug')
          .select()
          .single();

      await client.rpc(
        'write_audit_log',
        params: <String, dynamic>{
          'p_action': 'category_upserted',
          'p_entity_type': 'product_categories',
          'p_entity_id': row['id'].toString(),
          'p_after': payload,
        },
      );
      return SupabaseSuccess(
        ProductCategory.fromPostgresMap(Map<String, dynamic>.from(row)),
      );
    } catch (e) {
      return SupabaseFailure('Gagal menyimpan kategori produk.', e);
    }
  }

  // ── 3. PRODUCTS CRUD & ARCHIVE ─────────────────────────────────────────────

  Future<SupabaseResult<List<CoffeeMenuItem>>> fetchAllProducts({
    bool includeArchived = true,
  }) async {
    final client = _supabase;
    if (client == null) {
      return SupabaseSuccess(
        List<CoffeeMenuItem>.from(CoffeeMenuItem.standardCatalog),
      );
    }
    try {
      var query = client.from('cafe_menus').select();
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      final rows = await query.order('created_at', ascending: false);
      if (rows.isEmpty) {
        return SupabaseSuccess(
          List<CoffeeMenuItem>.from(CoffeeMenuItem.standardCatalog),
        );
      }
      final items = rows
          .map((r) => CoffeeMenuItem.fromMap(Map<String, dynamic>.from(r)))
          .toList();
      return SupabaseSuccess(items);
    } catch (e) {
      return SupabaseFailure('Gagal memuat daftar produk.', e);
    }
  }

  Future<SupabaseResult<CoffeeMenuItem>> saveProduct(
    CoffeeMenuItem item, {
    CoffeeMenuItem? previousItem,
    int? initialStockOpname,
    String? opnameReason,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final payload = item.toPostgresMap();
      // Stock is never directly overwritten via raw product upsert;
      // stock changes go through rpc_admin_adjust_stock.
      payload.remove('stock_on_hand');
      payload.remove('stock_reserved');
      payload.remove('is_stock_initialized');

      final row = await client
          .from('cafe_menus')
          .upsert(payload, onConflict: 'id')
          .select()
          .single();

      await client.rpc(
        'write_audit_log',
        params: <String, dynamic>{
          'p_action': previousItem == null
              ? 'product_created'
              : (previousItem.basePrice != item.basePrice
                    ? 'product_price_updated'
                    : 'product_updated'),
          'p_entity_type': 'cafe_menus',
          'p_entity_id': item.id,
          'p_before': previousItem != null
              ? <String, dynamic>{
                  'name': previousItem.nameId,
                  'price': previousItem.basePrice,
                  'cost_price': previousItem.costPrice,
                  'is_available': previousItem.isAvailable,
                  'is_archived': previousItem.isArchived,
                }
              : null,
          'p_after': <String, dynamic>{
            'name': item.nameId,
            'price': item.basePrice,
            'cost_price': item.costPrice,
            'is_available': item.isAvailable,
            'is_archived': item.isArchived,
          },
        },
      );

      if (initialStockOpname != null && initialStockOpname >= 0) {
        await adjustInventory(
          productId: item.id,
          movementType: 'initial_opname',
          quantityDelta: initialStockOpname,
          reason: (opnameReason != null && opnameReason.trim().length >= 3)
              ? opnameReason.trim()
              : 'Stock opname awal saat pendaftaran produk',
        );
        final refreshed = await client
            .from('cafe_menus')
            .select()
            .eq('id', item.id)
            .single();
        return SupabaseSuccess(
          CoffeeMenuItem.fromMap(Map<String, dynamic>.from(refreshed)),
        );
      }

      return SupabaseSuccess(
        CoffeeMenuItem.fromMap(Map<String, dynamic>.from(row)),
      );
    } catch (e) {
      return SupabaseFailure('Gagal menyimpan produk.', e);
    }
  }

  Future<SupabaseResult<CoffeeMenuItem>> setProductArchived({
    required CoffeeMenuItem item,
    required bool isArchived,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final row = await client
          .from('cafe_menus')
          .update(<String, dynamic>{
            'is_archived': isArchived,
            'is_available': !isArchived,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', item.id)
          .select()
          .single();

      await client.rpc(
        'write_audit_log',
        params: <String, dynamic>{
          'p_action': isArchived ? 'product_archived' : 'product_reactivated',
          'p_entity_type': 'cafe_menus',
          'p_entity_id': item.id,
          'p_before': <String, dynamic>{'is_archived': item.isArchived},
          'p_after': <String, dynamic>{'is_archived': isArchived},
        },
      );

      return SupabaseSuccess(
        CoffeeMenuItem.fromMap(Map<String, dynamic>.from(row)),
      );
    } catch (e) {
      return SupabaseFailure('Gagal mengubah status arsip produk.', e);
    }
  }

  // ── 4. INVENTORY LEDGER & MANDATORY STOCK OPNAME ───────────────────────────

  Future<SupabaseResult<Map<String, dynamic>>> adjustInventory({
    required String productId,
    required String movementType,
    required int quantityDelta,
    required String reason,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final res = await client.rpc(
        'rpc_admin_adjust_stock',
        params: <String, dynamic>{
          'p_product_id': productId,
          'p_movement_type': movementType,
          'p_quantity_delta': quantityDelta,
          'p_reason': reason.trim(),
        },
      );
      return SupabaseSuccess(
        res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{},
      );
    } catch (e) {
      return SupabaseFailure(
        'Gagal menyesuaikan stok: ${e.toString().replaceAll('Exception:', '').trim()}',
        e,
      );
    }
  }

  Future<SupabaseResult<List<InventoryMovementEntry>>> fetchInventoryMovements({
    String? productId,
    int limit = 100,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<InventoryMovementEntry>[]);
    }
    try {
      var query = client.from('inventory_movements').select();
      if (productId != null && productId.isNotEmpty) {
        query = query.eq('product_id', productId);
      }
      final rows = await query.order('created_at', ascending: false).limit(limit);
      final list = rows
          .map(
            (r) => InventoryMovementEntry.fromPostgresMap(
              Map<String, dynamic>.from(r),
            ),
          )
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat riwayat mutasi stok.', e);
    }
  }

  Future<SupabaseResult<List<LowStockReportEntry>>> fetchLowStockReports() async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<LowStockReportEntry>[]);
    }
    try {
      final rows = await client
          .from('low_stock_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      final list = rows
          .map(
            (r) => LowStockReportEntry.fromPostgresMap(
              Map<String, dynamic>.from(r),
            ),
          )
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat laporan stok kasir.', e);
    }
  }

  Future<SupabaseResult<void>> resolveLowStockReport(String reportId) async {
    final client = _supabase;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      await client
          .from('low_stock_reports')
          .update(<String, dynamic>{
            'status': 'resolved',
            'resolved_by': uid,
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', reportId);
      return const SupabaseSuccess(null);
    } catch (e) {
      return SupabaseFailure('Gagal menandai laporan selesai.', e);
    }
  }

  // ── 5. ORDERS, PAYMENTS, REFUNDS & AUDIT LOGS ──────────────────────────────

  Future<SupabaseResult<List<CafeOrderTicket>>> fetchAllOrders({
    int limit = 100,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<CafeOrderTicket>[]);
    }
    try {
      final rows = await client
          .from('cafe_orders')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      final list = rows
          .map((r) => CafeOrderTicket.fromMap(Map<String, dynamic>.from(r)))
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat daftar pesanan.', e);
    }
  }

  Future<SupabaseResult<List<QrisPaymentRecord>>> fetchAllPayments({
    int limit = 100,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<QrisPaymentRecord>[]);
    }
    try {
      final rows = await client
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      final list = rows
          .map(
            (r) => QrisPaymentRecord.fromPostgresMap(
              Map<String, dynamic>.from(r),
            ),
          )
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat daftar transaksi pembayaran.', e);
    }
  }

  Future<SupabaseResult<void>> processRefund({
    required String orderId,
    required int amount,
    required String reason,
    bool restockItems = false,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final response = await client.functions.invoke(
        AppConstants.edgeFnProcessRefund,
        body: <String, dynamic>{
          'order_id': orderId,
          'amount': amount,
          'reason': reason.trim(),
          'restock_items': restockItems,
        },
      );
      if (response.status >= 400) {
        final data = response.data;
        final err = data is Map ? (data['error']?.toString() ?? '') : '';
        return SupabaseFailure(err.isNotEmpty ? err : 'Gagal memproses refund.');
      }
      return const SupabaseSuccess(null);
    } catch (e) {
      return SupabaseFailure('Gagal memproses refund pesanan.', e);
    }
  }

  Future<SupabaseResult<List<AuditLogEntry>>> fetchAuditLogs({
    int limit = 100,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<AuditLogEntry>[]);
    }
    try {
      final rows = await client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      final list = rows
          .map((r) => AuditLogEntry.fromPostgresMap(Map<String, dynamic>.from(r)))
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat log audit.', e);
    }
  }
}
