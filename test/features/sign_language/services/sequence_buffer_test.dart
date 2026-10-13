import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_sequence_buffer.dart';

void main() {
  group('BisindoSequenceBuffer Tests', () {
    test('buildModelTensor resamples to 48 timesteps with 706 features (33,888 floats)', () {
      final buffer = BisindoSequenceBuffer();

      // Add 20 variable frames
      for (int f = 0; f < 20; f++) {
        final frameFeatures = Float32List(353);
        for (int i = 0; i < 353; i++) {
          frameFeatures[i] = (f * 0.1) + (i * 0.001);
        }
        buffer.addFrame(frameFeatures);
      }

      expect(buffer.frameCount, equals(20));

      final tensor = buffer.buildModelTensor();
      expect(tensor.length, equals(48 * 706)); // 33,888

      // Delta velocity is clamped to [-4.0, 4.0]
      for (int t = 0; t < 48; t++) {
        final offset = t * 706;
        // First 353 are base features
        expect(tensor[offset], isNotNull);
        // Next 353 are delta velocity
        final delta = tensor[offset + 353];
        expect(delta, inInclusiveRange(-4.0, 4.0));
      }
    });

    test(
      'buildModelTensorAsync executes successfully offloaded to Isolate',
      () async {
        final buffer = BisindoSequenceBuffer();
        for (int f = 0; f < 10; f++) {
          buffer.addFrame(Float32List(353));
        }

        final tensor = await buffer.buildModelTensorAsync();
        expect(tensor.length, equals(48 * 706));
      },
    );
  });
}
