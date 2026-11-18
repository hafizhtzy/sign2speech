import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_result.dart';
import '../../domain/models/cafe_order_ticket.dart';
import '../../domain/models/order_enums.dart';

/// Production-ready Supabase Service for Cafe POS orders, queue sync, and tickets.
/// Adheres to Clean Architecture (Data Layer only), Defensive Lazy Initialization,
/// and Dart 3 sealed class modeling.
class SupabaseCafePosService {
  final SupabaseClient? _customSupabase;

  SupabaseCafePosService({SupabaseClient? supabase})
      : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates a Cafe order ticket in Supabase (`cafe_orders` table).
  Future<SupabaseResult<String>> saveOrder(CafeOrderTicket ticket) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final docId = ticket.orderId.isNotEmpty
          ? ticket.orderId
          : 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final statusStr = ticket.status == OrderStatus.readyForPickup
          ? 'ready'
          : ticket.status.name;

      final payload = <String, dynamic>{
        'order_id': docId,
        'queue_number': ticket.queueNumber,
        'customer_name': ticket.customerName,
        'customer_notes': ticket.customerNotes,
        'items': ticket.items.map((item) => item.toMap()).toList(),
        'status': statusStr,
        'payment_method': ticket.paymentMethod.name,
        'amount_paid': ticket.amountPaid,
        'subtotal': ticket.subtotal,
        'tax_amount': ticket.taxAmount,
        'grand_total': ticket.grandTotal,
        'change_amount': ticket.changeAmount,
        'created_at': ticket.createdAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client.from('cafe_orders').upsert(
            payload,
            onConflict: 'order_id',
          );
      return SupabaseSuccess(docId);
    } catch (e, stack) {
      debugPrint('SupabaseCafePosService saveOrder error: $e\n$stack');
      return SupabaseFailure('Failed to save cafe order to cloud', e);
    }
  }

  /// Updates the order status (e.g. draft, confirmed, preparing, ready, completed, cancelled)
  Future<SupabaseResult<void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final statusStr =
          status == OrderStatus.readyForPickup ? 'ready' : status.name;

      await client.from('cafe_orders').update({
        'status': statusStr,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('order_id', orderId);
      return const SupabaseSuccess(null);
    } catch (e) {
      debugPrint('SupabaseCafePosService updateOrderStatus error: $e');
      return SupabaseFailure('Failed to update status for order: $orderId', e);
    }
  }

  /// Fetches a specific order ticket by ID
  Future<SupabaseResult<CafeOrderTicket?>> getOrder(String orderId) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final row = await client
          .from('cafe_orders')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (row == null) {
        return const SupabaseSuccess(null);
      }
      return SupabaseSuccess(CafeOrderTicket.fromMap(row));
    } catch (e) {
      debugPrint('SupabaseCafePosService getOrder error: $e');
      return SupabaseFailure('Failed to retrieve order: $orderId', e);
    }
  }

  /// Realtime stream of active orders for barista / cashier / queue display.
  /// Emits tickets currently in draft, confirmed, preparing, or ready status.
  Stream<List<CafeOrderTicket>> streamActiveOrders() {
    final client = _supabase;
    if (client == null) {
      return Stream.value(<CafeOrderTicket>[]);
    }

    const activeStatuses = {
      'draft',
      'confirmed',
      'preparing',
      'ready',
      'readyForPickup',
    };

    return client
        .from('cafe_orders')
        .stream(primaryKey: ['order_id'])
        .map((rows) {
          final tickets = rows
              .where((row) => activeStatuses.contains(row['status']))
              .map((row) => CafeOrderTicket.fromMap(row))
              .toList();
          // Sort by creation time descending in-memory
          tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tickets;
        });
  }

  /// Fetches recent orders history from Supabase (`cafe_orders`)
  Future<SupabaseResult<List<CafeOrderTicket>>> fetchRecentOrders({
    int limit = 50,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final rows = await client
          .from('cafe_orders')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final orders = rows
          .map((row) => CafeOrderTicket.fromMap(row))
          .toList();

      return SupabaseSuccess(orders);
    } catch (e) {
      debugPrint('SupabaseCafePosService fetchRecentOrders error: $e');
      return SupabaseFailure('Failed to fetch recent orders', e);
    }
  }

  /// Syncs customer digital loyalty stamps to Supabase (`user_loyalty` table)
  Future<SupabaseResult<void>> syncLoyaltyStamps(
    String customerId,
    int stampCount,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      await client.from('user_loyalty').upsert(
        {
          'customer_id': customerId,
          'stamps_count': stampCount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'customer_id',
      );
      return const SupabaseSuccess(null);
    } catch (e) {
      return SupabaseFailure('Failed to sync loyalty stamps', e);
    }
  }

  /// Cashier-authorized RPC to complete a cash payment with server-side stock deduction.
  Future<SupabaseResult<Map<String, dynamic>>> completeCashOrderRpc({
    required String orderId,
    required int amountReceived,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final res = await client.rpc(
        'rpc_cashier_complete_cash_order',
        params: <String, dynamic>{
          'p_order_id': orderId,
          'p_amount_received': amountReceived,
        },
      );
      return SupabaseSuccess(
        res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{},
      );
    } catch (e) {
      return SupabaseFailure('Gagal menyelesaikan pembayaran tunai.', e);
    }
  }

  /// Cashier-authorized RPC to advance order workflow status (`preparing`, `readyForPickup`, `completed`, `cancelled`).
  Future<SupabaseResult<Map<String, dynamic>>> advanceOrderStatusRpc({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final res = await client.rpc(
        'rpc_cashier_advance_order_status',
        params: <String, dynamic>{
          'p_order_id': orderId,
          'p_new_status': newStatus.name,
        },
      );
      return SupabaseSuccess(
        res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{},
      );
    } catch (e) {
      return SupabaseFailure('Gagal memperbarui status pesanan.', e);
    }
  }

  /// Allows CASHIER to report low stock to ADMIN without giving cashier direct stock mutation rights.
  Future<SupabaseResult<void>> reportLowStockToAdmin({
    required String productId,
    required int reportedAvailableStock,
    required String note,
  }) async {
    final client = _supabase;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      return const SupabaseFailure('Sesi kasir belum terautentikasi.');
    }
    try {
      await client.from('low_stock_reports').insert(<String, dynamic>{
        'product_id': productId,
        'reported_by': uid,
        'reported_available_stock': reportedAvailableStock,
        'note': note.trim(),
        'status': 'open',
      });
      return const SupabaseSuccess(null);
    } catch (e) {
      return SupabaseFailure('Gagal mengirim laporan stok ke Admin.', e);
    }
  }
}
