import 'dart:isolate';
import 'dart:typed_data';

/// Manages temporal collection, uniform linear interpolation resampling (to 48 timesteps),
/// first-order motion velocity calculation, and final [1, 48, 706] model input tensor construction.
class BisindoSequenceBuffer {
  static const int kSequenceLength = 48;
  static const int kBaseFeatureDim = 353;
  static const int kModelInputFeatureDim = 706;
  static const int totalTensorSize = kSequenceLength * kModelInputFeatureDim; // 33,888

  // Backward compatibility aliases
  static const int targetTimesteps = kSequenceLength;
  static const int baseFeatureCount = kBaseFeatureDim;
  static const int deltaFeatureCount = kBaseFeatureDim;
  static const int totalFeatureDim = kModelInputFeatureDim;

  final List<Float32List> _capturedBaseFeatures = [];
  final int maxCapacity;

  BisindoSequenceBuffer({this.maxCapacity = 120});

  List<Float32List> get capturedFeatures =>
      List.unmodifiable(_capturedBaseFeatures);

  int get length => _capturedBaseFeatures.length;
  int get frameCount => _capturedBaseFeatures.length;

  void addBaseFeature(Float32List feature) {
    assert(
      feature.length == kBaseFeatureDim,
      'Expected feature length $kBaseFeatureDim, got ${feature.length}',
    );
    if (_capturedBaseFeatures.length >= maxCapacity) {
      _capturedBaseFeatures.removeAt(0);
    }
    _capturedBaseFeatures.add(feature);
  }

  void addFrame(Float32List frame) => addBaseFeature(frame);

  void clear() {
    _capturedBaseFeatures.clear();
  }

  /// Uniformly resamples the captured sequence of N frames (N >= 2)
  /// to exactly 48 timesteps using 1D linear interpolation across each of the 353 dimensions.
  static List<Float32List> resampleBaseSequence(
    List<Float32List> originalSequence, {
    int targetLength = kSequenceLength,
  }) {
    if (originalSequence.isEmpty) {
      return List.generate(targetLength, (_) => Float32List(kBaseFeatureDim));
    }

    final int n = originalSequence.length;
    if (n == 1) {
      return List.generate(
        targetLength,
        (_) => Float32List.fromList(originalSequence.first),
      );
    }

    final List<Float32List> resampled = [];

    for (int t = 0; t < targetLength; t++) {
      final double targetT = t / (targetLength - 1.0); // 0.0 .. 1.0
      final double position = targetT * (n - 1.0);
      final int k = position.floor().clamp(0, n - 2);
      final double alpha = (position - k).clamp(0.0, 1.0);

      final frame0 = originalSequence[k];
      final frame1 = originalSequence[k + 1];

      final Float32List interpolatedFrame = Float32List(kBaseFeatureDim);
      for (int d = 0; d < kBaseFeatureDim; d++) {
        final double v0 = frame0[d];
        final double v1 = frame1[d];
        interpolatedFrame[d] = (v0 + alpha * (v1 - v0)).toDouble();
      }

      resampled.add(interpolatedFrame);
    }

    return resampled;
  }

  /// Computes first-order velocity delta for each timestep:
  /// delta[0] = zero (353 zeros)
  /// delta[t] = base[t] - base[t-1], clipped to [-4.0, 4.0]
  static List<Float32List> computeMotionDelta(List<Float32List> baseSequence) {
    final int seqLen = baseSequence.length;
    final List<Float32List> deltas = [];

    for (int t = 0; t < seqLen; t++) {
      final Float32List delta = Float32List(kBaseFeatureDim);
      if (t > 0) {
        final current = baseSequence[t];
        final prev = baseSequence[t - 1];
        for (int d = 0; d < kBaseFeatureDim; d++) {
          final diff = current[d] - prev[d];
          delta[d] = diff.clamp(-4.0, 4.0).toDouble();
        }
      }
      deltas.add(delta);
    }

    return deltas;
  }

