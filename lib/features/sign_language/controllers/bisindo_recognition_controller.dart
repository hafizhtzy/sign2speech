import 'dart:async';

import 'package:get/get.dart';

import '../models/bisindo_prediction.dart';
import '../models/sign_token.dart';
import '../services/bisindo_tts_service.dart';
import '../services/sign_transcript_store.dart';

class BisindoRecognitionController extends GetxController {
  final BisindoTtsService ttsService;
  final SignTranscriptStore transcriptStore;

  final RxList<SignToken> tokens = <SignToken>[].obs;
  final RxString spellingBuffer = ''.obs;
  final RxString lastRecognizedWord = ''.obs;
  final RxBool isSpeaking = false.obs;

  Timer? _letterSpeechTimer;
  String _lastCommittedWord = '';
  int _lastCommittedTimeMs = 0;
  static const int duplicateCooldownMs = 1200;

  BisindoRecognitionController({
    required this.ttsService,
    required this.transcriptStore,
  });

  @override
  void onInit() {
    super.onInit();
    _loadPersistedTranscript();
  }

  @override
  void onClose() {
    _letterSpeechTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadPersistedTranscript() async {
    final saved = await transcriptStore.loadTranscript();
    if (saved.isNotEmpty) {
      tokens.assignAll(saved);
    }
  }

  String get fullTranscriptText {
    final words = tokens.map((t) => t.value).toList();
    if (spellingBuffer.value.isNotEmpty) {
      words.add(spellingBuffer.value);
    }
    return words.join(' ');
  }

  void handlePrediction(BisindoPrediction prediction) {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (prediction.isLetter) {
      // 1. Buffer letter predictions
      final char = prediction.cleanLabel;
      spellingBuffer.value += char;

      // Reset and trigger 1500ms idle timer to speak complete word
      _letterSpeechTimer?.cancel();
      _letterSpeechTimer = Timer(const Duration(milliseconds: 1500), () {
        commitSpellingBuffer();
      });
    } else {
      // 2. Full word prediction
      final word = prediction.cleanLabel;

      // Cooldown guard (1200ms)
      if (word == _lastCommittedWord &&
          (now - _lastCommittedTimeMs) < duplicateCooldownMs) {
        return;
      }

      // If there was a pending spelling buffer, commit it first
      if (spellingBuffer.value.isNotEmpty) {
        commitSpellingBuffer();
      }

      _lastCommittedWord = word;
      _lastCommittedTimeMs = now;
      lastRecognizedWord.value = word;

      tokens.add(
        SignToken(
          value: word,
          type: SignTokenType.word,
          timestamp: DateTime.now(),
        ),
      );

      // Trigger Indonesian FIFO TTS
      ttsService.speak(word);
      saveCurrentTranscript();
    }
  }

  void commitSpellingBuffer() {
    final bufferedWord = spellingBuffer.value.trim();
    if (bufferedWord.isEmpty) return;

    _letterSpeechTimer?.cancel();
    spellingBuffer.value = '';
    lastRecognizedWord.value = bufferedWord;

    tokens.add(
      SignToken(
        value: bufferedWord,
        type: SignTokenType.word,
        timestamp: DateTime.now(),
      ),
    );

    // Speak entire word cleanly (e.g. "BELI") instead of "B...E...L...I"
    ttsService.speak(bufferedWord);
    saveCurrentTranscript();
  }

  void insertSpace() {
    if (spellingBuffer.value.isNotEmpty) {
      commitSpellingBuffer();
    }
  }

  Future<void> saveCurrentTranscript() async {
    await transcriptStore.saveTranscript(tokens);
  }

  Future<void> replayLastOrFullTranscript() async {
    final text = fullTranscriptText;
    if (text.isNotEmpty) {
      await ttsService.speak(text);
    }
  }

  Future<void> resetTranscript() async {
    _letterSpeechTimer?.cancel();
    spellingBuffer.value = '';
    lastRecognizedWord.value = '';
    _lastCommittedWord = '';
    tokens.clear();
    await ttsService.stop();
    await transcriptStore.clearTranscript();
  }
}
