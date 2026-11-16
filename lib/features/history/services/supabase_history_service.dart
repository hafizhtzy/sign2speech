import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/history_item.dart';

import '../../../core/supabase/supabase_result.dart';
export '../../../core/supabase/supabase_result.dart';

/// Production-ready Supabase Service adhering to Clean Architecture & Dart 3.
class SupabaseHistoryService {
  final SupabaseClient? _customSupabase;

  SupabaseHistoryService({SupabaseClient? supabase})
      : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Verifies Supabase connectivity by reading/upserting the MVP initialization test row.
  Future<SupabaseResult<Map<String, dynamic>>> testConnection() async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final existing = await client
          .from('test_connection')
          .select()
          .eq('id', 'mvp_init_test')
          .maybeSingle();

      if (existing != null) {
        return SupabaseSuccess(existing);
      } else {
        final probeData = <String, dynamic>{
          'id': 'flutter_client_probe',
          'status': 'Probe active from Flutter client (Sign2Speech Mobile MVP)',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        await client.from('test_connection').upsert(
              probeData,
              onConflict: 'id',
            );
        return SupabaseSuccess(probeData);
      }
    } catch (e, stack) {
      debugPrint('Supabase testConnection error: $e\n$stack');
      return SupabaseFailure('Failed to connect to Supabase', e);
    }
  }

  /// Saves a single history item to Supabase (`translations_history` table).
  Future<SupabaseResult<String>> saveHistory(HistoryItem item) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final payload = item.toPostgresMap();
      await client.from('translations_history').upsert(
            payload,
            onConflict: 'id',
          );
      return SupabaseSuccess(item.id);
    } catch (e) {
      debugPrint('Supabase saveHistory error: $e');
      return SupabaseFailure('Failed to save history to cloud', e);
    }
  }

  /// Fetches translation history items from Supabase (`translations_history` table).
  Future<SupabaseResult<List<HistoryItem>>> fetchHistory({
    int limit = 50,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      final rows = await client
          .from('translations_history')
          .select()
          .order('timestamp', ascending: false)
          .limit(limit);

      final items = rows.map((row) => HistoryItem.fromMap(row)).toList();

      return SupabaseSuccess(items);
    } catch (e) {
      debugPrint('Supabase fetchHistory error: $e');
      return SupabaseFailure('Failed to fetch history from cloud', e);
    }
  }

  /// Realtime Stream of translation history.
  Stream<List<HistoryItem>> watchHistory({int limit = 30}) {
    final client = _supabase;
    if (client == null) {
      return Stream.value(<HistoryItem>[]);
    }
    return client
        .from('translations_history')
        .stream(primaryKey: ['id'])
        .order('timestamp')
        .limit(limit)
        .map((rows) {
          final items = rows.map((row) => HistoryItem.fromMap(row)).toList();
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        });
  }

  /// Deletes a history item by ID from Supabase (`translations_history` table).
  Future<SupabaseResult<void>> deleteHistory(String id) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }
    try {
      await client.from('translations_history').delete().eq('id', id);
      return const SupabaseSuccess(null);
    } catch (e) {
      return SupabaseFailure('Failed to delete history item: $id', e);
    }
  }
}
