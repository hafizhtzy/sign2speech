import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_classifier_service.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_synthetic_gesture_generator.dart';

void main() {
  group('Bisindo Classifier & Synthetic Gesture Pipeline Tests', () {
    late BisindoClassifierService classifier;

    setUp(() {
      classifier = BisindoClassifierService();
    });

    test('Classifies synthetic gesture tensor for Halo with valid confidence and margin', () async {
      final tensor = BisindoSyntheticGestureGenerator.generateTensorForLabel('Halo');
      final pred = await classifier.classify(tensor, modelType: SignLanguageModelType.bisindo);

      expect(pred, isNotNull);
      expect(pred!.cleanLabel, equals('Halo'));
      expect(pred.isLetter, isFalse);
      expect(pred.confidence, greaterThanOrEqualTo(0.70));
      expect(pred.margin, greaterThanOrEqualTo(0.15));
    });

    test('Classifies synthetic gesture tensor for single letter spelling with isLetter true', () async {
      final tensor = BisindoSyntheticGestureGenerator.generateTensorForLabel('B');
      final pred = await classifier.classify(tensor, modelType: SignLanguageModelType.bisindo);

      expect(pred, isNotNull);
      expect(pred!.cleanLabel, equals('B'));
      expect(pred.isLetter, isTrue);
      expect(pred.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Handles SIBI model type classification with 72 classes vocabulary', () async {
      final tensor = BisindoSyntheticGestureGenerator.generateTensorForLabel('Dokter');
      final pred = await classifier.classify(tensor, modelType: SignLanguageModelType.sibi);

      expect(pred, isNotNull);
      expect(pred!.cleanLabel, equals('Dokter'));
      expect(pred.isLetter, isFalse);
    });
  });
}
