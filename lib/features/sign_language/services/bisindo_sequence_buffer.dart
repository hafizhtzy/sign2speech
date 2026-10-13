import 'dart:isolate';
import 'dart:typed_data';

class BisindoSequenceBuffer {
  static const int targetTimesteps = 48;
  static const int baseFeatureCount = 353;
  static const int deltaFeatureCount = 353;
  static const int totalFeatureDim = 706; // 353 + 353
  static const int totalTensorSize =
      targetTimesteps * totalFeatureDim; // 33,888

  final List<Float32List> _frames = [];
  final int maxCapacity;

  BisindoSequenceBuffer({this.maxCapacity = 120});

  int get frameCount => _frames.length;

  void addFrame(Float32List frame) {
    if (_frames.length >= maxCapacity) {
      _frames.removeAt(0);
    }
    _frames.add(frame);
  }

  void clear() {
    _frames.clear();
  }

  /// Builds [1, 48, 706] Float32 tensor with 1D linear temporal resampling and delta velocity.
  Float32List buildModelTensor() {
    return _buildTensorInternal(_frames);
  }

  /// Offloads 706-D tensor generation to a background Isolate for zero UI lag.
  Future<Float32List> buildModelTensorAsync() {
    final framesCopy = List<Float32List>.from(_frames);
    return Isolate.run(() => _buildTensorInternal(framesCopy));
  }

  static Float32List _buildTensorInternal(List<Float32List> sourceFrames) {
    final tensor = Float32List(totalTensorSize);
    if (sourceFrames.isEmpty) return tensor;

    final n = sourceFrames.length;
    final resampled = List<Float32List>.generate(
      targetTimesteps,
      (_) => Float32List(baseFeatureCount),
    );

    // 1D Linear Interpolation across time to 48 timesteps
    if (n == 1) {
      for (int t = 0; t < targetTimesteps; t++) {
        resampled[t].setAll(0, sourceFrames[0]);
      }
    } else {
      for (int t = 0; t < targetTimesteps; t++) {
        final normPos = (t / (targetTimesteps - 1)) * (n - 1);
        final idx0 = normPos.floor();
        final idx1 = (idx0 + 1 < n) ? idx0 + 1 : idx0;
        final alpha = normPos - idx0;

        final f0 = sourceFrames[idx0];
        final f1 = sourceFrames[idx1];

        for (int i = 0; i < baseFeatureCount; i++) {
          final val = (1.0 - alpha) * f0[i] + alpha * f1[i];
          resampled[t][i] = val;
        }
      }
    }

    // Pack Base (353) + Delta Velocity (353) = 706 into output tensor
    for (int t = 0; t < targetTimesteps; t++) {
      final stepOffset = t * totalFeatureDim;
      final currentBase = resampled[t];

      // 1. Copy base features (353)
      for (int i = 0; i < baseFeatureCount; i++) {
        tensor[stepOffset + i] = currentBase[i];
      }

      // 2. Compute delta velocity: delta[t] = clamp(base[t] - base[t-1], -4.0, 4.0), delta[0] = 0
      if (t == 0) {
        for (int i = 0; i < deltaFeatureCount; i++) {
          tensor[stepOffset + baseFeatureCount + i] = 0.0;
        }
      } else {
        final prevBase = resampled[t - 1];
        for (int i = 0; i < deltaFeatureCount; i++) {
          final diff = currentBase[i] - prevBase[i];
          tensor[stepOffset + baseFeatureCount + i] = diff.clamp(-4.0, 4.0);
        }
      }
    }

    return tensor;
  }
}
