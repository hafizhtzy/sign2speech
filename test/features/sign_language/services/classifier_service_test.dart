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

    test('SIBI Adaptive: Accepts prediction with confidence 0.62 and margin 0.10 for SIBI', () {
      final pred = classifier.filterPrediction(
        label: 'BANTU',
        top1Confidence: 0.62,
        top2Confidence: 0.52,
        modelType: SignLanguageModelType.sibi,
      );

      expect(pred, isNotNull);
      expect(pred!.cleanLabel, equals('Bantu'));
      expect(pred.confidence, equals(0.62));
      expect(pred.margin, closeTo(0.10, 0.001));
    });

    test('SIBI Adaptive: Rejects prediction when SIBI confidence < 0.58 or margin < 0.08', () {
      final predLowConf = classifier.filterPrediction(
        label: 'BANTU',
        top1Confidence: 0.52,
        top2Confidence: 0.20,
        modelType: SignLanguageModelType.sibi,
      );
      expect(predLowConf, isNull);

      final predLowMargin = classifier.filterPrediction(
        label: 'BANTU',
        top1Confidence: 0.65,
        top2Confidence: 0.60,
        modelType: SignLanguageModelType.sibi,
      );
      expect(predLowMargin, isNull);
    });
  });
}
