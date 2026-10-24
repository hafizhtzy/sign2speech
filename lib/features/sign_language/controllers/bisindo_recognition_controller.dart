import 'dart:async';

import 'package:get/get.dart';

import '../../settings/controllers/settings_controller.dart';
import '../models/bisindo_prediction.dart';
import '../models/sign_token.dart';
import '../services/bisindo_tts_service.dart';
import '../services/sign_transcript_store.dart';
import '../services/sign_translation_service.dart';

class BisindoRecognitionController extends GetxController {
  final BisindoTtsService ttsService;
  final SignTranscriptStore transcriptStore;
  final SignTranslationService translationService;

  final RxList<SignToken> tokens = <SignToken>[].obs;
  final RxString spellingBuffer = ''.obs;
  final RxString lastRecognizedWord = ''.obs;
  final RxBool isCameraActive = false.obs;
  final RxBool isHandDetected = false.obs;
  final RxDouble currentConfidenceThreshold = 0.70.obs;
  final RxInt currentStablePredictionsRequired = 3.obs;

  Timer? _letterSpeechTimer;
  String _lastCommittedWord = '';
  int _lastCommittedTimeMs = 0;
  static const int duplicateCooldownMs = 1200;

  BisindoRecognitionController({
    required this.ttsService,
    required this.transcriptStore,
    SignTranslationService? translationService,
  }) : translationService = translationService ?? SignTranslationService();

  void setModelThresholds({
    double? confidenceThreshold,
    int? stablePredictionsRequired,
  }) {
    if (confidenceThreshold != null) {
      currentConfidenceThreshold.value = confidenceThreshold;
    }
    if (stablePredictionsRequired != null) {
      currentStablePredictionsRequired.value = stablePredictionsRequired;
    }
  }

  void setCameraActive(bool active) {
    isCameraActive.value = active;
    if (!active) {
      isHandDetected.value = false;
    }
  }

  void registerHandFrame() {
    isHandDetected.value = true;
  }

  void resetRecognitionState() {
    _letterSpeechTimer?.cancel();
    spellingBuffer.value = '';
    _lastCommittedWord = '';
  }

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

  /// Full raw transcript text in original sign language / Indonesian representation
  String get fullTranscriptText {
    final words = tokens.map((t) => t.value).toList();
    if (spellingBuffer.value.isNotEmpty) {
      words.add(spellingBuffer.value);
    }
    return words.join(' ');
  }

  /// Translated transcript in English
  String get translatedTranscriptText {
    return translationService.translateToEnglish(fullTranscriptText);
  }

  /// Returns localized transcript based on current app language setting
  String get localizedTranscriptText {
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      if (settings.selectedAppLanguage.value == 'en') {
        return translatedTranscriptText;
      }
    }
    return fullTranscriptText;
  }

  /// Speaks text dynamically using the user's selected language
  Future<void> _speakText(String indonesianText) async {
    final clean = indonesianText.trim();
    if (clean.isEmpty) return;

    bool isEnglish = false;
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      isEnglish = settings.selectedAppLanguage.value == 'en';
    }

    final textToSpeak = isEnglish
        ? translationService.translateToEnglish(clean)
        : clean;
    final langCode = isEnglish ? 'en-US' : 'id-ID';

    await ttsService.speak(textToSpeak, languageCode: langCode);
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

      // Trigger Dynamic FIFO TTS in chosen language
      _speakText(word);
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

    // Speak entire word cleanly (e.g. "BELI" or "Buy")
    _speakText(bufferedWord);
    saveCurrentTranscript();
  }

  void insertSpace() {
    if (spellingBuffer.value.isNotEmpty) {
      commitSpellingBuffer();
    }
    if (tokens.isNotEmpty && tokens.last.type != SignTokenType.space) {
      tokens.add(
        SignToken(
          value: ' ',
          type: SignTokenType.space,
          timestamp: DateTime.now(),
        ),
      );
      saveCurrentTranscript();
    }
  }

  void deleteLast() {
    if (spellingBuffer.value.isNotEmpty) {
      final current = spellingBuffer.value;
      spellingBuffer.value = current.substring(0, current.length - 1);
    } else if (tokens.isNotEmpty) {
      tokens.removeLast();
      saveCurrentTranscript();
    }
  }

  void commitWord(String word, {bool speak = true}) {
    if (word.trim().isEmpty) return;
    final clean = word.trim();
    if (spellingBuffer.value.isNotEmpty) {
      commitSpellingBuffer();
    }
    tokens.add(
      SignToken(
        value: clean,
        type: SignTokenType.word,
        timestamp: DateTime.now(),
      ),
    );
    lastRecognizedWord.value = clean;
    if (speak) {
      _speakText(clean);
    }
    saveCurrentTranscript();
  }

  Future<void> speakTranscript() async {
    await replayLastOrFullTranscript();
  }

  Future<void> saveCurrentTranscript() async {
    await transcriptStore.saveTranscript(tokens);
  }

  Future<void> replayLastOrFullTranscript() async {
    final text = fullTranscriptText;
    if (text.isNotEmpty) {
      await _speakText(text);
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
