import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_classifier_service.dart';

void main() {
  group('BisindoClassifierService Threshold & Filtering Tests', () {
    late BisindoClassifierService classifier;

    setUp(() {
      classifier = BisindoClassifierService();
    });

    test('Filters out prediction if confidence < 0.70', () {
      // Simulate raw model output: Top1 = 0.65, Top2 = 0.20
      final pred = classifier.filterPrediction(
        label: 'WORD_HALO',
        top1Confidence: 0.65,
        top2Confidence: 0.20,
      );

      expect(pred, isNull);
    });

    test('Filters out prediction if top1 - top2 margin < 0.15', () {
      // Simulate raw model output: Top1 = 0.75, Top2 = 0.65 (margin 0.10)
      final pred = classifier.filterPrediction(
        label: 'WORD_HALO',
        top1Confidence: 0.75,
        top2Confidence: 0.65,
      );

      expect(pred, isNull);
    });

    test('Accepts prediction when confidence >= 0.70 and margin >= 0.15', () {
      // Simulate raw model output: Top1 = 0.85, Top2 = 0.25 (margin 0.60)
      final pred = classifier.filterPrediction(
        label: 'WORD_TERIMA_KASIH',
        top1Confidence: 0.85,
        top2Confidence: 0.25,
      );

      expect(pred, isNotNull);
      expect(pred!.cleanLabel, equals('Terima_kasih'));
      expect(pred.confidence, equals(0.85));
      expect(pred.margin, equals(0.60));
    });
  });
}
