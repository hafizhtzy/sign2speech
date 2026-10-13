import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';
import 'package:speech2sign/features/sign_language/models/sign_video_entry.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_repository.dart';
import 'package:speech2sign/features/translator/services/speech_service.dart';

class MockSpeechService extends SpeechService {
  bool listening = false;
  SpeechResultCallback? resultCallback;

  @override
  bool get isListening => listening;

  @override
  Future<void> startListening({
    String languageCode = 'id_ID',
    required SpeechResultCallback onResult,
  }) async {
    listening = true;
    resultCallback = onResult;
  }

  @override
  Future<void> stopListening() async {
    listening = false;
  }

  void simulateSpeech(String text, bool isFinal) {
    if (resultCallback != null) {
      resultCallback!(text, isFinal);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSpeechService mockSpeechService;
  late SignLanguageRepository repository;
  late TextToSignController controller;

  setUp(() async {
    Get.testMode = true;
    mockSpeechService = MockSpeechService();
    repository = SignLanguageRepository(
      catalog: SignLanguageCatalog.defaultCatalog(),
    );
    controller = TextToSignController(
      speechService: mockSpeechService,
      repository: repository,
    );
    await controller.loadAvailableVideos();
  });

  tearDown(() {
    Get.reset();
  });

  group('TextToSignController Tests', () {
    test('Toggles voice recognition status', () async {
      expect(controller.isListening.value, isFalse);
      await controller.toggleVoiceRecognition();
      expect(controller.isListening.value, isTrue);
      await controller.toggleVoiceRecognition();
      expect(controller.isListening.value, isFalse);
    });

    test(
      'isFinal == true triggers automatic search and populates playlist',
      () async {
        await controller.toggleVoiceRecognition();
        mockSpeechService.simulateSpeech('terima kasih', true);
        await Future.delayed(const Duration(milliseconds: 10));

        // Should automatically stop listening and search
        expect(controller.isListening.value, isFalse);
        expect(controller.playlist.length, equals(1));
        expect(controller.playlist.first.label, equals('Terima Kasih'));
        expect(controller.activeWordIndex.value, equals(0));
      },
    );

    test(
      '_playSessionId guards against stale asynchronous voice inputs',
      () async {
        await controller.toggleVoiceRecognition();
        final initialSession = controller.playSessionId.value;

        controller.onSpeechResult('halo', false);
        expect(controller.recognizedWords.value, equals('halo'));

        // New input increments session id
        await controller.processVoiceInput('beli obat');
        expect(controller.playSessionId.value, greaterThan(initialSession));
        expect(controller.playlist.length, equals(2));
        expect(controller.playlist[0].label, equals('Beli'));
        expect(controller.playlist[1].label, equals('Obat'));
      },
    );

    test('onVideoFinished advances playlist index or loops', () async {
      const entry1 = SignVideoEntry(
        id: '1',
        label: 'Satu',
        aliases: [],
        category: 'test',
        assetPath: '',
        remoteUrl: '',
      );
      const entry2 = SignVideoEntry(
        id: '2',
        label: 'Dua',
        aliases: [],
        category: 'test',
        assetPath: '',
        remoteUrl: '',
      );

      controller.playlist.assignAll([entry1, entry2]);
      controller.activeWordIndex.value = 0;

      controller.onVideoFinished();
      expect(controller.activeWordIndex.value, equals(1));

      // Reaching the end loops to index 0 when loop is active
      controller.isLooping.value = true;
      controller.onVideoFinished();
      expect(controller.activeWordIndex.value, equals(0));
    });

    test('Autocomplete suggestions filters candidate dictionary correctly', () {
      controller.updateSearchQuery('bai');
      expect(controller.searchSuggestions.isNotEmpty, isTrue);
      expect(controller.searchSuggestions.any((s) => s.toLowerCase() == 'baik'), isTrue);
      expect(controller.showSuggestions.value, isTrue);

      controller.dismissSuggestions();
      expect(controller.showSuggestions.value, isFalse);
    });

    test('selectSuggestion updates query and triggers search', () async {
      controller.selectSuggestion('Baik');
      await controller.searchSign('Baik', force: true);
      expect(controller.currentQuery.value, equals('Baik'));
      expect(controller.textController.text, equals('Baik'));
      expect(controller.currentEntry.value, isNotNull);
      expect(controller.currentEntry.value!.label, equals('Baik'));
      expect(
        controller.currentEntry.value!.remoteUrl,
        equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'),
      );
    });

    test('dynamicPackageCategories groups available videos into packages', () {
      final packages = controller.dynamicPackageCategories;
      expect(packages.isNotEmpty, isTrue);
      expect(packages.any((p) => p.title.contains('Salam') || p.category == 'salam'), isTrue);
    });

    test('Vocabulary pagination divides into 5 items per page', () {
      expect(TextToSignController.vocabPageSize, equals(5));
      final paginated = controller.paginatedVocabulary;
      expect(paginated.length, lessThanOrEqualTo(5));

      final total = controller.totalVocabPages;
      expect(total, greaterThanOrEqualTo(1));

      if (total > 1) {
        controller.nextVocabPage();
        expect(controller.currentVocabPage.value, equals(2));
        controller.previousVocabPage();
        expect(controller.currentVocabPage.value, equals(1));
      }
    });
  });
}
