import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/models/app_user_role.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_result.dart';
import '../../domain/models/staff_member.dart';

/// Supabase Data Layer service for Admin Staff / Cashier Management (`Phase 6`).
/// Calls the secure `admin-manage-cashier` Edge Function (never uses service_role key in Flutter).
class SupabaseAdminStaffService {
  final SupabaseClient? _customSupabase;

  SupabaseAdminStaffService({SupabaseClient? supabase})
    : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<SupabaseResult<List<StaffMember>>> listCashiers() async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<StaffMember>[]);
    }
    try {
      final response = await client.functions.invoke(
        AppConstants.edgeFnManageCashier,
        body: const <String, dynamic>{'action': 'list_cashiers'},
      );
      final data = response.data;
      if (response.status >= 400 || data is! Map) {
        final err = data is Map ? (data['error']?.toString() ?? '') : '';
        return SupabaseFailure(
          err.isNotEmpty ? err : 'Gagal memuat daftar akun kasir.',
        );
      }
      final rawList = data['cashiers'];
      if (rawList is! List) {
        return const SupabaseSuccess(<StaffMember>[]);
      }
      final staff = rawList
          .whereType<Map>()
          .map((m) => StaffMember.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      return SupabaseSuccess(staff);
    } catch (e, st) {
      debugPrint('SupabaseAdminStaffService.listCashiers error: $e\n$st');
      return SupabaseFailure('Gagal memuat daftar kasir.', e);
    }
  }

  /// Invites a new CASHIER account via Edge Function.
  /// Never accepts a role parameter or password (cashier sets password via activation link).
  Future<SupabaseResult<StaffMember>> inviteCashier({
    required String email,
    required String fullName,
    String? phone,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final response = await client.functions.invoke(
        AppConstants.edgeFnManageCashier,
        body: <String, dynamic>{
          'action': 'invite_cashier',
          'email': email.trim().toLowerCase(),
          'full_name': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      final data = response.data;
      if (response.status >= 400 || data is! Map || data['cashier'] is! Map) {
        final err = data is Map ? (data['error']?.toString() ?? '') : '';
        return SupabaseFailure(
          err.isNotEmpty ? err : 'Gagal mengundang kasir baru.',
        );
      }
      return SupabaseSuccess(
        StaffMember.fromMap(Map<String, dynamic>.from(data['cashier'] as Map)),
      );
    } catch (e) {
      return SupabaseFailure('Gagal mengirim undangan kasir.', e);
    }
  }

  Future<SupabaseResult<StaffMember>> setCashierStatus({
    required String cashierId,
    required AccountStatus targetStatus,
    required String reason,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final response = await client.functions.invoke(
        AppConstants.edgeFnManageCashier,
        body: <String, dynamic>{
          'action': 'set_cashier_status',
          'cashier_id': cashierId,
          'status': targetStatus.dbValue,
          'reason': reason.trim(),
        },
      );
      final data = response.data;
      if (response.status >= 400 || data is! Map || data['cashier'] is! Map) {
        final err = data is Map ? (data['error']?.toString() ?? '') : '';
        return SupabaseFailure(
          err.isNotEmpty ? err : 'Gagal mengubah status akun kasir.',
        );
      }
      return SupabaseSuccess(
        StaffMember.fromMap(Map<String, dynamic>.from(data['cashier'] as Map)),
      );
    } catch (e) {
      return SupabaseFailure('Gagal memperbarui status kasir.', e);
    }
  }
}
