import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_result.dart';
import '../../domain/models/cafe_counter_session.dart';
import '../../domain/models/order_enums.dart';

/// Supabase Data Layer service untuk `counter_sessions`.
/// Mengikuti Clean Architecture: HANYA dipanggil dari Controller / Repository,
/// TIDAK dari widget/view langsung.
///
/// Tabel: `counter_sessions` (e.g. `counter_id = 'KAFE-01'`)
/// Tidak menyimpan raw frames, MediaPipe landmarks, tensor 706-D, atau audio.
class SupabaseCounterSessionService {
  final SupabaseClient? _customSupabase;

  SupabaseCounterSessionService({SupabaseClient? supabase})
      : _customSupabase = supabase;

  /// Lazy null-safe getter — aman digunakan di test tanpa Supabase init.
  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ── WRITE: Upsert session state ──────────────────────────────────────────

  /// Sync stage pesanan ke Supabase (`counter_sessions`) secara real-time.
  Future<SupabaseResult<void>> syncStage(
    String counterId,
    CafeOrderStage stage, {
    String currentOrderId = '',
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      await client.from('counter_sessions').upsert(
        {
          'counter_id': counterId,
          'stage': stage.name,
          'current_order_id': currentOrderId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'counter_id',
      );
      return const SupabaseSuccess(null);
    } catch (e, st) {
      debugPrint('SupabaseCounterSessionService.syncStage error: $e\n$st');
      return SupabaseFailure('Gagal sync stage ke cloud', e);
    }
  }

  /// Pasangkan tablet kasir dan tablet pembeli ke counter session.
  Future<SupabaseResult<void>> pairDevices({
    required String counterId,
    required String cashierTabletId,
    required String customerTabletId,
    required CounterDeviceMode mode,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final modeStr = mode == CounterDeviceMode.dualTabletLocked
          ? 'dualTablet'
          : 'singleTablet';

      await client.from('counter_sessions').upsert(
        {
          'counter_id': counterId,
          'device_mode': modeStr,
          'cashier_tablet_id': cashierTabletId,
          'customer_tablet_id': customerTabletId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'counter_id',
      );
      return const SupabaseSuccess(null);
    } catch (e) {
      debugPrint('SupabaseCounterSessionService.pairDevices error: $e');
      return SupabaseFailure('Gagal menyimpan pairing device', e);
    }
  }

  // ── READ: Real-time stream ────────────────────────────────────────────────

  /// Stream session counter untuk tablet pembeli (real-time sync).
  Stream<CafeCounterSession> streamSession(String counterId) {
    final client = _supabase;
    if (client == null) {
      return Stream.value(CafeCounterSession(
        counterId: counterId,
        updatedAt: DateTime.now(),
      ));
    }
    return client
        .from('counter_sessions')
        .stream(primaryKey: ['counter_id'])
        .eq('counter_id', counterId)
        .map((rows) {
          if (rows.isEmpty) {
            return CafeCounterSession(
              counterId: counterId,
              updatedAt: DateTime.now(),
            );
          }
          return CafeCounterSession.fromMap(rows.first);
        });
  }

  /// One-shot fetch session.
  Future<SupabaseResult<CafeCounterSession>> getSession(
    String counterId,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final row = await client
          .from('counter_sessions')
          .select()
          .eq('counter_id', counterId)
          .maybeSingle();

      if (row == null) {
        return SupabaseSuccess(CafeCounterSession(
          counterId: counterId,
          updatedAt: DateTime.now(),
        ));
      }
      return SupabaseSuccess(CafeCounterSession.fromMap(row));
    } catch (e) {
      debugPrint('SupabaseCounterSessionService.getSession error: $e');
      return SupabaseFailure('Gagal mengambil session', e);
    }
  }
}
