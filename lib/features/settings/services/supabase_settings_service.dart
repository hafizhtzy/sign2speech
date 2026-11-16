import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_result.dart';

/// Production-ready Supabase Service for syncing user preferences & accessibility settings.
/// Adheres to Clean Architecture, Defensive Lazy Initialization, and Dart 3 sealed class modeling.
class SupabaseSettingsService {
  final SupabaseClient? _customSupabase;

  SupabaseSettingsService({SupabaseClient? supabase})
      : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Normalizes role string to PostgreSQL CHECK constraint values (`deaf`, `hearing`, `cashier`).
  String _normalizeRole(dynamic rawRole) {
    final role = (rawRole ?? 'deaf').toString().trim();
    switch (role.toLowerCase()) {
      case 'teman tuli':
      case 'deaf':
        return 'deaf';
      case 'teman dengar':
      case 'hearing':
        return 'hearing';
      case 'kasir':
      case 'cashier':
        return 'cashier';
      default:
        return 'deaf';
    }
  }

  /// Maps PostgreSQL snake_case row back to include camelCase keys expected by callers.
  Map<String, dynamic> _fromPostgresRow(Map<String, dynamic> row) {
    return <String, dynamic>{
      ...row,
      'userId': row['user_id'] ?? row['userId'] ?? 'default_user',
      'role': row['role'] ?? 'deaf',
      'signLanguage': row['sign_language'] ?? row['signLanguage'] ?? 'BISINDO',
      'appLanguage': row['app_language'] ?? row['appLanguage'] ?? 'id',
      'themeMode': row['theme_mode'] ?? row['themeMode'] ?? 'system',
      'ttsSpeed': (row['tts_speed'] ?? row['ttsSpeed'] ?? 1.0 as num).toDouble(),
      'videoSpeed':
          (row['video_speed'] ?? row['videoSpeed'] ?? 1.0 as num).toDouble(),
      'hasCompletedOnboarding': row['has_completed_onboarding'] ??
          row['hasCompletedOnboarding'] ??
          false,
    };
  }

  /// Saves user settings to Supabase (`user_settings` table).
  Future<SupabaseResult<void>> saveSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final payload = <String, dynamic>{
        'user_id': userId.isNotEmpty ? userId : 'default_user',
        'role': _normalizeRole(settings['role']),
        'sign_language':
            settings['signLanguage'] ?? settings['sign_language'] ?? 'BISINDO',
        'app_language':
            settings['appLanguage'] ?? settings['app_language'] ?? 'id',
        'theme_mode':
            settings['themeMode'] ?? settings['theme_mode'] ?? 'system',
        'tts_speed': settings['ttsSpeed'] ?? settings['tts_speed'] ?? 1.0,
        'video_speed': settings['videoSpeed'] ?? settings['video_speed'] ?? 1.0,
        'has_completed_onboarding': settings['hasCompletedOnboarding'] ??
            settings['has_completed_onboarding'] ??
            false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client.from('user_settings').upsert(
            payload,
            onConflict: 'user_id',
          );
      return const SupabaseSuccess(null);
    } catch (e, stack) {
      debugPrint('SupabaseSettingsService saveSettings error: $e\n$stack');
      return SupabaseFailure('Failed to save settings to cloud', e);
    }
  }

  /// Fetches user settings from Supabase (`user_settings` table).
  Future<SupabaseResult<Map<String, dynamic>?>> fetchSettings(
    String userId,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final row = await client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        return const SupabaseSuccess(null);
      }
      return SupabaseSuccess(_fromPostgresRow(row));
    } catch (e) {
      debugPrint('SupabaseSettingsService fetchSettings error: $e');
      return SupabaseFailure('Failed to fetch settings from cloud', e);
    }
  }

  /// Realtime stream of user settings.
  Stream<Map<String, dynamic>?> streamSettings(String userId) {
    final client = _supabase;
    if (client == null) {
      return Stream.value(null);
    }

    return client
        .from('user_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return _fromPostgresRow(rows.first);
        });
  }
}
