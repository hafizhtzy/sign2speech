import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String text, bool isFinal);

class SpeechService {
  final stt.SpeechToText _speechToText;
  bool _isInitialized = false;
  int _generation = 0;

  SpeechService({stt.SpeechToText? speechToText})
    : _speechToText = speechToText ?? stt.SpeechToText();

  bool get isListening => _speechToText.isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize({void Function(String error)? onError}) async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (val) {
          if (onError != null) onError(val.errorMsg);
        },
        onStatus: (status) {
          debugPrint('SpeechService status: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      if (onError != null) onError(e.toString());
      return false;
    }
  }

  Future<void> startListening({
    String languageCode = 'id_ID',
    required SpeechResultCallback onResult,
  }) async {
    final currentGen = ++_generation;

    if (!_isInitialized) {
      final ready = await initialize();
      if (!ready || currentGen != _generation) return;
    }

    try {
      await _speechToText.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: languageCode,
          listenMode: stt.ListenMode.confirmation,
        ),
        onResult: (result) {
          // Guard against obsolete generations
          if (currentGen == _generation) {
            onResult(result.recognizedWords, result.finalResult);
          }
        },
      );
    } catch (e) {
      debugPrint('SpeechService listen error: $e');
    }
  }

  Future<void> stopListening() async {
    _generation++;
    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('SpeechService stop error: $e');
    }
  }

  Future<void> cancelListening() async {
    _generation++;
    try {
      await _speechToText.cancel();
    } catch (e) {
      debugPrint('SpeechService cancel error: $e');
    }
  }
}
