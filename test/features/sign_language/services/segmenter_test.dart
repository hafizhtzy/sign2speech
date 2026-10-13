import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/models/landmark_frame.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_segmenter.dart';

void main() {
  group('BisindoSegmenter Tests', () {
    test('Ignores fleeting hand presence less than 3 frames', () {
      final segmenter = BisindoSegmenter();
      final frame1 = LandmarkFrame(
        landmarks: List.filled(500, 0.5),
        timestampMs: 100,
      );

      final event = segmenter.processFrame(
        frame1,
        isHandDetected: true,
        motionEnergy: 0.1,
      );
      expect(event, isNull);
      expect(segmenter.isSigningActive, isFalse);
    });

    test('Triggers onset after 3 stable consecutive hand frames with motion energy', () {
      final segmenter = BisindoSegmenter();
      final frame = LandmarkFrame(
        landmarks: List.filled(500, 0.5),
        timestampMs: 100,
      );

      segmenter.processFrame(frame, isHandDetected: true, motionEnergy: 0.1);
      segmenter.processFrame(frame, isHandDetected: true, motionEnergy: 0.1);
      final event = segmenter.processFrame(
        frame,
        isHandDetected: true,
        motionEnergy: 0.1,
      );

      expect(event, equals(SegmentEventType.onset));
      expect(segmenter.isSigningActive, isTrue);
    });

    test(
      'Triggers offset and produces valid segment when hand absent > 450ms',
      () {
        final segmenter = BisindoSegmenter();
        final frame = LandmarkFrame(
          landmarks: List.filled(500, 0.5),
          timestampMs: 100,
        );

        // Onset
        segmenter.processFrame(frame, isHandDetected: true, motionEnergy: 0.1);
        segmenter.processFrame(frame, isHandDetected: true, motionEnergy: 0.1);
        segmenter.processFrame(frame, isHandDetected: true, motionEnergy: 0.1);

        // Ongoing signing for 600ms
        final frameMid = LandmarkFrame(
          landmarks: List.filled(500, 0.5),
          timestampMs: 700,
        );
        segmenter.processFrame(
          frameMid,
          isHandDetected: true,
          motionEnergy: 0.1,
        );

        // Hand disappeared at 1200ms (> 450ms absence)
        final frameEnd = LandmarkFrame(
          landmarks: List.filled(500, 0.0),
          timestampMs: 1200,
        );
        final event = segmenter.processFrame(
          frameEnd,
          isHandDetected: false,
          motionEnergy: 0.0,
        );

        expect(event, equals(SegmentEventType.offset));
        expect(segmenter.isSigningActive, isFalse);
      },
    );
  });
}
