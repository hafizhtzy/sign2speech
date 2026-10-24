import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/firestore_result.dart';
import '../../domain/models/cafe_counter_session.dart';
import '../../domain/models/order_enums.dart';

/// Firestore Data Layer service untuk counter_sessions.
/// Mengikuti Clean Architecture: HANYA dipanggil dari Controller / Repository,
/// TIDAK dari widget/view langsung.
///
/// Koleksi: `counter_sessions/{counterId}` (e.g. 'KAFE-01')
/// Tidak menyimpan raw frames, MediaPipe landmarks, tensor 706-D, atau audio.
class FirestoreCounterSessionService {
  final FirebaseFirestore? _customFirestore;

  FirestoreCounterSessionService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  /// Lazy null-safe getter — aman digunakan di test tanpa Firebase init.
  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _sessions =>
      _firestore?.collection('counter_sessions');

  // ── WRITE: Upsert session state ──────────────────────────────────────────

  /// Sync stage pesanan ke Firestore secara real-time.
  Future<FirestoreResult<void>> syncStage(
    String counterId,
    CafeOrderStage stage, {
    String currentOrderId = '',
  }) async {
    final col = _sessions;
    if (col == null) {
      return const FirestoreFailure('Firestore tidak tersedia (offline mode)');
    }
    try {
      await col.doc(counterId).set({
        'counterId': counterId,
        'stage': stage.name,
        'currentOrderId': currentOrderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const FirestoreSuccess(null);
    } catch (e, st) {
      debugPrint('FirestoreCounterSessionService.syncStage error: $e\n$st');
      return FirestoreFailure('Gagal sync stage ke cloud', e);
    }
  }

  /// Pasangkan tablet kasir dan tablet pembeli ke counter session.
  Future<FirestoreResult<void>> pairDevices({
    required String counterId,
    required String cashierTabletId,
    required String customerTabletId,
    required CounterDeviceMode mode,
  }) async {
    final col = _sessions;
    if (col == null) {
      return const FirestoreFailure('Firestore tidak tersedia (offline mode)');
    }
    try {
      await col.doc(counterId).set({
        'counterId': counterId,
        'deviceMode': mode.name,
        'cashierTabletId': cashierTabletId,
        'customerTabletId': customerTabletId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const FirestoreSuccess(null);
    } catch (e) {
      debugPrint('FirestoreCounterSessionService.pairDevices error: $e');
      return FirestoreFailure('Gagal menyimpan pairing device', e);
    }
  }

  // ── READ: Real-time stream ────────────────────────────────────────────────

  /// Stream session counter untuk tablet pembeli (real-time sync).
  Stream<CafeCounterSession> streamSession(String counterId) {
    final col = _sessions;
    if (col == null) {
      return Stream.value(CafeCounterSession(
        counterId: counterId,
        updatedAt: DateTime.now(),
      ));
    }
    return col.doc(counterId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return CafeCounterSession(
          counterId: counterId,
          updatedAt: DateTime.now(),
        );
      }
      return CafeCounterSession.fromMap(snap.data()!);
    });
  }

  /// One-shot fetch session.
  Future<FirestoreResult<CafeCounterSession>> getSession(
      String counterId) async {
    final col = _sessions;
    if (col == null) {
      return const FirestoreFailure('Firestore tidak tersedia (offline mode)');
    }
    try {
      final snap = await col.doc(counterId).get();
      if (!snap.exists || snap.data() == null) {
        return FirestoreSuccess(CafeCounterSession(
          counterId: counterId,
          updatedAt: DateTime.now(),
        ));
      }
      return FirestoreSuccess(CafeCounterSession.fromMap(snap.data()!));
    } catch (e) {
      debugPrint('FirestoreCounterSessionService.getSession error: $e');
      return FirestoreFailure('Gagal mengambil session', e);
    }
  }
}
