import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/history_item.dart';
import '../services/firestore_history_service.dart';
import '../services/history_store.dart';

class HistoryController extends GetxController {
  final HistoryStore historyStore;
  final FirestoreHistoryService? firestoreHistoryService;

  final RxList<HistoryItem> items = <HistoryItem>[].obs;
  final RxInt selectedFilterIndex =
      0.obs; // 0: Semua, 1: Sign to Speech, 2: Speech to Sign
  final RxBool isSyncing = false.obs;

  HistoryController({
    required this.historyStore,
    this.firestoreHistoryService,
  });

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  /// Loads history from Cloud Firestore if available, otherwise falls back to local storage.
  Future<void> loadHistory() async {
    isSyncing.value = true;
    try {
      if (firestoreHistoryService != null) {
        final cloudResult =
            await firestoreHistoryService!.fetchHistory(limit: 50);
        switch (cloudResult) {
          case FirestoreSuccess(:final data):
            if (data.isNotEmpty) {
              items.assignAll(data);
              isSyncing.value = false;
              return;
            }
          case FirestoreFailure(:final errorMessage):
            debugPrint('Firestore fetch fallback: $errorMessage');
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

    // 2. Sync to Cloud Firestore in the background
    if (firestoreHistoryService != null) {
      final result = await firestoreHistoryService!.saveHistory(item);
      switch (result) {
        case FirestoreSuccess():
          break;
        case FirestoreFailure(:final errorMessage):
          debugPrint('History cloud sync notice: $errorMessage');
      }
    }
  }

  Future<void> deleteEntry(String id) async {
    await historyStore.deleteItem(id);
    items.removeWhere((e) => e.id == id);

    if (firestoreHistoryService != null) {
      final result = await firestoreHistoryService!.deleteHistory(id);
      switch (result) {
        case FirestoreSuccess():
          break;
        case FirestoreFailure(:final errorMessage):
          debugPrint('Firestore delete notice: $errorMessage');
      }
    }
  }

  Future<void> clearAll() async {
    await historyStore.clearHistory();
    items.clear();
  }
}
