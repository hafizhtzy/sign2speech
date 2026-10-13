import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/features/sign_language/controllers/sign_language_controller.dart';
import 'package:speech2sign/features/sign_language/models/landmark_frame.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CameraFeedService & SignLanguageController Native Platform Tests', () {
    late CameraFeedService cameraService;
    late SignLanguageController controller;

    setUp(() {
      Get.reset();
      cameraService = CameraFeedService();
      controller = SignLanguageController(
        cameraFeedService: cameraService,
      );
    });

    tearDown(() {
      controller.onClose();
      cameraService.onClose();
      Get.reset();
    });

    test('Initial camera state defaults to front lens and not initialized', () {
      expect(cameraService.isInitialized.value, isFalse);
      expect(cameraService.isLoading.value, isFalse);
      expect(cameraService.isFrontCamera.value, isTrue);
      expect(cameraService.isCameraReady, isFalse);
      expect(cameraService.receivedFramesCount.value, equals(0));
    });

    test('Flipping camera toggles lens direction between front and back', () async {
      expect(controller.isFrontCamera.value, isTrue);

      await controller.flipCamera();
      expect(controller.isFrontCamera.value, isFalse);

      await controller.flipCamera();
      expect(controller.isFrontCamera.value, isTrue);
    });

    test('startContinuous activates camera flag and transitions to listening', () async {
      expect(controller.isCameraActive.value, isFalse);

      await controller.startContinuous();

      expect(controller.isCameraActive.value, isTrue);
      expect(controller.isContinuousRunning.value, isTrue);
      expect(controller.state.value, equals(BisindoLiveState.listening));
    });

    test('stopContinuous resets camera flags and sets state to stopped', () async {
      await controller.startContinuous();
      expect(controller.isCameraActive.value, isTrue);

      await controller.stopContinuous();

      expect(controller.isCameraActive.value, isFalse);
      expect(controller.isContinuousRunning.value, isFalse);
      expect(controller.state.value, equals(BisindoLiveState.stopped));
    });

    test('LandmarkFrame.fromEvent correctly parses native Android MediaPipe event payload', () {
      final mockEvent = {
        'timestamp': 123456,
        'pose': [
          [0.5, 0.5, 0.0],
          [0.6, 0.6, 0.1],
        ],
        'left_hand': [
          [0.1, 0.2, 0.3],
        ],
        'right_hand': [
          [0.7, 0.8, 0.9],
        ],
        'face_blendshapes': {
          'mouthSmileLeft': 0.85,
        },
      };

      final frame = LandmarkFrame.fromEvent(mockEvent);
      expect(frame.isValid, isTrue);
      expect(frame.timestampMs, equals(123456));
      expect(frame.landmarks.length, equals(277)); // 99 pose + 63 left + 63 right + 52 face
      expect(frame.landmarks[0], equals(0.5));
      expect(frame.landmarks[1], equals(0.5));
    });

    test('stopCamera cleans up subscription and resets flags', () async {
      await cameraService.stopCamera();
      expect(cameraService.isInitialized.value, isFalse);
      expect(cameraService.isCameraActive.value, isFalse);
    });
  });
}
