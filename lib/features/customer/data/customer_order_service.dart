import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_result.dart';
import '../../cafe_pos/domain/models/cafe_order_ticket.dart';
import '../../cafe_pos/domain/models/coffee_menu_item.dart';
import '../../cafe_pos/domain/models/parsed_cafe_order_slot.dart';
import '../domain/models/qris_payment_record.dart';

/// Supabase Data Layer service for Customer Self-Order, Atomic Stock Reservation,
/// and Midtrans QRIS Payment tracking.
class CustomerOrderService {
  final SupabaseClient? _customSupabase;

  CustomerOrderService({SupabaseClient? supabase}) : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Fetches non-archived cafe menu items from `public.cafe_menus`.
  Future<SupabaseResult<List<CoffeeMenuItem>>> fetchActiveCatalog() async {
    final client = _supabase;
    if (client == null) {
      return SupabaseSuccess(List<CoffeeMenuItem>.from(CoffeeMenuItem.standardCatalog));
    }
    try {
      final rows = await client
          .from('cafe_menus')
          .select()
          .eq('is_archived', false)
          .order('created_at', ascending: true);

      if (rows.isEmpty) {
        return SupabaseSuccess(List<CoffeeMenuItem>.from(CoffeeMenuItem.standardCatalog));
      }

      final items = rows
          .map((r) => CoffeeMenuItem.fromMap(Map<String, dynamic>.from(r)))
          .toList();
      return SupabaseSuccess(items);
    } catch (e, st) {
      debugPrint('CustomerOrderService.fetchActiveCatalog error: $e\n$st');
      return SupabaseFailure('Gagal memuat katalog menu kafe.', e);
    }
  }

  /// Calls `rpc_create_order_with_reservation` to atomically validate stock,
  /// reserve inventory, snapshot prices, and create the order row.
  Future<SupabaseResult<Map<String, dynamic>>> createOrderWithReservation({
    required String orderId,
    required String queueNumber,
    required String customerName,
    required String customerNotes,
    required List<ParsedCafeOrderSlot> items,
    String paymentMethod = 'qris',
    String orderSource = 'customer_app',
  }) async {
    final subtotal = items.fold<int>(0, (sum, s) => sum + s.totalPrice);
    final taxAmount = (subtotal * 0.10).round();
    final grandTotal = subtotal + taxAmount;
    final client = _supabase;
    if (client == null) {
      if (!kReleaseMode) {
        return SupabaseSuccess(<String, dynamic>{
          'order_id': orderId,
          'queue_number': queueNumber,
          'grand_total': grandTotal,
          'is_simulation': true,
        });
      }
      return const SupabaseFailure('Layanan transaksi belum terhubung.');
    }
    try {
      final itemsPayload = items.map((slot) {
        final modifierExtra = slot.unitPrice - slot.basePrice;
        return <String, dynamic>{
          'product_id': slot.drinkId,
          'quantity': slot.quantity,
          'modifier_extra_price': modifierExtra.clamp(0, 999999),
          'modifiers': <String, dynamic>{
            'temperature': slot.temperature.name,
            'cup_size': slot.cupSize.name,
            'milk_type': slot.milkType.name,
            'sweetness': slot.sweetnessLevel.name,
            'extra_shot': slot.extraShot,
          },
        };
      }).toList();

      final res = await client.rpc(
        'rpc_create_order_with_reservation',
        params: <String, dynamic>{
          'p_order_id': orderId,
          'p_queue_number': queueNumber,
          'p_customer_name': customerName.trim().isEmpty
              ? 'Pelanggan'
              : customerName.trim(),
          'p_customer_notes': customerNotes.trim(),
          'p_payment_method': paymentMethod,
          'p_order_source': orderSource,
          'p_items': itemsPayload,
        },
      );

      final data = res is Map
          ? Map<String, dynamic>.from(res)
          : <String, dynamic>{'order_id': orderId};
      return SupabaseSuccess(data);
    } catch (e, st) {
      debugPrint('CustomerOrderService.createOrderWithReservation error: $e\n$st');
      final raw = e.toString().toLowerCase();
      if (!kReleaseMode &&
          (raw.contains('pgrst202') ||
              raw.contains('could not find the function'))) {
        try {
          await client.from('cafe_orders').insert(<String, dynamic>{
            'order_id': orderId,
            'queue_number': queueNumber,
            'customer_name': customerName.trim().isEmpty
                ? 'Pelanggan'
                : customerName.trim(),
            'customer_notes': customerNotes.trim(),
            'status': 'pending',
            'payment_method': paymentMethod,
            'is_paid': false,
            'subtotal': subtotal,
            'tax_amount': taxAmount,
            'grand_total': grandTotal,
            'items': items.map((e) => e.toMap()).toList(),
          });
        } catch (_) {}
        return SupabaseSuccess(<String, dynamic>{
          'order_id': orderId,
          'queue_number': queueNumber,
          'grand_total': grandTotal,
          'is_simulation': true,
        });
      }
      return SupabaseFailure(_extractCleanError(e), e);
    }
  }

