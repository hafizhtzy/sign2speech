import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BisindoTtsService {
  final FlutterTts _flutterTts;
  Future<void> _speechChain = Future.value();
  bool _isConfigured = false;

  BisindoTtsService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  Future<void> _configure() async {
    if (_isConfigured) return;
    try {
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isConfigured = true;
    } catch (e) {
      debugPrint('BisindoTtsService config error: $e');
    }
  }

  /// Speaks text using a non-overlapping serial FIFO queue via Future chaining.
  Future<void> speak(String text) {
    final completer = Completer<void>();

    _speechChain = _speechChain.then((_) async {
      await _configure();
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
