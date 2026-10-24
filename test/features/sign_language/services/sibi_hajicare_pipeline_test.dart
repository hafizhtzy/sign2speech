import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:speech2sign/features/sign_language/models/bisindo_prediction.dart';
import 'package:speech2sign/features/sign_language/models/landmark_frame.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_feature_extractor.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_segmenter.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_sequence_buffer.dart';
import 'package:speech2sign/features/sign_language/services/sign_transcript_store.dart';
import 'package:speech2sign/features/sign_language/services/sign_translation_service.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SIBI HajiCare Pipeline Parity & Integration Tests', () {
    test('LandmarkFrame parses structured event dictionary from BisindoCameraHelper', () {
      final mockEvent = {
        'timestamp': 1000,
        'pose': List.generate(33, (i) => [0.5, 0.5, 0.0]),
        'left_hand': List.generate(21, (i) => [0.4, 0.6, 0.0]),
        'right_hand': List.generate(21, (i) => [0.6, 0.6, 0.0]),
        'face_blendshapes': {
          '_neutral': 0.85,
          'mouthSmileLeft': 0.75,
        },
      };

      final frame = LandmarkFrame.fromEvent(mockEvent);
      expect(frame.isValid, isTrue);
      expect(frame.hasPose, isTrue);
      expect(frame.hasLeftHand, isTrue);
      expect(frame.hasRightHand, isTrue);
      expect(frame.hasFaceBlendshapes, isTrue);
      expect(frame.pose!.length, equals(33));
      expect(frame.leftHand!.length, equals(21));
      expect(frame.rightHand!.length, equals(21));
      expect(frame.faceBlendshapes!['_neutral'], equals(0.85));
    });

    test('BisindoFeatureExtractor extracts exact 353-D MotionGRU vector with BodyReference', () {
      final pose = List.generate(33, (i) => [0.5, 0.5, 0.0]);
      pose[11] = [0.4, 0.3, 0.0]; // Left shoulder
      pose[12] = [0.6, 0.3, 0.0]; // Right shoulder

      final leftHand = List.generate(21, (i) => [0.38, 0.5 + (i * 0.01), 0.0]);
      final rightHand = List.generate(21, (i) => [0.62, 0.5 + (i * 0.01), 0.0]);

      final frame = LandmarkFrame(
        pose: pose,
        leftHand: leftHand,
        rightHand: rightHand,
        faceBlendshapes: {
          '_neutral': 0.90,
          'browInnerUp': 0.20,
        },
        timestampMs: 500,
      );

      final feature = BisindoFeatureExtractor.extractBaseFeature(frame);
      expect(feature.length, equals(353));

      // 0..62: Left hand global (clamped to [-6.0, 6.0])
      for (int i = 0; i < 63; i++) {
        expect(feature[i], inInclusiveRange(-6.0, 6.0));
      }
      // 63..125: Left hand local (clamped to [-5.0, 5.0])
      for (int i = 63; i < 126; i++) {
        expect(feature[i], inInclusiveRange(-5.0, 5.0));
      }
      // 126..188: Right hand global
      for (int i = 126; i < 189; i++) {
        expect(feature[i], inInclusiveRange(-6.0, 6.0));
      }
      // 189..251: Right hand local
      for (int i = 189; i < 252; i++) {
        expect(feature[i], inInclusiveRange(-5.0, 5.0));
      }
      // 252..296: 15 Selected pose landmarks
      for (int i = 252; i < 297; i++) {
        expect(feature[i], inInclusiveRange(-6.0, 6.0));
      }
      // 297: Face blendshape '_neutral'
      expect(feature[297], closeTo(0.90, 0.001));

      // 349..352: Presence masks [hasLeft, hasRight, hasPose, hasFace]
      expect(feature[349], equals(1.0));
      expect(feature[350], equals(1.0));
      expect(feature[351], equals(1.0));
      expect(feature[352], equals(1.0));
    });

    test('BisindoSequenceBuffer resamples, computes velocity delta, and produces [1, 48, 706] tensor', () {
      final buffer = BisindoSequenceBuffer();

      for (int f = 0; f < 15; f++) {
        final frame = LandmarkFrame(
          leftHand: List.generate(21, (i) => [0.4 + (f * 0.01), 0.5, 0.0]),
          pose: List.generate(33, (i) => [0.5, 0.5, 0.0]),
        );
        buffer.addBaseFeature(BisindoFeatureExtractor.extractBaseFeature(frame));
      }

      expect(buffer.length, equals(15));
      final inputTensor = buffer.prepareModelInput();

      expect(inputTensor.length, equals(1));
      expect(inputTensor[0].length, equals(48));
      expect(inputTensor[0][0].length, equals(706));

      for (int d = 353; d < 706; d++) {
        expect(inputTensor[0][0][d], equals(0.0));
      }

      for (int t = 1; t < 48; t++) {
        for (int d = 353; d < 706; d++) {
          expect(inputTensor[0][t][d], inInclusiveRange(-4.0, 4.0));
        }
      }
    });

    test('BisindoSegmenter collects pre-roll frames and segments on stillness', () {
      final segmenter = BisindoSegmenter(
        config: const BisindoSegmenterConfig(
          startHandFrames: 3,
          preRollFrames: 4,
          minFrames: 5,
          minDuration: Duration(milliseconds: 300),
          endStillness: Duration(milliseconds: 400),
        ),
      );

      // 1. Moving frames
      for (int i = 0; i < 8; i++) {
        final frame = LandmarkFrame(
          leftHand: List.generate(21, (p) => [0.3 + (i * 0.04), 0.5, 0.0]),
          timestampMs: i * 50,
        );
        segmenter.add(frame, nowMs: i * 50);
      }

      expect(segmenter.isActive, isTrue);

      // 2. Still frames (hand motionless at same coordinate)
      BisindoSegment? finishedSegment;
      for (int i = 8; i < 35; i++) {
        final frame = LandmarkFrame(
          leftHand: List.generate(21, (p) => [0.70, 0.5, 0.0]),
          timestampMs: i * 50,
        );
        finishedSegment = segmenter.add(frame, nowMs: i * 50);
        if (finishedSegment != null) break;
      }

      expect(finishedSegment, isNotNull);
      expect(finishedSegment!.reason, equals(BisindoSegmentEndReason.handsStill));
      expect(finishedSegment.frames.length, greaterThanOrEqualTo(5));
      expect(finishedSegment.duration.inMilliseconds, greaterThanOrEqualTo(300));
    });

    test('SIBI Model Config verifies 72 classes and adaptive threshold contracts', () {
      final config = SignLanguageModelConfig.sibi;
      expect(config.model, equals(SignLanguageModel.sibi));
      expect(config.classCount, equals(72));
      expect(config.expectedInputFeatures, equals(706));
      expect(config.windowSize, equals(48));
      expect(config.modelAsset, equals('assets/models/sibi/sibi_motion_gru_float16.tflite'));
      expect(config.labelAsset, equals('assets/models/sibi/labels.txt'));
      expect(config.configAsset, equals('assets/models/sibi/model_metadata.json'));
      expect(config.minMargin, equals(0.08));
    });

    test('BisindoRecognitionController handles SIBI model thresholds and letter spelling buffering', () async {
      final controller = BisindoRecognitionController(
        ttsService: BisindoTtsService(),
        transcriptStore: SignTranscriptStore(),
        translationService: SignTranslationService(),
      );

      controller.setModelThresholds(
        confidenceThreshold: 0.58,
        stablePredictionsRequired: 2,
      );

      expect(controller.currentConfidenceThreshold.value, equals(0.58));
      expect(controller.currentStablePredictionsRequired.value, equals(2));

      controller.handlePrediction(
        const BisindoPrediction(
          label: 'LETTER_S',
          confidence: 0.85,
          margin: 0.20,
          isLetter: true,
        ),
      );
      expect(controller.spellingBuffer.value, equals('S'));

      controller.handlePrediction(
        const BisindoPrediction(
          label: 'LETTER_I',
          confidence: 0.88,
          margin: 0.22,
          isLetter: true,
        ),
      );
      expect(controller.spellingBuffer.value, equals('SI'));

      controller.commitSpellingBuffer();
      expect(controller.spellingBuffer.value, isEmpty);
      expect(controller.tokens.length, equals(1));
      expect(controller.tokens.first.value, equals('SI'));

      controller.onClose();
    });
  });
}
