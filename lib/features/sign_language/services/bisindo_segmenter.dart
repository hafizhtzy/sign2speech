import '../models/landmark_frame.dart';

enum SegmentEventType { onset, offset }

class BisindoSegmenter {
  final double minMotionEnergy;
  final int minConsecutiveFrames;
  final int absenceThresholdMs;
  final int stillnessThresholdMs;
  final int minDurationMs;
  final int maxDurationMs;

  int _consecutiveHandFrames = 0;
  bool _isSigningActive = false;
  int _signingStartTimeMs = 0;
  int _lastHandTimeMs = 0;
  int _stillnessStartTimeMs = 0;

  BisindoSegmenter({
    this.minMotionEnergy = 0.05,
    this.minConsecutiveFrames = 3,
    this.absenceThresholdMs = 450,
    this.stillnessThresholdMs = 750,
    this.minDurationMs = 450,
    this.maxDurationMs = 3500,
  });

  bool get isSigningActive => _isSigningActive;
  int get currentDurationMs =>
      _isSigningActive ? (_lastHandTimeMs - _signingStartTimeMs) : 0;

  /// Processes frame and returns SegmentEventType if onset or offset occurred.
  SegmentEventType? processFrame(
    LandmarkFrame frame, {
    required bool isHandDetected,
    required double motionEnergy,
  }) {
    final now = frame.timestampMs;

    if (isHandDetected) {
      _lastHandTimeMs = now;
      if (motionEnergy >= minMotionEnergy) {
        _consecutiveHandFrames++;
        _stillnessStartTimeMs = 0;
      } else {
        // Hand present but still
        if (_stillnessStartTimeMs == 0) {
          _stillnessStartTimeMs = now;
        }
      }
    } else {
      _consecutiveHandFrames = 0;
    }

    // 1. Check Onset
    if (!_isSigningActive) {
      if (_consecutiveHandFrames >= minConsecutiveFrames) {
        _isSigningActive = true;
        _signingStartTimeMs = now;
        return SegmentEventType.onset;
      }
      return null;
    }

    // 2. Check Offset while signing is active
    final duration = now - _signingStartTimeMs;

    // Check hand absence (> 450ms)
    final absenceDuration = now - _lastHandTimeMs;
    final isAbsent = !isHandDetected && absenceDuration >= absenceThresholdMs;

    // Check stillness (> 750ms)
    final isStill =
        _stillnessStartTimeMs > 0 &&
        (now - _stillnessStartTimeMs) >= stillnessThresholdMs;

    // Max duration exceeded (> 3500ms)
    final isMaxExceeded = duration >= maxDurationMs;

    if (isAbsent || isStill || isMaxExceeded) {
      _isSigningActive = false;
      _consecutiveHandFrames = 0;
      _stillnessStartTimeMs = 0;

      // Filter: valid gesture duration must be >= 450ms
      if (duration >= minDurationMs) {
        return SegmentEventType.offset;
      }
    }

    return null;
  }

  void reset() {
    _consecutiveHandFrames = 0;
    _isSigningActive = false;
    _signingStartTimeMs = 0;
    _lastHandTimeMs = 0;
    _stillnessStartTimeMs = 0;
  }
}
