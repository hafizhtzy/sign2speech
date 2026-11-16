import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/history/models/history_item.dart';
import 'package:speech2sign/features/history/services/supabase_history_service.dart';

void main() {
  group('SupabaseHistoryService & Result Modeling Tests', () {
    test('SupabaseResult pattern matching handles Success and Failure variants cleanly', () {
      const SupabaseResult<String> success = SupabaseSuccess('doc_12345');
      const SupabaseResult<String> failure = SupabaseFailure('Network timeout');

      final successOutcome = switch (success) {
        SupabaseSuccess(:final data) => 'Saved: $data',
        SupabaseFailure(:final errorMessage) => 'Error: $errorMessage',
      };

      final failureOutcome = switch (failure) {
        SupabaseSuccess(:final data) => 'Saved: $data',
        SupabaseFailure(:final errorMessage) => 'Error: $errorMessage',
      };

      expect(successOutcome, 'Saved: doc_12345');
      expect(failureOutcome, 'Error: Network timeout');
    });

    test('HistoryItem serialized map matches Supabase schema constraints', () {
      final now = DateTime(2026, 10, 24, 14, 0, 0);
      final item = HistoryItem(
        id: 'test_hist_01',
        originalContent: 'Halo',
        translatedContent: 'Halo',
        direction: TranslationDirection.signToSpeech,
        signLanguageType: 'BISINDO',
        timestamp: now,
      );

      final map = item.toMap();
      expect(map['id'], 'test_hist_01');
      expect(map['originalContent'], 'Halo');
      expect(map['translatedContent'], 'Halo');
      expect(map['direction'], 0);
      expect(map['signLanguageType'], 'BISINDO');
      expect(map['timestamp'], now.toIso8601String());

      final reconstituted = HistoryItem.fromMap(map);
      expect(reconstituted.id, item.id);
      expect(reconstituted.originalContent, item.originalContent);
      expect(reconstituted.direction, TranslationDirection.signToSpeech);
    });
  });
}
