import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/models/landmark_frame.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_feature_extractor.dart';

void main() {
  group('BisindoFeatureExtractor Tests', () {
    test('extract returns exactly 353 float values with normalized bounds', () {
      // Create a mock frame of 543 coords * 3 = 1629 floats
      final rawCoords = List<double>.generate(1629, (i) => (i % 100) / 100.0);
      final frame = LandmarkFrame(
        landmarks: rawCoords,
        timestampMs: 1000,
        isValid: true,
      );

      final features = BisindoFeatureExtractor.extract(frame);
      expect(features.length, equals(353));

      // Global coordinates clamped to [-6.0, 6.0]
      for (int i = 0; i < 63; i++) {
        expect(features[i], inInclusiveRange(-6.0, 6.0));
      }
      // Local coordinates clamped to [-5.0, 5.0]
      for (int i = 63; i < 126; i++) {
        expect(features[i], inInclusiveRange(-5.0, 5.0));
      }
      // Masks at 349..352
      expect(features[349], equals(1.0)); // hasLeft
      expect(features[350], equals(1.0)); // hasRight
      expect(features[351], equals(1.0)); // hasPose
      expect(features[352], equals(1.0)); // hasFace
    });

    test('extractAsync executes successfully offloaded to Isolate', () async {
      final rawCoords = List<double>.filled(1629, 0.5);
      final frame = LandmarkFrame(
        landmarks: rawCoords,
        timestampMs: 1000,
        isValid: true,
      );

      final features = await BisindoFeatureExtractor.extractAsync(frame);
      expect(features, isA<Float32List>());
      expect(features.length, equals(353));
    });
  });
}
