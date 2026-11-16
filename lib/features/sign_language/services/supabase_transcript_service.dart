import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_result.dart';
import '../models/sign_token.dart';

/// Production-ready Supabase Service for storing and syncing sign recognition transcripts.
/// Reduces local storage bloat by archiving recognition transcripts to Supabase (`sign_transcripts`).
class SupabaseTranscriptService {
  final SupabaseClient? _customSupabase;

  SupabaseTranscriptService({SupabaseClient? supabase})
      : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Archives a sequence of sign recognition tokens to Supabase (`sign_transcripts` table).
  Future<SupabaseResult<String>> archiveSessionTranscript({
    required String sessionId,
    required List<SignToken> tokens,
    String languageType = 'BISINDO',
    String? sessionNotes,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final docId = sessionId.isNotEmpty
          ? sessionId
          : 'TRX-${DateTime.now().millisecondsSinceEpoch}';

      final tokenMaps = tokens.map((t) => t.toJson()).toList();
      final sentence = tokens.map((t) => t.value).join(' ');

      final payload = <String, dynamic>{
        'transcript_id': docId,
        'session_id': docId,
        'tokens': tokenMaps,
        'full_sentence': sentence,
        'token_count': tokens.length,
        'language_type': languageType,
        'session_notes': sessionNotes ?? '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client.from('sign_transcripts').upsert(
            payload,
            onConflict: 'transcript_id',
          );
      return SupabaseSuccess(docId);
    } catch (e, stack) {
      debugPrint('SupabaseTranscriptService archive error: $e\n$stack');
      return SupabaseFailure('Failed to archive transcript to cloud', e);
    }
  }

  /// Fetches recent transcript sessions from Supabase (`sign_transcripts` table).
  Future<SupabaseResult<List<Map<String, dynamic>>>> fetchRecentTranscripts({
    int limit = 20,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient is not initialized');
    }

    try {
      final rows = await client
          .from('sign_transcripts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final list = rows.map((row) {
        return <String, dynamic>{
          ...row,
          'sessionId': row['session_id'] ?? row['transcript_id'],
          'fullSentence': row['full_sentence'] ?? '',
          'tokenCount': row['token_count'] ?? 0,
          'languageType': row['language_type'] ?? 'BISINDO',
          'sessionNotes': row['session_notes'] ?? '',
        };
      }).toList();
      return SupabaseSuccess(list);
    } catch (e) {
      debugPrint('SupabaseTranscriptService fetch error: $e');
      return SupabaseFailure('Failed to fetch transcripts', e);
    }
  }
}
