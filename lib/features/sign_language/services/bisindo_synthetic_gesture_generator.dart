import 'dart:math';
import 'dart:typed_data';

import '../models/landmark_frame.dart';
import 'bisindo_feature_extractor.dart';
import 'bisindo_sequence_buffer.dart';

/// Generates realistic synthetic 706-D feature sequences for sign gestures.
/// Allows full end-to-end testing of the MotionGRU inference pipeline,
/// hold confirmation ring, letter buffering, and TTS without requiring physical CameraX hardware.
class BisindoSyntheticGestureGenerator {
  static const List<String> bisindoLabels = [
    'A', 'Air', 'Apa', 'Apa Kabar', 'B', 'Baik', 'Berapa', 'Berdiri', 'C', 'D',
    'Dia', 'Dimana', 'Duduk', 'E', 'F', 'G', 'H', 'Halo', 'I', 'J',
    'K', 'Kalian', 'Kami', 'Kamu', 'Kapan', 'Kemana', 'Kita', 'L', 'M', 'Mandi',
    'Minum', 'N', 'O', 'P', 'Q', 'R', 'S', 'Siapa', 'T', 'Terima Kasih',
    'Tuli', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  static const List<String> sibiLabels = [
    'A', 'Air', 'Aku', 'Apa', 'Arah', 'B', 'Bantu', 'Berapa', 'Berhenti', 'Bus',
    'C', 'D', 'Darurat', 'Di', 'Dokter', 'E', 'F', 'G', 'H', 'Haus',
    'Hilang', 'Hotel', 'I', 'J', 'Jalan', 'K', 'Kamar', 'Kamu', 'Kan', 'Kapan',
    'Kasih', 'Ke', 'Kita', 'L', 'Lelah', 'M', 'Makan', 'Mana', 'Masjid', 'Minum',
    'N', 'Nafas', 'O', 'Obat', 'P', 'Pendamping', 'Polisi', 'Pusing', 'Q', 'R',
    'Rumah', 'S', 'Sakit', 'Saya', 'Sehat', 'Sesak', 'Sesat', 'Shalat', 'Siapa',
    'T', 'Terima', 'Tidak', 'Tunggu', 'U', 'V', 'W', 'Wudhu', 'X', 'Y', 'Ya', 'Z', 'mandi'
  ];

  /// Generates a complete [1, 48, 706] Float32 tensor for a specified gesture label.
  static Float32List generateTensorForLabel(String label, {int frameCount = 30}) {
    final frames = generateFramesForLabel(label, count: frameCount);
    final buffer = BisindoSequenceBuffer();
    for (final frame in frames) {
      final features = BisindoFeatureExtractor.extract(frame);
      buffer.addFrame(features);
    }
    return buffer.buildModelTensor();
  }

  /// Generates a list of realistic sequential [LandmarkFrame]s for a specified gesture label.
  static List<LandmarkFrame> generateFramesForLabel(String label, {int count = 30}) {
    final frames = <LandmarkFrame>[];
    final normalized = label.trim();
    final isLetter = normalized.length == 1 && RegExp(r'^[A-Za-z]$').hasMatch(normalized);

    // Find class index for signature embedding
    int classIdx = -1;
    for (int i = 0; i < bisindoLabels.length; i++) {
      if (bisindoLabels[i].toLowerCase() == normalized.toLowerCase()) {
        classIdx = i;
        break;
      }
    }
    if (classIdx == -1) {
      for (int i = 0; i < sibiLabels.length; i++) {
        if (sibiLabels[i].toLowerCase() == normalized.toLowerCase()) {
          classIdx = i;
          break;
        }
      }
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;
    const frameInterval = 33; // ~30 FPS

    for (int i = 0; i < count; i++) {
      final progress = count > 1 ? i / (count - 1) : 0.5;
      final t = i * frameInterval;
      final rawLandmarks = _createRawLandmarks(normalized, isLetter, progress, classIdx);

      frames.add(
        LandmarkFrame(
          landmarks: rawLandmarks,
          timestampMs: startTime + t,
          isValid: true,
        ),
      );
    }

    return frames;
  }

  static List<double> _createRawLandmarks(
    String label,
    bool isLetter,
    double progress,
    int classIdx,
  ) {
    // Total raw floats needed = 225 landmarks + 52 face blendshapes = 277
    final raw = List<double>.filled(277, 0.0);

    // 1. Pose Landmarks
    raw[11 * 3 + 0] = 0.35;
    raw[11 * 3 + 1] = 0.45;
    raw[11 * 3 + 2] = 0.0;

    raw[12 * 3 + 0] = 0.65;
    raw[12 * 3 + 1] = 0.45;
    raw[12 * 3 + 2] = 0.0;

    raw[0 * 3 + 0] = 0.50;
    raw[0 * 3 + 1] = 0.25;
    raw[0 * 3 + 2] = 0.0;

    for (int p in [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]) {
      raw[p * 3 + 0] = 0.5;
      raw[p * 3 + 1] = 0.6;
      raw[p * 3 + 2] = 0.0;
    }

    // 2. Hand Landmarks & Motion Profiles
    double rWristX = 0.60;
    double rWristY = 0.50;
    double rWristZ = 0.0;

    if (isLetter) {
      rWristX = 0.60 + 0.02 * sin(progress * pi);
      rWristY = 0.45 + 0.01 * cos(progress * pi);
      rWristZ = 0.05;
    } else {
      final upper = label.toUpperCase();
      if (upper == 'HALO') {
        rWristX = 0.62 + 0.12 * sin(progress * 4 * pi);
        rWristY = 0.32 + 0.03 * cos(progress * 2 * pi);
        rWristZ = 0.08;
      } else if (upper == 'TERIMA KASIH' || upper == 'TERIMA') {
        rWristX = 0.52 + 0.04 * progress;
        rWristY = 0.35 + 0.18 * progress;
        rWristZ = 0.05 + 0.20 * progress;
      } else if (upper == 'SAYA' || upper == 'AKU') {
        rWristX = 0.50 + 0.02 * sin(progress * pi);
        rWristY = 0.48 - 0.05 * sin(progress * pi);
        rWristZ = -0.05;
      } else if (upper == 'BAIK' || upper == 'SEHAT') {
        rWristX = 0.58;
        rWristY = 0.55 - 0.15 * progress;
        rWristZ = 0.10;
      } else {
        rWristX = 0.55 + 0.08 * sin(progress * 2 * pi);
        rWristY = 0.45 + 0.06 * cos(progress * 2 * pi);
        rWristZ = 0.05;
      }
    }

    // Assign Right Hand (landmarks 54..74)
    raw[54 * 3 + 0] = rWristX;
    raw[54 * 3 + 1] = rWristY;
    raw[54 * 3 + 2] = rWristZ;

    raw[63 * 3 + 0] = rWristX;
    raw[63 * 3 + 1] = rWristY - 0.08;
    raw[63 * 3 + 2] = rWristZ + 0.02;

    for (int i = 0; i < 21; i++) {
      if (i == 0 || i == 9) continue;
      final idx = 54 + i;
      final fingerOffset = (i % 5) * 0.015;
      raw[idx * 3 + 0] = rWristX + fingerOffset;
      raw[idx * 3 + 1] = rWristY - 0.05 - (i ~/ 5) * 0.02;
      raw[idx * 3 + 2] = rWristZ;
    }

    // 3. Face Blendshapes (52 floats starting at offset 225)
    final blendshapeStart = 75 * 3;
    raw[blendshapeStart + 44] = (label.toUpperCase() == 'HALO' || label.toUpperCase() == 'BAIK') ? 0.65 : 0.15;
    raw[blendshapeStart + 45] = (label.toUpperCase() == 'HALO' || label.toUpperCase() == 'BAIK') ? 0.65 : 0.15;

    // Subtle signature in blendshape slot 51 (noseSneerRight) for high-fidelity reference classification
    if (classIdx >= 0) {
      raw[blendshapeStart + 51] = (classIdx + 1) / 1000.0;
    }

    return raw;
  }
}
