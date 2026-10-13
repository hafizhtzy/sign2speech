import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';

class HistoryStore {
  static const String _key = 'sign2speech_translation_history';

  Future<List<HistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key);
    if (jsonList == null) return [];

    return jsonList
        .map(
          (itemStr) =>
              HistoryItem.fromMap(json.decode(itemStr) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveItem(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadHistory();
    current.insert(0, item);
    final stringList = current.map((e) => json.encode(e.toMap())).toList();
    await prefs.setStringList(_key, stringList);
  }

  Future<void> deleteItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadHistory();
    current.removeWhere((element) => element.id == id);
    final stringList = current.map((e) => json.encode(e.toMap())).toList();
    await prefs.setStringList(_key, stringList);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
