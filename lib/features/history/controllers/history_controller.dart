import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/history_item.dart';
import '../services/history_store.dart';
import '../services/supabase_history_service.dart';

class HistoryController extends GetxController {
  final HistoryStore historyStore;
  final SupabaseHistoryService? supabaseHistoryService;

  final RxList<HistoryItem> items = <HistoryItem>[].obs;
  final RxInt selectedFilterIndex =
      0.obs; // 0: Semua, 1: Sign to Speech, 2: Speech to Sign
  final RxBool isSyncing = false.obs;

  HistoryController({
    required this.historyStore,
    this.supabaseHistoryService,
  });

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  /// Loads history from Supabase if available, otherwise falls back to local storage.
  Future<void> loadHistory() async {
    isSyncing.value = true;
    try {
      if (supabaseHistoryService != null) {
        final cloudResult =
            await supabaseHistoryService!.fetchHistory(limit: 50);
        switch (cloudResult) {
          case SupabaseSuccess(:final data):
            if (data.isNotEmpty) {
              items.assignAll(data);
              isSyncing.value = false;
              return;
            }
          case SupabaseFailure(:final errorMessage):
            debugPrint('Supabase fetch fallback: $errorMessage');
        }
      }

      // Offline fallback: load from local SharedPreferences
      final localList = await historyStore.loadHistory();
      items.assignAll(localList);
    } finally {
      isSyncing.value = false;
    }
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

    // 1. Always save locally first for instantaneous responsiveness
    await historyStore.saveItem(item);
    items.insert(0, item);

    // 2. Sync to Supabase in the background
    if (supabaseHistoryService != null) {
      final result = await supabaseHistoryService!.saveHistory(item);
      switch (result) {
        case SupabaseSuccess():
          break;
        case SupabaseFailure(:final errorMessage):
          debugPrint('History cloud sync notice: $errorMessage');
      }
    }
  }

  Future<void> deleteEntry(String id) async {
    await historyStore.deleteItem(id);
    items.removeWhere((e) => e.id == id);

    if (supabaseHistoryService != null) {
      final result = await supabaseHistoryService!.deleteHistory(id);
      switch (result) {
        case SupabaseSuccess():
          break;
        case SupabaseFailure(:final errorMessage):
          debugPrint('Supabase delete notice: $errorMessage');
      }
    }
  }

  Future<void> clearAll() async {
    await historyStore.clearHistory();
    items.clear();
  }
}
