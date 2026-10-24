import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/firebase/firestore_result.dart';
import 'package:speech2sign/features/sign_language/models/sign_token.dart';
import 'package:speech2sign/features/sign_language/services/firestore_transcript_service.dart';

void main() {
  group('FirestoreTranscriptService Tests', () {
    test('Defensive lazy initialization safely returns FirestoreFailure without crashing in test harness', () async {
      final service = FirestoreTranscriptService();
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

      expect(archiveResult, isA<FirestoreFailure<String>>());
      switch (archiveResult) {
        case FirestoreSuccess():
          fail('Should fail defensively without Firebase app');
        case FirestoreFailure(:final errorMessage):
          expect(errorMessage.contains('not initialized'), isTrue);
      }

      final fetchResult = await service.fetchRecentTranscripts();
      expect(fetchResult, isA<FirestoreFailure<List<Map<String, dynamic>>>>());
    });
  });
}
