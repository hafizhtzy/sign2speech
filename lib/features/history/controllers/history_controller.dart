import 'package:get/get.dart';

import '../models/history_item.dart';
import '../services/history_store.dart';

class HistoryController extends GetxController {
  final HistoryStore historyStore;

  final RxList<HistoryItem> items = <HistoryItem>[].obs;
  final RxInt selectedFilterIndex =
      0.obs; // 0: Semua, 1: Sign to Speech, 2: Speech to Sign

  HistoryController({required this.historyStore});

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final list = await historyStore.loadHistory();
    items.assignAll(list);
  }

  List<HistoryItem> get filteredItems {
    if (selectedFilterIndex.value == 1) {
      return items
          .where((e) => e.direction == TranslationDirection.signToSpeech)
          .toList();
    } else if (selectedFilterIndex.value == 2) {
      return items
          .where((e) => e.direction == TranslationDirection.speechToSign)
          .toList();
    }
    return items;
  }

  void setFilter(int index) {
    selectedFilterIndex.value = index;
  }

  Future<void> addHistoryEntry({
    required String original,
    required String translated,
    required TranslationDirection direction,
    String signLanguage = 'BISINDO',
  }) async {
    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalContent: original,
      translatedContent: translated,
      direction: direction,
      signLanguageType: signLanguage,
      timestamp: DateTime.now(),
    );
    await historyStore.saveItem(item);
    items.insert(0, item);
  }

  Future<void> deleteEntry(String id) async {
    await historyStore.deleteItem(id);
    items.removeWhere((e) => e.id == id);
  }

  Future<void> clearAll() async {
    await historyStore.clearHistory();
    items.clear();
  }
}
