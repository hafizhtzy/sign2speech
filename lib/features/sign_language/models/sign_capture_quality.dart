import 'package:flutter/foundation.dart';

enum CaptureLightLevel { low, normal, excessive }

@immutable
class SignCaptureQuality {
  final bool isHandVisible;
  final bool isPoseVisible;
  final bool isFaceVisible;
  final CaptureLightLevel lightLevel;
  final double handKineticEnergy;

  const SignCaptureQuality({
    this.isHandVisible = true,
    this.isPoseVisible = true,
    this.isFaceVisible = true,
    this.lightLevel = CaptureLightLevel.normal,
    this.handKineticEnergy = 0.0,
  });

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
}
