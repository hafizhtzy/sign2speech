import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import '../models/landmark_frame.dart';

class BisindoFeatureExtractor {
  /// Extracts 353 geometric features from a LandmarkFrame synchronously.
  /// 0..62    : Left Hand Global (63 float, clamped [-6.0, 6.0])
  /// 63..125  : Left Hand Local  (63 float, clamped [-5.0, 5.0])
  /// 126..188 : Right Hand Global (63 float, clamped [-6.0, 6.0])
  /// 189..251 : Right Hand Local  (63 float, clamped [-5.0, 5.0])
  /// 252..296 : 15 Selected Pose Landmarks (45 float)
  /// 297..348 : 52 Face Blendshapes Coefficients (52 float)
  /// 349..352 : 4 Presence Masks [hasLeft, hasRight, hasPose, hasFace]
  static Float32List extract(LandmarkFrame frame) {
    final raw = frame.landmarks;
    final out = Float32List(353);

    // Default presence flags
    bool hasPose = false;
    bool hasLeft = false;
    bool hasRight = false;
    bool hasFace = false;

    // Helper to get landmark (x, y, z) at base index
    double getX(int idx) => (idx * 3 < raw.length) ? raw[idx * 3] : 0.0;
    double getY(int idx) => (idx * 3 + 1 < raw.length) ? raw[idx * 3 + 1] : 0.0;
    double getZ(int idx) => (idx * 3 + 2 < raw.length) ? raw[idx * 3 + 2] : 0.0;

    // Pose: 33 landmarks (0..32)
    // Left Shoulder: 11, Right Shoulder: 12
    final lsX = getX(11), lsY = getY(11), lsZ = getZ(11);
    final rsX = getX(12), rsY = getY(12), rsZ = getZ(12);

    hasPose = (lsX != 0.0 || rsX != 0.0 || lsY != 0.0 || rsY != 0.0);

    final scX = (lsX + rsX) / 2.0;
    final scY = (lsY + rsY) / 2.0;
    final scZ = (lsZ + rsZ) / 2.0;

    final dx = lsX - rsX;
    final dy = lsY - rsY;
    final dz = lsZ - rsZ;
    double shoulderDist = sqrt(dx * dx + dy * dy + dz * dz);
    if (shoulderDist < 1e-4) shoulderDist = 1.0;

    // Left Hand: landmarks 33..53 (21 landmarks)
    // Wrist: landmark 33, MCP Middle: landmark 42
    final lwX = getX(33), lwY = getY(33), lwZ = getZ(33);
    final lmX = getX(42), lmY = getY(42), lmZ = getZ(42);
    final ldx = lwX - lmX, ldy = lwY - lmY, ldz = lwZ - lmZ;
    double lPalmScale = sqrt(ldx * ldx + ldy * ldy + ldz * ldz);
    if (lPalmScale < 1e-4) lPalmScale = 0.2;

    for (int i = 0; i < 21; i++) {
      final pIdx = 33 + i;
      final px = getX(pIdx), py = getY(pIdx), pz = getZ(pIdx);
      if (px != 0.0 || py != 0.0 || pz != 0.0) hasLeft = true;

      // Global: 0..62
      out[i * 3 + 0] = ((px - scX) / (shoulderDist + 1e-6)).clamp(-6.0, 6.0);
      out[i * 3 + 1] = ((py - scY) / (shoulderDist + 1e-6)).clamp(-6.0, 6.0);
      out[i * 3 + 2] = ((pz - scZ) / (shoulderDist + 1e-6)).clamp(-6.0, 6.0);

      // Local: 63..125
      out[63 + i * 3 + 0] = ((px - lwX) / (lPalmScale + 1e-6)).clamp(-5.0, 5.0);
      out[63 + i * 3 + 1] = ((py - lwY) / (lPalmScale + 1e-6)).clamp(-5.0, 5.0);
      out[63 + i * 3 + 2] = ((pz - lwZ) / (lPalmScale + 1e-6)).clamp(-5.0, 5.0);
    }

    // Right Hand: landmarks 54..74 (21 landmarks)
    // Wrist: landmark 54, MCP Middle: landmark 63
    final rwX = getX(54), rwY = getY(54), rwZ = getZ(54);
    final rmX = getX(63), rmY = getY(63), rmZ = getZ(63);
    final rdx = rwX - rmX, rdy = rwY - rmY, rdz = rwZ - rmZ;
    double rPalmScale = sqrt(rdx * rdx + rdy * rdy + rdz * rdz);
    if (rPalmScale < 1e-4) rPalmScale = 0.2;

    for (int i = 0; i < 21; i++) {
      final pIdx = 54 + i;
      final px = getX(pIdx), py = getY(pIdx), pz = getZ(pIdx);
      if (px != 0.0 || py != 0.0 || pz != 0.0) hasRight = true;

      // Global: 126..188
      out[126 + i * 3 + 0] = ((px - scX) / (shoulderDist + 1e-6)).clamp(
        -6.0,
        6.0,
      );
      out[126 + i * 3 + 1] = ((py - scY) / (shoulderDist + 1e-6)).clamp(
        -6.0,
        6.0,
      );
      out[126 + i * 3 + 2] = ((pz - scZ) / (shoulderDist + 1e-6)).clamp(
        -6.0,
        6.0,
      );

      // Local: 189..251
      out[189 + i * 3 + 0] = ((px - rwX) / (rPalmScale + 1e-6)).clamp(
        -5.0,
        5.0,
      );
      out[189 + i * 3 + 1] = ((py - rwY) / (rPalmScale + 1e-6)).clamp(
        -5.0,
        5.0,
      );
      out[189 + i * 3 + 2] = ((pz - rwZ) / (rPalmScale + 1e-6)).clamp(
        -5.0,
        5.0,
      );
    }

    // 15 Selected Pose Landmarks: 252..296
    const poseSelected = [
      0,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
    ];
    for (int i = 0; i < poseSelected.length; i++) {
      final idx = poseSelected[i];
      out[252 + i * 3 + 0] = getX(idx);
      out[252 + i * 3 + 1] = getY(idx);
      out[252 + i * 3 + 2] = getZ(idx);
    }

    // Face Blendshapes: 297..348 (52 floats)
    // Starting offset for blendshapes in raw coordinates array (75 * 3 = 225)
    const blendshapeStart = 75 * 3;
    for (int i = 0; i < 52; i++) {
      final bIdx = blendshapeStart + i;
      if (bIdx < raw.length) {
        final val = raw[bIdx];
        out[297 + i] = val.clamp(-1.0, 1.0);
        if (val != 0.0) hasFace = true;
      }
    }

    // Presence masks: 349..352
    out[349] = hasLeft ? 1.0 : 0.0;
    out[350] = hasRight ? 1.0 : 0.0;
    out[351] = hasPose ? 1.0 : 0.0;
    out[352] = hasFace ? 1.0 : 0.0;

    return out;
  }

  /// Offloads 353-D feature extraction to a background Isolate for zero Main UI Thread lag.
  static Future<Float32List> extractAsync(LandmarkFrame frame) {
    return Isolate.run(() => extract(frame));
  }
}
