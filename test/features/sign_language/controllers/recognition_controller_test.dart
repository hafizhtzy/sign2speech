import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:speech2sign/features/sign_language/models/bisindo_prediction.dart';
import 'package:speech2sign/features/sign_language/models/sign_token.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_transcript_store.dart';

import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/features/sign_language/services/sign_translation_service.dart';

class MockTtsService extends BisindoTtsService {
  final List<String> spokenWords = [];
  final List<String?> spokenLanguages = [];

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    spokenWords.add(text);
    spokenLanguages.add(languageCode);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTts;
  late SignTranscriptStore store;
  late SignTranslationService translationService;
  late SettingsController settingsController;
  late BisindoRecognitionController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    mockTts = MockTtsService();
    store = SignTranscriptStore();
    translationService = SignTranslationService();
    settingsController = SettingsController();
    Get.put<SettingsController>(settingsController);

    controller = BisindoRecognitionController(
      ttsService: mockTts,
      transcriptStore: store,
      translationService: translationService,
    );
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  group('BisindoRecognitionController Tests', () {
    test(
      'Directly commits and speaks full words with duplicate cooldown',
      () async {
        const predWord = BisindoPrediction(
          label: 'WORD_HALO',
          confidence: 0.90,
          margin: 0.30,
          isLetter: false,
        );

        controller.handlePrediction(predWord);
        expect(controller.tokens.length, equals(1));
        expect(controller.tokens.first.value, equals('Halo'));
        expect(mockTts.spokenWords, contains('Halo'));

        // Duplicate within 1200ms is rejected
        controller.handlePrediction(predWord);
        expect(controller.tokens.length, equals(1));
        expect(mockTts.spokenWords.length, equals(1));
      },
    );

    test('Buffers letter predictions without immediate TTS, speaks full word after idle or space', () async {
      const predB = BisindoPrediction(
        label: 'LETTER_B',
        confidence: 0.90,
        margin: 0.30,
        isLetter: true,
      );
      const predE = BisindoPrediction(
        label: 'LETTER_E',
        confidence: 0.90,
        margin: 0.30,
        isLetter: true,
      );
      const predL = BisindoPrediction(
        label: 'LETTER_L',
        confidence: 0.90,
        margin: 0.30,
        isLetter: true,
      );
      const predI = BisindoPrediction(
        label: 'LETTER_I',
        confidence: 0.90,
        margin: 0.30,
        isLetter: true,
      );

      controller.handlePrediction(predB);
      controller.handlePrediction(predE);
      controller.handlePrediction(predL);
      controller.handlePrediction(predI);

      expect(controller.spellingBuffer.value, equals('BELI'));
      expect(mockTts.spokenWords, isEmpty); // Not spoken letter-by-letter!

      // Explicit space commits word "BELI" to tokens and triggers TTS
      controller.insertSpace();
      expect(controller.spellingBuffer.value, isEmpty);
      expect(controller.tokens.any((t) => t.value == 'BELI'), isTrue);
      expect(mockTts.spokenWords, contains('BELI'));
    });

    test('Persists transcript and survives model toggle', () async {
      controller.tokens.add(
        SignToken(
          value: 'Selamat Pagi',
          type: SignTokenType.word,
          timestamp: DateTime.now(),
        ),
      );

      await controller.saveCurrentTranscript();

      final reloaded = await store.loadTranscript();
      expect(reloaded.length, equals(1));
      expect(reloaded.first.value, equals('Selamat Pagi'));
    });

    test('Speaks translated English text with en-US locale when English language is active', () async {
      settingsController.selectedAppLanguage.value = 'en';

      const predHalo = BisindoPrediction(
        label: 'WORD_HALO',
        confidence: 0.95,
        margin: 0.40,
        isLetter: false,
      );

      controller.handlePrediction(predHalo);
      expect(controller.tokens.first.value, equals('Halo'));
      // Translated transcript text should be "Hello"
      expect(controller.translatedTranscriptText, equals('Hello'));
      // Spoken text should be English "Hello" with en-US locale
      expect(mockTts.spokenWords, contains('Hello'));
      expect(mockTts.spokenLanguages, contains('en-US'));
    });
  });
}
