import 'package:flutter/foundation.dart';

import '../models/bisindo_prediction.dart';

enum SignLanguageModelType {
  bisindo, // 47 classes
  sibi, // 72 classes
}

abstract class IModelClassifier {
  Future<BisindoPrediction?> classify(
    Float32List tensor, {
    required SignLanguageModelType modelType,
  });
}

class BisindoClassifierService implements IModelClassifier {
  final double minConfidence;
  final double minMargin;
  final bool _isModelLoaded = false;

  BisindoClassifierService({this.minConfidence = 0.70, this.minMargin = 0.15});

  bool get isModelLoaded => _isModelLoaded;

  /// Filters prediction based on PRD validation contracts:
  /// - Confidence >= 0.70
  /// - Margin (Top1 - Top2) >= 0.15
  BisindoPrediction? filterPrediction({
    required String label,
    required double top1Confidence,
    required double top2Confidence,
  }) {
    if (top1Confidence < minConfidence) {
      return null;
    }

    final margin = top1Confidence - top2Confidence;
    if (margin < minMargin) {
      return null;
    }

    final isLetter = label.startsWith('LETTER_');
    return BisindoPrediction(
      label: label,
      confidence: top1Confidence,
      margin: margin,
      isLetter: isLetter,
    );
  }

  @override
  Future<BisindoPrediction?> classify(
    Float32List tensor, {
    required SignLanguageModelType modelType,
  }) async {
    // If running in environment without deployed TFLite binary, report gracefully
    if (!_isModelLoaded) {
      debugPrint(
        'MotionGRU model is not yet bundled in assets. Classification deferred.',
      );
      return null;
    }
    return null;
  }
}