  /// Invokes Edge Function `payment-create-qris` to generate a Midtrans Core API
  /// QRIS charge (or controlled non-production simulator charge).
  Future<SupabaseResult<QrisPaymentRecord>> requestQrisCharge(
    String orderId, {
    int fallbackGrossAmount = 0,
  }) async {
    final client = _supabase;
    if (client == null) {
      if (!kReleaseMode) {
        return SupabaseSuccess(
          _buildDevSandboxSimulatedQris(orderId, fallbackGrossAmount),
        );
      }
      return const SupabaseFailure('Layanan pembayaran belum terhubung.');
    }
    try {
      final response = await client.functions.invoke(
        AppConstants.edgeFnCreateQris,
        body: <String, dynamic>{'order_id': orderId},
      );

      final data = response.data;
      if (response.status >= 400 || data is! Map) {
        final errMsg = data is Map ? (data['error']?.toString() ?? '') : '';
        if (!kReleaseMode && response.status == 404) {
          return SupabaseSuccess(
            _buildDevSandboxSimulatedQris(orderId, fallbackGrossAmount),
          );
        }
        return SupabaseFailure(
          errMsg.isNotEmpty ? errMsg : 'Gagal membuat kode pembayaran QRIS.',
        );
      }

      final paymentMap = data['payment'];
      if (paymentMap is! Map) {
        return const SupabaseFailure('Format respons QRIS tidak valid.');
      }

      return SupabaseSuccess(
        QrisPaymentRecord.fromPostgresMap(Map<String, dynamic>.from(paymentMap)),
      );
    } catch (e, st) {
      debugPrint('CustomerOrderService.requestQrisCharge error: $e\n$st');
      if (!kReleaseMode) {
        return SupabaseSuccess(
          _buildDevSandboxSimulatedQris(orderId, fallbackGrossAmount),
        );
      }
      return SupabaseFailure(_extractCleanError(e), e);
    }
  }

  QrisPaymentRecord _buildDevSandboxSimulatedQris(
    String orderId,
    int grossAmount,
  ) {
    final now = DateTime.now().toUtc();
    return QrisPaymentRecord(
      id: 'sim-$orderId',
      orderId: orderId,
      provider: 'sandbox_simulator',
      isSimulation: true,
      grossAmount: grossAmount,
      status: 'pending',
      qrString: '00020101021226680016ID.CO.SIGN2SPEECH.SIM0215$orderId',
      qrisActions: const <Map<String, dynamic>>[],
      expiresAt: now.add(const Duration(minutes: 15)),
    );
  }

  /// Streams realtime updates for a specific order's payment record.
  Stream<QrisPaymentRecord?> streamPaymentForOrder(String orderId) {
    final client = _supabase;
    if (client == null || orderId.isEmpty) {
      return const Stream<QrisPaymentRecord?>.empty();
    }
    return client
        .from('payments')
        .stream(primaryKey: const ['id'])
        .eq('order_id', orderId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return QrisPaymentRecord.fromPostgresMap(rows.first);
        });
  }

  /// Fetches the authenticated customer's own order history.
  Future<SupabaseResult<List<CafeOrderTicket>>> fetchMyOrders() async {
    final client = _supabase;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      return const SupabaseSuccess(<CafeOrderTicket>[]);
    }
    try {
      final rows = await client
          .from('cafe_orders')
          .select()
          .eq('customer_id', uid)
          .order('created_at', ascending: false)
          .limit(50);

      final tickets = rows
          .map((r) => CafeOrderTicket.fromMap(Map<String, dynamic>.from(r)))
          .toList();
      return SupabaseSuccess(tickets);
    } catch (e, st) {
      debugPrint('CustomerOrderService.fetchMyOrders error: $e\n$st');
      return SupabaseFailure('Gagal memuat riwayat pesanan Anda.', e);
    }
  }

  /// Streams the authenticated customer's orders in real time.
  Stream<List<CafeOrderTicket>> streamMyOrders(String userId) {
    final client = _supabase;
    if (client == null || userId.isEmpty) {
      return const Stream<List<CafeOrderTicket>>.empty();
    }
    return client
        .from('cafe_orders')
        .stream(primaryKey: const ['order_id'])
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((r) => CafeOrderTicket.fromMap(Map<String, dynamic>.from(r)))
              .toList(),
        );
  }

  String _extractCleanError(Object e) {
    final raw = e.toString();
    if (raw.contains('Stok produk')) {
      final match = RegExp(r'Stok produk[^"\n]+').firstMatch(raw);
      if (match != null) return match.group(0)!;
    }
    if (raw.contains('Produk "')) {
      final match = RegExp(r'Produk "[^"\n]+').firstMatch(raw);
      if (match != null) return match.group(0)!;
    }
    return 'Gagal memproses pesanan. Pastikan stok tersedia dan akun Anda aktif.';
  }
}
