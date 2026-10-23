import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../../settings/controllers/settings_controller.dart';

class BisindoTtsService {
  final FlutterTts _flutterTts;
  Future<void> _speechChain = Future.value();
  String _currentLanguage = 'id-ID';
  double _currentSpeechRate = 0.5;
  bool _isConfigured = false;

  BisindoTtsService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  String get currentLanguage => _currentLanguage;
  double get currentSpeechRate => _currentSpeechRate;

  String _normalizeLanguageTag(String langCode) {
    if (langCode == 'en' || langCode.toLowerCase().startsWith('en')) {
      return 'en-US';
    }
    return 'id-ID';
  }

  /// Sets the TTS spoken language dynamically ('id' -> 'id-ID', 'en' -> 'en-US').
  Future<void> setLanguage(String langCode) async {
    final target = _normalizeLanguageTag(langCode);
    _currentLanguage = target;
    try {
      await _flutterTts.setLanguage(_currentLanguage);
    } catch (e) {
      debugPrint('BisindoTtsService setLanguage error: $e');
    }
  }

  /// Updates TTS speech rate based on user preference (0.5x to 1.5x).
  Future<void> setSpeechRate(double speed) async {
    _currentSpeechRate = (speed * 0.5).clamp(0.2, 1.0);
    try {
      await _flutterTts.setSpeechRate(_currentSpeechRate);
    } catch (e) {
      debugPrint('BisindoTtsService setSpeechRate error: $e');
    }
  }

  Future<void> _configure({String? languageCode}) async {
    // If languageCode not specified, check active SettingsController
    String targetLang = _currentLanguage;
    if (languageCode != null) {
      targetLang = _normalizeLanguageTag(languageCode);
    } else if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      targetLang = _normalizeLanguageTag(settings.selectedAppLanguage.value);
      _currentSpeechRate = (settings.ttsSpeed.value * 0.5).clamp(0.2, 1.0);
    }

    final needsLanguageUpdate = !_isConfigured || _currentLanguage != targetLang;
    try {
      if (needsLanguageUpdate) {
        _currentLanguage = targetLang;
        await _flutterTts.setLanguage(_currentLanguage);
      }
      if (!_isConfigured) {
        await _flutterTts.setSpeechRate(_currentSpeechRate);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        _isConfigured = true;
      }
    } catch (e) {
      debugPrint('BisindoTtsService config error: $e');
    }
  }

  /// Speaks text using a non-overlapping serial FIFO queue via Future chaining.
  /// Dynamically speaks in [languageCode] (or active app language if null).
  Future<void> speak(String text, {String? languageCode}) {
    final completer = Completer<void>();

    _speechChain = _speechChain.then((_) async {
      await _configure(languageCode: languageCode);
      try {
        final finishCompleter = Completer<void>();

        _flutterTts.setCompletionHandler(() {
          if (!finishCompleter.isCompleted) {
            finishCompleter.complete();
          }
        });

        _flutterTts.setErrorHandler((_) {
          if (!finishCompleter.isCompleted) {
            finishCompleter.complete();
          }
        });

        await _flutterTts.speak(text);

        // Fallback timeout in case completion handler is delayed
        await finishCompleter.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () {},
        );

        completer.complete();
      } catch (e) {
        debugPrint('BisindoTtsService speak error: $e');
        completer.complete();
      }
    });

    return completer.future;
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _speechChain = Future.value();
    } catch (_) {}
  }
}
