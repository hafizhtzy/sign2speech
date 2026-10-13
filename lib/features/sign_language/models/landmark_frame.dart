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

  @override
  String toString() =>
      'LandmarkFrame(coords: ${landmarks.length}, time: $timestampMs, valid: $isValid)';
}
