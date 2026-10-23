import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/cafe_order_ticket.dart';
import '../../domain/models/coffee_customization_draft.dart';

/// Local data source for caching Cafe POS active order tickets and drink customization drafts.
/// Adheres to Clean Architecture and accepts an optional [SharedPreferences] for easy unit testing.
class CafePosLocalDataSource {
  static const String _activeTicketKey = 'cafe_pos_active_ticket_v1';
  static const String _draftCustomizationPrefix = 'cafe_pos_draft_customization_v1_';

  final SharedPreferences? _injectedPrefs;

  CafePosLocalDataSource({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _injectedPrefs ?? await SharedPreferences.getInstance();
  }

  // ── ACTIVE ORDER TICKET PERSISTENCE ────────────────────────────────────────

  /// Loads the saved active order ticket from local storage.
  /// Returns null if no active ticket is saved or if corrupted.
  Future<CafeOrderTicket?> loadActiveTicket() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_activeTicketKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return null;
      }

      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return CafeOrderTicket.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Persists the current active ticket to local storage.
  Future<void> saveActiveTicket(CafeOrderTicket ticket) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = json.encode(ticket.toMap());
      await prefs.setString(_activeTicketKey, jsonStr);
    } catch (_) {}
  }

  /// Clears the active order ticket from local storage.
  Future<void> clearActiveTicket() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_activeTicketKey);
    } catch (_) {}
  }

  // ── COFFEE CUSTOMIZATION DRAFT PERSISTENCE ─────────────────────────────────

  /// Loads the saved customization draft for a specific drink ID.
  Future<CoffeeCustomizationDraft?> loadCustomizationDraft(String drinkId) async {
    try {
      final prefs = await _getPrefs();
      final key = '$_draftCustomizationPrefix$drinkId';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return null;
      }

      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return CoffeeCustomizationDraft.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Persists the customized options draft for a specific drink.
  Future<void> saveCustomizationDraft(CoffeeCustomizationDraft draft) async {
    try {
      final prefs = await _getPrefs();
      final key = '$_draftCustomizationPrefix${draft.drinkId}';
      final jsonStr = json.encode(draft.toMap());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  /// Clears the customization draft for a specific drink after adding to ticket.
  Future<void> clearCustomizationDraft(String drinkId) async {
    try {
      final prefs = await _getPrefs();
      final key = '$_draftCustomizationPrefix$drinkId';
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Clears all coffee customization drafts.
  Future<void> clearAllCustomizationDrafts() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys().where((k) => k.startsWith(_draftCustomizationPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  // ── DIGITAL LOYALTY STAMPS ("SAHABAT TEMAN TULI") ─────────────────────────
  static const String _loyaltyStampKey = 'cafe_pos_loyalty_stamps_count';

  /// Loads the total digital loyalty stamps earned from learning sign language.
  Future<int> loadLoyaltyStamps() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt(_loyaltyStampKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increments and saves a digital loyalty stamp for "Sahabat Teman Tuli".
  Future<int> addLoyaltyStamp() async {
    try {
      final prefs = await _getPrefs();
      final current = prefs.getInt(_loyaltyStampKey) ?? 0;
      final updated = current + 1;
      await prefs.setInt(_loyaltyStampKey, updated);
      return updated;
    } catch (_) {
      return 0;
    }
  }
}

