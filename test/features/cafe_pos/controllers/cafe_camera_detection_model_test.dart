import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_mini_camera_viewport.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/features/sign_language/controllers/sign_language_controller.dart';
import 'package:speech2sign/features/sign_language/models/bisindo_prediction.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_classifier_service.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech2sign/features/translator/services/speech_service.dart';

class MockCameraFeedService extends CameraFeedService {
  bool startCameraCalled = false;
  bool stopCameraCalled = false;

  @override
  Future<bool> startCamera() async {
    startCameraCalled = true;
    isCameraActive.value = true;
    isInitialized.value = true;
    return true;
  }

  @override
  Future<void> stopCamera() async {
    stopCameraCalled = true;
    isCameraActive.value = false;
    isInitialized.value = false;
  }
}

class MockSignLanguageController extends SignLanguageController {
  bool startContinuousCalled = false;
  bool stopContinuousCalled = false;
  SignLanguageModel? lastSwitchedModel;

  MockSignLanguageController({
    required super.classifierService,
    required super.cameraFeedService,
  });

  @override
  Future<void> startContinuous() async {
    startContinuousCalled = true;
    isContinuousRunning.value = true;
    isCameraActive.value = true;
  }

  @override
  Future<void> stopContinuous() async {
    stopContinuousCalled = true;
    isContinuousRunning.value = false;
    isCameraActive.value = false;
  }

  @override
  Future<void> switchModel(SignLanguageModel targetModel) async {
    lastSwitchedModel = targetModel;
    currentModel.value = targetModel;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late CafeCashierController controller;
  late MockCameraFeedService mockCamera;
  late MockSignLanguageController mockSignCtrl;
  late SettingsController settingsController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;

    settingsController = SettingsController();
    Get.put<SettingsController>(settingsController);

    mockCamera = MockCameraFeedService();
    mockSignCtrl = MockSignLanguageController(
      classifierService: BisindoClassifierService(),
      cameraFeedService: mockCamera,
    );

    controller = CafeCashierController(
      cameraFeedService: mockCamera,
      signLanguageController: mockSignCtrl,
      ttsService: BisindoTtsService(),
      speechService: SpeechService(),
    );
    Get.put<CafeCashierController>(controller);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  group('Cafe Cashier Sign Language Model Selection & Synchronization', () {
    test('defaults to BISINDO or syncs with SettingsController', () {
      expect(controller.activeSignModel, SignLanguageModel.bisindo);
      expect(
        controller.currentChallengeVocabulary,
        CafeCashierController.challengeVocabulary,
      );
    });

    test('switching model to SIBI updates activeSignModel, settings, and vocabulary', () async {
      await controller.switchSignLanguageModel(SignLanguageModel.sibi);

      expect(controller.activeSignModel, SignLanguageModel.sibi);
      expect(settingsController.selectedSignLanguage.value, 'SIBI');
      expect(mockSignCtrl.lastSwitchedModel, SignLanguageModel.sibi);
      expect(
        controller.currentChallengeVocabulary,
        CafeCashierController.sibiChallengeVocabulary,
      );
    });

    test('settings change to SIBI automatically synchronizes CafeCashierController', () async {
      settingsController.setSignLanguage('SIBI');
      // Allow GetX ever worker to fire
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.activeSignModel, SignLanguageModel.sibi);
      expect(
        controller.currentChallengeVocabulary,
        CafeCashierController.sibiChallengeVocabulary,
      );
    });
  });

  group('Cafe Cashier Camera Pipeline Activation & Teardown', () {
    test('opening camera starts continuous detection on sign language controller', () async {
      await controller.openCameraFor(CafeCameraActiveFeature.liveOrder);

      expect(controller.activeCameraFeature.value, CafeCameraActiveFeature.liveOrder);
      expect(mockSignCtrl.startContinuousCalled, isTrue);
      expect(mockSignCtrl.onPredictionAccepted, isNotNull);
    });

    test('closing camera stops continuous detection and resets state', () async {
      await controller.openCameraFor(CafeCameraActiveFeature.cupNameSpelling);
      await controller.closeCamera();

      expect(controller.activeCameraFeature.value, CafeCameraActiveFeature.none);
      expect(mockSignCtrl.stopContinuousCalled, isTrue);
      expect(controller.detectedSpellingLetter.value, isEmpty);
      expect(controller.letterHoldProgress.value, 0.0);
    });
  });

  group('Sign Gesture Live Predictions Handling', () {
    test('liveOrder camera receives sign prediction and parses order slot', () async {
      await controller.openCameraFor(CafeCameraActiveFeature.liveOrder);

      // Simulate prediction callback from SignLanguageController
      mockSignCtrl.onPredictionAccepted?.call(
        const BisindoPrediction(
          label: 'KOPI',
          confidence: 0.95,
          isRecognized: true,
        ),
      );

      expect(controller.liveTranscript.value, 'Kopi');
      expect(controller.activeParsedSlot.value, isNotNull);
    });

    test('cupNameSpelling camera detects alphabet letters and commits into cup name', () async {
      await controller.openCameraFor(CafeCameraActiveFeature.cupNameSpelling);

      // Streak 1
      mockSignCtrl.onPredictionAccepted?.call(
        const BisindoPrediction(
          label: 'A',
          confidence: 0.92,
          isLetter: true,
          isRecognized: true,
        ),
      );
      expect(controller.detectedSpellingLetter.value, 'A');
      expect(controller.letterHoldProgress.value, 0.5);

      // Streak 2 -> commits letter
      mockSignCtrl.onPredictionAccepted?.call(
        const BisindoPrediction(
          label: 'A',
          confidence: 0.94,
          isLetter: true,
          isRecognized: true,
        ),
      );
      expect(controller.customerCupNameBuffer.value, 'A');
    });

    test('waitingChallenge camera matches challenge sign and advances progress', () async {
      await controller.openCameraFor(CafeCameraActiveFeature.waitingChallenge);
      controller.activeChallengeSign.value = 'TERIMA KASIH';
      controller.challengeProgress.value = 0.0;

      // Predict matching gesture
      mockSignCtrl.onPredictionAccepted?.call(
        const BisindoPrediction(
          label: 'Terima Kasih',
          confidence: 0.90,
          isRecognized: true,
        ),
      );

      expect(controller.challengeProgress.value, greaterThan(0.3));
    });

    test('waitingChallenge in SIBI mode matches single word gestures', () async {
      await controller.switchSignLanguageModel(SignLanguageModel.sibi);
      await controller.openCameraFor(CafeCameraActiveFeature.waitingChallenge);
      controller.activeChallengeSign.value = 'TERIMA';
      controller.challengeProgress.value = 0.0;

      // SIBI output "Terima"
      mockSignCtrl.onPredictionAccepted?.call(
        const BisindoPrediction(
          label: 'Terima',
          confidence: 0.92,
          isRecognized: true,
        ),
      );

      expect(controller.challengeProgress.value, greaterThan(0.3));
    });
  });

  group('CafeMiniCameraViewport Visual Overlay Verification', () {
    testWidgets('renders cleanly without hand palm icon and reticle border', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: CafeMiniCameraViewport(
              title: 'Test Camera',
              modelBadge: 'SIBI (72)',
            ),
          ),
        ),
      );

      // Verify hand palm icon is completely gone
      expect(find.byIcon(Icons.front_hand_outlined), findsNothing);
      expect(find.byIcon(Icons.front_hand_rounded), findsNothing);

      // Verify model badge is rendered
      expect(find.text('SIBI (72)'), findsOneWidget);
      expect(find.text('Test Camera'), findsOneWidget);
    });
  });
}
