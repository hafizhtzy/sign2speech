import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/supabase/supabase_result.dart';
import 'package:speech2sign/features/settings/services/supabase_settings_service.dart';

void main() {
  group('SupabaseSettingsService Cloud Preferences Sync Tests', () {
    test('Defensive lazy initialization safely returns SupabaseFailure without crashing', () async {
      final service = SupabaseSettingsService();

      final saveResult = await service.saveSettings('test_user_01', {
        'role': 'Teman Tuli',
        'signLanguage': 'BISINDO',
        'appLanguage': 'id',
        'themeMode': 'system',
        'ttsSpeed': 1.0,
      });

      expect(saveResult, isA<SupabaseFailure<void>>());
      switch (saveResult) {
        case SupabaseSuccess():
          fail('Should fail defensively without Supabase client');
        case SupabaseFailure(:final errorMessage):
          expect(errorMessage.contains('not initialized'), isTrue);
      }

      final fetchResult = await service.fetchSettings('test_user_01');
      expect(fetchResult, isA<SupabaseFailure<Map<String, dynamic>?>>());

      final stream = service.streamSettings('test_user_01');
      expect(await stream.first, isNull);
    });

    test('SupabaseResult correctly represents cloud user settings operations', () {
      final Map<String, dynamic> mockCloudData = {
        'role': 'Teman Tuli',
        'signLanguage': 'BISINDO',
        'appLanguage': 'id',
        'ttsSpeed': 1.25,
      };

      final SupabaseResult<Map<String, dynamic>?> successResult =
          SupabaseSuccess(mockCloudData);

      final role = switch (successResult) {
        SupabaseSuccess(:final data) => data?['role'] ?? 'Unknown',
        SupabaseFailure() => 'Default',
      };

      expect(role, 'Teman Tuli');
    });
  });
}
