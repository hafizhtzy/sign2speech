import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_result.dart';
import '../models/app_user_role.dart';
import '../models/user_profile.dart';

/// Supabase Data Layer service for authentication and authoritative profile lookup.
/// Follows Clean Architecture, Defensive Lazy Initialization, and Least Privilege RBAC.
class SupabaseAuthService {
  final SupabaseClient? _customSupabase;

  SupabaseAuthService({SupabaseClient? supabase}) : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentAuthUser => _supabase?.auth.currentUser;

  Session? get currentSession => _supabase?.auth.currentSession;

  Stream<AuthState> get onAuthStateChange =>
      _supabase?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  /// Signs in an existing user (CUSTOMER, CASHIER, or ADMIN) and immediately
  /// verifies their authoritative `public.profiles` role and active status.
  Future<SupabaseResult<UserProfile>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('Layanan autentikasi belum siap.');
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const SupabaseFailure('Login gagal: pengguna tidak ditemukan.');
      }

      final profileRes = await fetchProfileByUserId(user.id, fallbackUser: user);
      return switch (profileRes) {
        SupabaseSuccess(:final data) => await _validateActiveProfile(client, data),
        SupabaseFailure(:final errorMessage, :final error) =>
          SupabaseFailure(errorMessage, error),
      };
    } on AuthException catch (e) {
      return SupabaseFailure(_mapAuthErrorMessage(e.message), e);
    } catch (e, st) {
      debugPrint('SupabaseAuthService.signInWithPassword error: $e\n$st');
      return SupabaseFailure('Gagal masuk ke akun.', e);
    }
  }

  Future<SupabaseResult<UserProfile>> _validateActiveProfile(
    SupabaseClient client,
    UserProfile profile,
  ) async {
    if (!profile.isActive) {
      await client.auth.signOut();
      return const SupabaseFailure(
        'Akun Anda telah dinonaktifkan oleh Admin. Hubungi pengelola kafe.',
      );
    }
    return SupabaseSuccess(profile);
  }

  /// Self-registration strictly for CUSTOMER accounts.
  /// Never accepts a role parameter; database trigger also enforces `role = 'customer'`.
  Future<SupabaseResult<UserProfile>> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String communicationMode = 'deaf',
    String preferredSignSystem = 'BISINDO',
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('Layanan autentikasi belum siap.');
    }
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = fullName.trim();
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: <String, dynamic>{
          'full_name': cleanName,
          'phone': phone?.trim(),
          'communication_mode': communicationMode,
          'preferred_sign_system': preferredSignSystem,
        },
      );

      final user = response.user;
      if (user == null) {
        return const SupabaseFailure('Registrasi gagal membuat akun.');
      }

      final profileRes = await fetchProfileByUserId(
        user.id,
        fallbackUser: user,
        defaultFullName: cleanName,
        defaultPhone: phone,
        defaultCommunicationMode: communicationMode,
        defaultSignSystem: preferredSignSystem,
      );
      return profileRes;
    } on AuthException catch (e) {
      return SupabaseFailure(_mapAuthErrorMessage(e.message), e);
    } catch (e, st) {
      debugPrint('SupabaseAuthService.registerCustomer error: $e\n$st');
      return SupabaseFailure('Gagal mendaftarkan akun pelanggan.', e);
    }
  }

  /// Fetches the authoritative `public.profiles` record for [userId].
  Future<SupabaseResult<UserProfile>> fetchProfileByUserId(
    String userId, {
    User? fallbackUser,
    String? defaultFullName,
    String? defaultPhone,
    String defaultCommunicationMode = 'deaf',
    String defaultSignSystem = 'BISINDO',
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum terinisialisasi.');
    }
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row != null) {
        return SupabaseSuccess(UserProfile.fromPostgresMap(row));
      }

      // If the profile row was not yet created (e.g. before trigger runs),
      // read ONLY server-controlled `appMetadata['app_role']` and default to customer.
      final user = fallbackUser ?? client.auth.currentUser;
      final serverAppRole = user?.appMetadata['app_role']?.toString();
      final serverStatus = user?.appMetadata['account_status']?.toString();
      final meta = user?.userMetadata ?? const <String, dynamic>{};

      final fallbackProfile = UserProfile(
        id: userId,
        email: user?.email ?? '',
        fullName: defaultFullName ??
            meta['full_name']?.toString() ??
            user?.email?.split('@').first ??
            'Pelanggan',
        phone: defaultPhone ?? meta['phone']?.toString(),
        role: AppUserRole.fromString(serverAppRole),
        status: AccountStatus.fromString(serverStatus),
        communicationMode:
            meta['communication_mode']?.toString() ?? defaultCommunicationMode,
        preferredSignSystem:
            meta['preferred_sign_system']?.toString() ?? defaultSignSystem,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      return SupabaseSuccess(fallbackProfile);
    } catch (e, st) {
      debugPrint('SupabaseAuthService.fetchProfileByUserId error: $e\n$st');
      return SupabaseFailure('Gagal memuat profil pengguna.', e);
    }
  }

  /// Updates only the authenticated user's own editable profile fields.
  Future<SupabaseResult<UserProfile>> updateOwnProfile(
    UserProfile updated,
  ) async {
    final client = _supabase;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null || uid != updated.id) {
      return const SupabaseFailure('Sesi pengguna tidak valid.');
    }
    try {
      final payload = updated.toSelfEditableMap();
      final row = await client
          .from('profiles')
          .update(payload)
          .eq('id', uid)
          .select()
          .single();
      return SupabaseSuccess(UserProfile.fromPostgresMap(row));
    } catch (e, st) {
      debugPrint('SupabaseAuthService.updateOwnProfile error: $e\n$st');
      return SupabaseFailure('Gagal memperbarui profil.', e);
    }
  }

  /// Streams the authenticated user's `public.profiles` row so role changes or
  /// cashier account deactivation by Admin take effect immediately.
  Stream<UserProfile?> streamOwnProfile(String userId) {
    final client = _supabase;
    if (client == null || userId.isEmpty) {
      return const Stream<UserProfile?>.empty();
    }
    return client
        .from('profiles')
        .stream(primaryKey: const ['id'])
        .eq('id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return UserProfile.fromPostgresMap(rows.first);
        });
  }

  Future<SupabaseResult<void>> signOut() async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(null);
    }
    try {
      await client.auth.signOut();
      return const SupabaseSuccess(null);
    } catch (e) {
      return SupabaseFailure('Gagal keluar dari sesi.', e);
    }
  }

  String _mapAuthErrorMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Silakan periksa kotak masuk email Anda.';
    }
    if (lower.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (lower.contains('rate limit') || lower.contains('over_email_send_rate_limit')) {
      return 'Batas pengiriman email tercapai. Matikan Confirm Email di Supabase Dashboard (saat testing) atau tunggu beberapa saat.';
    }
    if (lower.contains('banned') || lower.contains('disabled')) {
      return 'Akun Anda telah dinonaktifkan oleh Admin.';
    }
    return raw;
  }
}
