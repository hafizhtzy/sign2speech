import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sign_token.dart';

class SignTranscriptStore {
  static const String keyTranscript = 'sign2speech_transcript_v1';

  Future<void> saveTranscript(List<SignToken> tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tokens.map((t) => t.toJson()).toList();
    await prefs.setString(keyTranscript, jsonEncode(jsonList));
  }

  Future<List<SignToken>> loadTranscript() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyTranscript);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => SignToken.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearTranscript() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyTranscript);
  }
}