  /// Concatenates base features + motion deltas along feature dimension:
  /// modelInput[t] = [ base[t] (353), delta[t] (353) ] -> 706 floats.
  /// Result: [48, 706].
  static List<Float32List> concatenateBaseAndDelta({
    required List<Float32List> baseSequence,
    required List<Float32List> deltaSequence,
  }) {
    assert(
      baseSequence.length == deltaSequence.length,
      'Base and delta sequence lengths must match',
    );
    final int seqLen = baseSequence.length;
    final List<Float32List> combined = [];

    for (int t = 0; t < seqLen; t++) {
      final Float32List frame706 = Float32List(kModelInputFeatureDim);
      final base = baseSequence[t];
      final delta = deltaSequence[t];

      for (int d = 0; d < kBaseFeatureDim; d++) {
        frame706[d] = base[d];
        frame706[kBaseFeatureDim + d] = delta[d];
      }

      combined.add(frame706);
    }

    return combined;
  }

  /// Processes the captured session base features into final model input tensor
  /// Returns a nested List representing shape [1, 48, 706] for TFLite inference.
  List<List<List<double>>> prepareModelInput() {
    if (_capturedBaseFeatures.length < 2) {
      if (_capturedBaseFeatures.isEmpty) {
        return [
          List.generate(
            kSequenceLength,
            (_) => List<double>.filled(kModelInputFeatureDim, 0.0),
          ),
        ];
      }
      // Single frame: duplicate
      final single = _capturedBaseFeatures.first;
      final resampled = List.generate(
        kSequenceLength,
        (_) => Float32List.fromList(single),
      );
      final deltas = computeMotionDelta(resampled);
      final combined = concatenateBaseAndDelta(
        baseSequence: resampled,
        deltaSequence: deltas,
      );
      return [
        List.generate(kSequenceLength, (t) {
          final frame = combined[t];
          return List<double>.generate(kModelInputFeatureDim, (d) => frame[d]);
        }),
      ];
    }

    // 1. Resample to 48 timesteps
    final resampledBase = resampleBaseSequence(_capturedBaseFeatures);

    // 2. Compute motion delta clipped to [-4.0, 4.0]
    final deltas = computeMotionDelta(resampledBase);

    // 3. Concatenate base + delta -> [48, 706]
    final combined706 = concatenateBaseAndDelta(
      baseSequence: resampledBase,
      deltaSequence: deltas,
    );

    // 4. Wrap with batch dimension [1, 48, 706]
    final List<List<List<double>>> tensorInput = [
      List.generate(kSequenceLength, (t) {
        final frame = combined706[t];
        return List<double>.generate(kModelInputFeatureDim, (d) => frame[d]);
      }),
    ];

    return tensorInput;
  }

  /// Backward-compatible flat Float32List (33,888 floats) for existing tests.
  Float32List buildModelTensor() {
    final tensor = Float32List(totalTensorSize);
    if (_capturedBaseFeatures.isEmpty) return tensor;

    final resampled = resampleBaseSequence(_capturedBaseFeatures);
    final deltas = computeMotionDelta(resampled);
    final combined = concatenateBaseAndDelta(
      baseSequence: resampled,
      deltaSequence: deltas,
    );

    for (int t = 0; t < kSequenceLength; t++) {
      final stepOffset = t * kModelInputFeatureDim;
      final frame = combined[t];
      for (int i = 0; i < kModelInputFeatureDim; i++) {
        tensor[stepOffset + i] = frame[i];
      }
    }

    return tensor;
  }

  /// Offloads 706-D tensor generation to a background Isolate.
  Future<Float32List> buildModelTensorAsync() {
    final framesCopy = List<Float32List>.from(_capturedBaseFeatures);
    return Isolate.run(() {
      final buffer = BisindoSequenceBuffer();
      for (final f in framesCopy) {
        buffer.addBaseFeature(f);
      }
      return buffer.buildModelTensor();
    });
  }
}
