import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/supabase/supabase_result.dart';
import 'package:speech2sign/features/sign_language/models/sign_token.dart';
import 'package:speech2sign/features/sign_language/services/supabase_transcript_service.dart';

void main() {
  group('SupabaseTranscriptService Tests', () {
    test('Defensive lazy initialization safely returns SupabaseFailure without crashing in test harness', () async {
      final service = SupabaseTranscriptService();
      final tokens = [
        SignToken(
          value: 'TERIMA',
          type: SignTokenType.word,
          timestamp: DateTime.now(),
        ),
        SignToken(
          value: 'KASIH',
          type: SignTokenType.word,
          timestamp: DateTime.now(),
        ),
      ];

      final archiveResult = await service.archiveSessionTranscript(
        sessionId: 'SESS-100',
        tokens: tokens,
        languageType: 'BISINDO',
      );

      expect(archiveResult, isA<SupabaseFailure<String>>());
      switch (archiveResult) {
        case SupabaseSuccess():
          fail('Should fail defensively without Supabase client');
        case SupabaseFailure(:final errorMessage):
          expect(errorMessage.contains('not initialized'), isTrue);
      }

      final fetchResult = await service.fetchRecentTranscripts();
      expect(fetchResult, isA<SupabaseFailure<List<Map<String, dynamic>>>>());
    });
  });
}
