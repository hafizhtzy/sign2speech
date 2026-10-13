import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/features/history/controllers/history_controller.dart';
import 'package:speech2sign/features/history/models/history_item.dart';
import 'package:speech2sign/features/history/services/history_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('History Store & Controller Tests', () {
    late HistoryStore store;
    late HistoryController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = HistoryStore();
      controller = HistoryController(historyStore: store);
    });

    test('Add, filter, and clear history entries', () async {
      await controller.addHistoryEntry(
        original: 'Gestur Halo',
        translated: 'Halo',
        direction: TranslationDirection.signToSpeech,
        signLanguage: 'BISINDO',
      );

      await controller.addHistoryEntry(
        original: 'Terima kasih',
        translated: 'Peragaan Terima Kasih',
        direction: TranslationDirection.speechToSign,
        signLanguage: 'BISINDO',
      );

      expect(controller.items.length, 2);

      // Filter: Sign to Speech (index 1)
      controller.setFilter(1);
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.translatedContent, 'Halo');

      // Filter: Speech to Sign (index 2)
      controller.setFilter(2);
      expect(controller.filteredItems.length, 1);
      expect(
        controller.filteredItems.first.translatedContent,
        'Peragaan Terima Kasih',
      );

      // Filter: Semua (index 0)
      controller.setFilter(0);
      expect(controller.filteredItems.length, 2);

      // Clear all
      await controller.clearAll();
      expect(controller.items.isEmpty, isTrue);
    });
  });
}
