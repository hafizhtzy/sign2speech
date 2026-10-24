import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/firestore_result.dart';
import '../../domain/models/cafe_order_ticket.dart';
import '../../domain/models/order_enums.dart';

/// Production-ready Firestore Service for Cafe POS orders, queue sync, and tickets.
/// Adheres to Clean Architecture (Data Layer only) and Dart 3 sealed class modeling.
class FirestoreCafePosService {
  final FirebaseFirestore? _customFirestore;

  FirestoreCafePosService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _ordersCollection =>
      _firestore?.collection('cafe_orders');

  CollectionReference<Map<String, dynamic>>? get _loyaltyCollection =>
      _firestore?.collection('user_loyalty');

  /// Saves or updates a Cafe order ticket in Cloud Firestore.
  Future<FirestoreResult<String>> saveOrder(CafeOrderTicket ticket) async {
    final col = _ordersCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final docId = ticket.orderId.isNotEmpty
          ? ticket.orderId
          : 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final payload = ticket.toMap();
      payload['orderId'] = docId;
      payload['subtotal'] = ticket.subtotal;
      payload['taxAmount'] = ticket.taxAmount;
      payload['grandTotal'] = ticket.grandTotal;
      payload['changeAmount'] = ticket.changeAmount;
      payload['updatedAt'] = FieldValue.serverTimestamp();
      payload['createdAt'] = FieldValue.serverTimestamp();

      await col.doc(docId).set(payload, SetOptions(merge: true));
      return FirestoreSuccess(docId);
    } catch (e, stack) {
      debugPrint('FirestoreCafePosService saveOrder error: $e\n$stack');
      return FirestoreFailure('Failed to save cafe order to cloud', e);
    }
  }

  /// Updates the order status (e.g. draft, confirmed, preparing, ready, completed, cancelled)
  Future<FirestoreResult<void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final col = _ordersCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      await col.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const FirestoreSuccess(null);
    } catch (e) {
      debugPrint('FirestoreCafePosService updateOrderStatus error: $e');
      return FirestoreFailure('Failed to update status for order: $orderId', e);
    }
  }

  /// Fetches a specific order ticket by ID
  Future<FirestoreResult<CafeOrderTicket?>> getOrder(String orderId) async {
    final col = _ordersCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final doc = await col.doc(orderId).get();
      if (!doc.exists || doc.data() == null) {
        return const FirestoreSuccess(null);
      }
      return FirestoreSuccess(CafeOrderTicket.fromMap(doc.data()!));
    } catch (e) {
      debugPrint('FirestoreCafePosService getOrder error: $e');
      return FirestoreFailure('Failed to retrieve order: $orderId', e);
    }
  }

  /// Realtime stream of active orders for barista / cashier / queue display.
  /// Emits tickets currently in draft, confirmed, preparing, or ready status.
  Stream<List<CafeOrderTicket>> streamActiveOrders() {
    final col = _ordersCollection;
    if (col == null) {
      return Stream.value(<CafeOrderTicket>[]);
    }

    return col
        .where(
          'status',
          whereIn: ['draft', 'confirmed', 'preparing', 'ready'],
        )
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs
              .map((doc) => CafeOrderTicket.fromMap(doc.data()))
              .toList();
          // Sort by creation time descending in-memory to prevent complex composite index requirements
          tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tickets;
        });
  }

  /// Fetches recent orders history from Cloud Firestore
  Future<FirestoreResult<List<CafeOrderTicket>>> fetchRecentOrders({
    int limit = 50,
  }) async {
    final col = _ordersCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      final querySnapshot =
          await col.orderBy('createdAt', descending: true).limit(limit).get();

      final orders = querySnapshot.docs
          .map((doc) => CafeOrderTicket.fromMap(doc.data()))
          .toList();

      return FirestoreSuccess(orders);
    } catch (e) {
      debugPrint('FirestoreCafePosService fetchRecentOrders error: $e');
      return FirestoreFailure('Failed to fetch recent orders', e);
    }
  }

  /// Syncs customer digital loyalty stamps to Firestore
  Future<FirestoreResult<void>> syncLoyaltyStamps(
    String customerId,
    int stampCount,
  ) async {
    final col = _loyaltyCollection;
    if (col == null) {
      return const FirestoreFailure('FirebaseFirestore is not initialized');
    }

    try {
      await col.doc(customerId).set({
        'customerId': customerId,
        'stampsCount': stampCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const FirestoreSuccess(null);
    } catch (e) {
      return FirestoreFailure('Failed to sync loyalty stamps', e);
    }
  }
}
