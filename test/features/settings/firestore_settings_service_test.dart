import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/firebase/firestore_result.dart';
import 'package:speech2sign/features/settings/services/firestore_settings_service.dart';

void main() {
  group('FirestoreSettingsService Cloud Preferences Sync Tests', () {
    test('Defensive lazy initialization safely returns FirestoreFailure without crashing [core/no-app]', () async {
      final service = FirestoreSettingsService();

      final saveResult = await service.saveSettings('test_user_01', {
        'role': 'Teman Tuli',
        'signLanguage': 'BISINDO',
        'appLanguage': 'id',
        'themeMode': 'system',
        'ttsSpeed': 1.0,
      });

      expect(saveResult, isA<FirestoreFailure<void>>());
      switch (saveResult) {
        case FirestoreSuccess():
          fail('Should fail defensively without Firebase app');
        case FirestoreFailure(:final errorMessage):
          expect(errorMessage.contains('not initialized'), isTrue);
      }

      final fetchResult = await service.fetchSettings('test_user_01');
      expect(fetchResult, isA<FirestoreFailure<Map<String, dynamic>?>>());

      final stream = service.streamSettings('test_user_01');
      expect(await stream.first, isNull);
    });

    test('FirestoreResult correctly represents cloud user settings operations', () {
      final Map<String, dynamic> mockCloudData = {
        'role': 'Teman Tuli',
        'signLanguage': 'BISINDO',
        'appLanguage': 'id',
        'ttsSpeed': 1.25,
      };

      final FirestoreResult<Map<String, dynamic>?> successResult =
          FirestoreSuccess(mockCloudData);

      final role = switch (successResult) {
        FirestoreSuccess(:final data) => data?['role'] ?? 'Unknown',
        FirestoreFailure() => 'Default',
      };

      expect(role, 'Teman Tuli');
    });
  });
}
