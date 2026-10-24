import 'package:flutter/foundation.dart';
import 'landmark_frame.dart';

enum CaptureLightLevel { low, normal, excessive }

/// Quality validation result evaluated across a captured gesture.
class QualityValidationResult {
  final bool isValid;
  final String? userErrorMessage;

  const QualityValidationResult({required this.isValid, this.userErrorMessage});
}

/// Quality metrics evaluated across an isolated sign gesture recording session.
/// Ported from HajiCare MotionGRU contract.
@immutable
class SignCaptureQuality {
  final int totalFrames;
  final int handFrames;
  final int poseFrames;
  final int faceFrames;
  final bool isHandVisible;
  final bool isPoseVisible;
  final bool isFaceVisible;
  final CaptureLightLevel lightLevel;
  final double handKineticEnergy;

  const SignCaptureQuality({
    this.totalFrames = 0,
    this.handFrames = 0,
    this.poseFrames = 0,
    this.faceFrames = 0,
    this.isHandVisible = true,
    this.isPoseVisible = true,
    this.isFaceVisible = true,
    this.lightLevel = CaptureLightLevel.normal,
    this.handKineticEnergy = 0.0,
  });

  double get anyHandRatio => totalFrames > 0 ? (handFrames / totalFrames) : 0.0;
  double get poseRatio => totalFrames > 0 ? (poseFrames / totalFrames) : 0.0;
  double get faceRatio => totalFrames > 0 ? (faceFrames / totalFrames) : 0.0;

  bool get isReadyForRecognition =>
      isHandVisible && lightLevel != CaptureLightLevel.low;

  String get userFeedback {
    if (lightLevel == CaptureLightLevel.low) {
      return 'Cahaya kurang';
    }
    if (!isHandVisible) {
      return 'Tangan di luar frame';
    }
    if (handKineticEnergy < 0.01) {
      return 'Kamera siap';
    }
    return 'Mendeteksi gestur';
  }

  /// Aggregates quality from a list of collected frames.
  factory SignCaptureQuality.fromFrames(List<LandmarkFrame> frames) {
    if (frames.isEmpty) {
      return const SignCaptureQuality(
        totalFrames: 0,
        handFrames: 0,
        poseFrames: 0,
        faceFrames: 0,
        isHandVisible: false,
        isPoseVisible: false,
        isFaceVisible: false,
      );
    }

    int handCount = 0;
    int poseCount = 0;
    int faceCount = 0;

    for (final f in frames) {
      if (f.hasAnyHand) handCount++;
      if (f.hasPose) poseCount++;
      if (f.hasFaceBlendshapes) faceCount++;
    }

    final hasHand = handCount > 0;
    final hasPose = poseCount > 0;
    final hasFace = faceCount > 0;

    return SignCaptureQuality(
      totalFrames: frames.length,
      handFrames: handCount,
      poseFrames: poseCount,
      faceFrames: faceCount,
      isHandVisible: hasHand,
      isPoseVisible: hasPose,
      isFaceVisible: hasFace,
      handKineticEnergy: hasHand ? 0.25 : 0.0,
    );
  }

  /// Evaluates whether the capture meets minimum quality gating standards.
  QualityValidationResult validate() {
    if (totalFrames < 2) {
      return const QualityValidationResult(
        isValid: false,
        userErrorMessage: 'Gerakan belum cukup terdeteksi. Silakan coba lagi.',
      );
    }

    if (anyHandRatio < 0.35) {
      return const QualityValidationResult(
        isValid: false,
        userErrorMessage:
            'Tangan kurang terlihat. Pastikan tangan berada di dalam kamera.',
      );
    }

    if (poseRatio < 0.20) {
      return const QualityValidationResult(
        isValid: false,
        userErrorMessage:
            'Tubuh bagian atas belum terlihat jelas. Posisikan dada dan bahu dalam kamera.',
      );
    }

    return const QualityValidationResult(isValid: true);
  }

  @override
  String toString() =>
      'SignCaptureQuality(frames: $totalFrames, handRatio: ${(anyHandRatio * 100).toStringAsFixed(1)}%, poseRatio: ${(poseRatio * 100).toStringAsFixed(1)}%, faceRatio: ${(faceRatio * 100).toStringAsFixed(1)}%)';
}
