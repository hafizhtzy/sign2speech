import 'package:flutter/foundation.dart';

/// Sanitizes raw landmark coordinates:
/// - Replaces NaN, Infinity, -Infinity with 0.0
/// - Clamps values within physically plausible range [-10.0, 10.0] as specified in PRD
List<double> sanitizeLandmarks(List<double> raw) {
  final sanitized = List<double>.filled(raw.length, 0.0);
  for (int i = 0; i < raw.length; i++) {
    final v = raw[i];
    if (v.isNaN || v.isInfinite) {
      sanitized[i] = 0.0;
    } else if (v > 10.0) {
      sanitized[i] = 10.0;
    } else if (v < -10.0) {
      sanitized[i] = -10.0;
    } else {
      sanitized[i] = v;
    }
  }
  return sanitized;
}

@immutable
class LandmarkFrame {
  final List<double> landmarks;
  final int timestampMs;
  final bool isValid;

  LandmarkFrame({
    required List<double> landmarks,
    required this.timestampMs,
    this.isValid = true,
  }) : landmarks = sanitizeLandmarks(landmarks);

  /// Number of individual coordinates (e.g. 543 * 3 = 1629 floats or 543 xyz/blendshapes)
  int get coordinateCount => landmarks.length;

  /// Canonical 52 MediaPipe Face Blendshape names matching the model training contract.
  static const List<String> canonicalFaceBlendshapeNames = [
    '_neutral',
    'browDownLeft',
    'browDownRight',
    'browInnerUp',
    'browOuterUpLeft',
    'browOuterUpRight',
    'cheekPuff',
    'cheekSquintLeft',
    'cheekSquintRight',
    'eyeBlinkLeft',
    'eyeBlinkRight',
    'eyeLookDownLeft',
    'eyeLookDownRight',
    'eyeLookInLeft',
    'eyeLookInRight',
    'eyeLookOutLeft',
    'eyeLookOutRight',
    'eyeLookUpLeft',
    'eyeLookUpRight',
    'eyeSquintLeft',
    'eyeSquintRight',
    'eyeWideLeft',
    'eyeWideRight',
    'jawForward',
    'jawLeft',
    'jawOpen',
    'jawRight',
    'mouthClose',
    'mouthDimpleLeft',
    'mouthDimpleRight',
    'mouthFrownLeft',
    'mouthFrownRight',
    'mouthFunnel',
    'mouthLeft',
    'mouthLowerDownLeft',
    'mouthLowerDownRight',
    'mouthPressLeft',
    'mouthPressRight',
    'mouthPucker',
    'mouthRight',
    'mouthRollLower',
    'mouthRollUpper',
    'mouthShrugLower',
    'mouthShrugUpper',
    'mouthSmileLeft',
    'mouthSmileRight',
    'mouthStretchLeft',
    'mouthStretchRight',
    'mouthUpperUpLeft',
    'mouthUpperUpRight',
    'noseSneerLeft',
    'noseSneerRight',
  ];

  /// Creates a LandmarkFrame from a native Android EventChannel event dictionary.
  factory LandmarkFrame.fromEvent(dynamic event) {
    if (event is! Map) {
      return LandmarkFrame(landmarks: const [], timestampMs: 0, isValid: false);
    }

    final timestamp = (event['timestamp'] as num?)?.toInt() ?? 0;
    final flatList = <double>[];

    // 1. Pose landmarks (0..32, 33 points -> 99 floats)
    final poseRaw = event['pose'] as List?;
    if (poseRaw != null && poseRaw.isNotEmpty) {
      for (final pt in poseRaw) {
        if (pt is List && pt.length >= 3) {
          flatList.add((pt[0] as num).toDouble());
          flatList.add((pt[1] as num).toDouble());
          flatList.add((pt[2] as num).toDouble());
        }
      }
    }
    while (flatList.length < 99) {
      flatList.add(0.0);
    }

    // 2. Left Hand landmarks (33..53, 21 points -> 63 floats)
    final leftRaw = event['left_hand'] as List?;
    if (leftRaw != null && leftRaw.isNotEmpty) {
      for (final pt in leftRaw) {
        if (pt is List && pt.length >= 3) {
          flatList.add((pt[0] as num).toDouble());
          flatList.add((pt[1] as num).toDouble());
          flatList.add((pt[2] as num).toDouble());
        }
      }
    }
    while (flatList.length < 99 + 63) {
      flatList.add(0.0);
    }

    // 3. Right Hand landmarks (54..74, 21 points -> 63 floats)
    final rightRaw = event['right_hand'] as List?;
    if (rightRaw != null && rightRaw.isNotEmpty) {
      for (final pt in rightRaw) {
        if (pt is List && pt.length >= 3) {
          flatList.add((pt[0] as num).toDouble());
          flatList.add((pt[1] as num).toDouble());
          flatList.add((pt[2] as num).toDouble());
        }
      }
    }
    while (flatList.length < 99 + 63 + 63) {
      flatList.add(0.0);
    }

    // 4. Face blendshapes (75..126, 52 floats in exact canonical order)
    final blendRaw = event['face_blendshapes'] as Map?;
    if (blendRaw != null && blendRaw.isNotEmpty) {
      for (final name in canonicalFaceBlendshapeNames) {
        final v = blendRaw[name];
        if (v is num) {
          flatList.add(v.toDouble());
        } else {
          flatList.add(0.0);
        }
      }
    }
    while (flatList.length < 225 + 52) {
      flatList.add(0.0);
    }

    return LandmarkFrame(
      landmarks: flatList,
      timestampMs: timestamp,
      isValid: true,
    );
  }

  @override
  String toString() =>
      'LandmarkFrame(coords: ${landmarks.length}, time: $timestampMs, valid: $isValid)';
}
