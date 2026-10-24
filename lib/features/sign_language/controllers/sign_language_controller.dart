import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../settings/controllers/settings_controller.dart';
import '../models/bisindo_prediction.dart';
import '../models/landmark_frame.dart';
import '../models/sign_capture_quality.dart';
import '../models/sign_language_model.dart';
import '../services/bisindo_classifier_service.dart';
import '../services/bisindo_feature_extractor.dart';
import '../services/bisindo_segmenter.dart';
import '../services/bisindo_sequence_buffer.dart';
import '../services/bisindo_synthetic_gesture_generator.dart';
import '../services/camera_feed_service.dart';

/// Lifecycle of the Sign Language (BISINDO & SIBI) recognizer.
enum BisindoLiveState {
  initializing,
  stopped,
  listening,
  signing,
  classifying,
  recognized,
  rejected,
  manualCountdown,
  manualCapturing,
  error,
}

/// SignLanguageController manages continuous sign spotting ([BisindoSegmenter]),
/// streaming live preview inference with hold-to-confirm, and MotionGRU TFLite classification
/// matching the HajiCare high-accuracy pipeline 1:1.
class SignLanguageController extends GetxController {
  final BisindoClassifierService classifierService;
  final BisindoSegmenter segmenter;
  final BisindoSequenceBuffer sequenceBuffer;
  final CameraFeedService cameraFeedService;
  void Function(BisindoPrediction prediction)? onPredictionAccepted;

  /// Minimum top1-top2 probability gap for auto-committing in continuous mode.
  final double minContinuousMargin;

  SignLanguageController({
    BisindoClassifierService? classifierService,
    BisindoSegmenter? segmenter,
    BisindoSequenceBuffer? sequenceBuffer,
    CameraFeedService? cameraFeedService,
    this.onPredictionAccepted,
    this.minContinuousMargin = 0.15,
  })  : classifierService = classifierService ?? BisindoClassifierService(),
        segmenter = segmenter ?? BisindoSegmenter(),
        sequenceBuffer = sequenceBuffer ?? BisindoSequenceBuffer(),
        cameraFeedService = cameraFeedService ??
            (Get.isRegistered<CameraFeedService>()
                ? Get.find<CameraFeedService>()
                : CameraFeedService()) {
    this.cameraFeedService.onFrame = (frame) {
      onIncomingLandmarkFrame(frame);
    };
  }

  static const Duration kManualCaptureDuration = Duration(milliseconds: 2800);
  static const Duration kRecognizedHold = Duration(milliseconds: 700);
  static const Duration kRejectedHold = Duration(milliseconds: 1400);

  // Reactive UI States
  final currentModel = SignLanguageModel.bisindo.obs;
  final state = BisindoLiveState.stopped.obs;
  final isContinuousRunning = false.obs;
  final isCameraActive = false.obs;
  final isFrontCamera = true.obs;
  final isInferring = false.obs;
  final holdProgress = 0.0.obs;

  final countdownSeconds = 3.obs;
  final captureProgress = 0.0.obs;
  final framesCollected = 0.obs;

  // Streaming Gesture Suggestion & Clockwise Hold-to-Confirm
  final streamingCandidate = ''.obs;
  final suggestionProgress = 0.0.obs;
  final isCandidateConfirmed = false.obs;

  // Prediction & Guidance
  final detectedLabel = ''.obs;
  final confidenceScore = 0.0.obs;
  final guidanceMessage = ''.obs;
  final statusMessage = 'Tekan MULAI untuk mendeteksi'.obs;
  final topCandidates = <BisindoCandidate>[].obs;
  final lastQuality = Rxn<SignCaptureQuality>();
  final captureQuality = const SignCaptureQuality().obs;
  final latestPrediction = Rx<BisindoPrediction?>(null);

  // Backward compatibility alias
  Rx<SignLanguageModelType> get activeModel => Rx<SignLanguageModelType>(
        currentModel.value.toModelType,
      );

  // Continuous pipeline
  bool _isClassifying = false;
  bool _isPreviewing = false;
  DateTime _lastPreviewTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _candidateStreak = 0;
  String _lastCandidateLabel = '';
  double _lastCandidateConfidence = 0.0;
  String _pendingCandidateLabel = '';
  int _pendingCandidateCount = 0;
  DateTime? _segmentStartDateTime;
  int _lastInferenceDurationMs = 0;
  bool _isCommittedForCurrentSegment = false;
  BisindoSegment? _pendingSegment;
  Timer? _transientTimer;

  // Frame timing
  int _lastFrameTimestampMs = 0;
  static const int kMinFrameIntervalMs = 33; // ~30 FPS

  // Manual pipeline
  final List<LandmarkFrame> _manualFrames = [];
  Timer? _countdownTimer;
  Timer? _captureTimer;
  Timer? _progressTicker;
  DateTime? _captureStartTime;

  bool _isDisposed = false;

  bool get isReadyForInput =>
      state.value != BisindoLiveState.initializing &&
      state.value != BisindoLiveState.error;

  bool get isManualActive =>
      state.value == BisindoLiveState.manualCountdown ||
      state.value == BisindoLiveState.manualCapturing;

  String get stateStatusText {
    final modelName = currentModel.value.displayName;
    switch (state.value) {
      case BisindoLiveState.initializing:
        return 'Menyiapkan modul $modelName...';
      case BisindoLiveState.stopped:
        return 'Tekan MULAI untuk mendeteksi $modelName';
      case BisindoLiveState.listening:
        return 'Siap — lakukan isyarat $modelName';
      case BisindoLiveState.signing:
        return 'Membaca gerakan...';
      case BisindoLiveState.classifying:
        return 'Memproses gerakan...';
      case BisindoLiveState.recognized:
        return 'Terdeteksi: ${detectedLabel.value.toUpperCase()}';
      case BisindoLiveState.rejected:
        return guidanceMessage.value.isNotEmpty
            ? guidanceMessage.value
            : 'Gerakan belum dikenali. Silakan ulangi.';
      case BisindoLiveState.manualCountdown:
        return 'Bersiap dalam ${countdownSeconds.value}...';
      case BisindoLiveState.manualCapturing:
        return 'Lakukan satu gerakan $modelName';
      case BisindoLiveState.error:
        return guidanceMessage.value.isNotEmpty
            ? guidanceMessage.value
            : 'Modul $modelName bermasalah. Silakan coba lagi.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    _syncWithSettings();
    unawaited(initializeServices());
  }

  void _syncWithSettings() {
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      if (settings.selectedSignLanguage.value.toUpperCase() == 'SIBI') {
        currentModel.value = SignLanguageModel.sibi;
      } else {
        currentModel.value = SignLanguageModel.bisindo;
      }

      ever(settings.selectedSignLanguage, (lang) {
        final target = lang.toUpperCase() == 'SIBI'
            ? SignLanguageModel.sibi
            : SignLanguageModel.bisindo;
        if (currentModel.value != target) {
          switchModel(target);
        }
      });
    }
  }

  Future<void> initializeServices({SignLanguageModel? model}) async {
    state.value = BisindoLiveState.initializing;
    try {
      final target = model ?? currentModel.value;
      await classifierService.loadModel(target.config);
      currentModel.value = target;
      if (_isDisposed) return;
      state.value = isContinuousRunning.value
          ? BisindoLiveState.listening
          : BisindoLiveState.stopped;
      statusMessage.value = stateStatusText;
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Initialization failed: $e');
      if (!_isDisposed) {
        guidanceMessage.value =
            'Gagal memuat model ${currentModel.value.displayName}. Silakan mulai ulang.';
        state.value = BisindoLiveState.error;
      }
    }
  }

  /// Seamlessly switches between SIBI and BISINDO models in memory.
  Future<void> switchModel(SignLanguageModel targetModel) async {
    if (currentModel.value == targetModel && classifierService.isInitialized) {
      return;
    }
    try {
      currentModel.value = targetModel;
      await classifierService.loadModel(targetModel.config);
      segmenter.reset();
      sequenceBuffer.clear();
      detectedLabel.value = '';
      confidenceScore.value = 0.0;
      topCandidates.clear();
      guidanceMessage.value = '';
      _isCommittedForCurrentSegment = false;
      isCandidateConfirmed.value = false;
      _resetStreamingPreviewState();

      if (Get.isRegistered<SettingsController>()) {
        final settings = Get.find<SettingsController>();
        final langStr =
            targetModel == SignLanguageModel.bisindo ? 'BISINDO' : 'SIBI';
        if (settings.selectedSignLanguage.value != langStr) {
          settings.setSignLanguage(langStr);
        }
      }

      statusMessage.value =
          'Model ${targetModel.displayName} aktif (${targetModel.classCount} kelas)';
      debugPrint(
        '[SIGN_LANGUAGE_CONTROLLER] Switched to ${targetModel.displayName} successfully.',
      );
    } catch (e) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Switch model error: $e');
      rethrow;
    }
  }

  void toggleModel() {
    if (currentModel.value == SignLanguageModel.bisindo) {
      switchModel(SignLanguageModel.sibi);
    } else {
      switchModel(SignLanguageModel.bisindo);
    }
  }

  void setModel(SignLanguageModelType modelType) {
    switchModel(
      modelType == SignLanguageModelType.sibi
          ? SignLanguageModel.sibi
          : SignLanguageModel.bisindo,
    );
  }

  void toggleCameraActive() {
    if (isContinuousRunning.value) {
      stopContinuous();
    } else {
      startContinuous();
    }
  }

  Future<void> flipCamera() async {
    isFrontCamera.value = !isFrontCamera.value;
    if (isCameraActive.value) {
      await cameraFeedService.switchCamera();
    }
  }

  Future<void> retryStartCamera() async {
    await startContinuous();
  }

  /// Starts hands-free continuous detection and native CameraX feed.
  Future<void> startContinuous() async {
    if (_isDisposed) return;
    isContinuousRunning.value = true;
    isCameraActive.value = true;
    segmenter.reset();
    sequenceBuffer.clear();
    guidanceMessage.value = '';
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    _resetStreamingPreviewState();

    if (state.value == BisindoLiveState.initializing ||
        state.value == BisindoLiveState.error ||
        isManualActive) {
      return;
    }
    _transientTimer?.cancel();
    state.value = BisindoLiveState.listening;
    statusMessage.value = 'Siap — lakukan isyarat';

    final ok = await cameraFeedService.startCamera();
    if (!ok && cameraFeedService.errorMessage.value.isNotEmpty) {
      statusMessage.value = cameraFeedService.errorMessage.value;
    }
  }

  /// Stops detection and releases camera feed.
  Future<void> stopContinuous() async {
    if (_isDisposed) return;
    isContinuousRunning.value = false;
    isCameraActive.value = false;
    _cancelManualTimers();
    _manualFrames.clear();
    _transientTimer?.cancel();
    segmenter.reset();
    sequenceBuffer.clear();
    _pendingSegment = null;
    framesCollected.value = 0;
    captureProgress.value = 0.0;
    holdProgress.value = 0.0;
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    _resetStreamingPreviewState();

    await cameraFeedService.stopCamera();

    if (state.value != BisindoLiveState.initializing &&
        state.value != BisindoLiveState.error) {
      state.value = BisindoLiveState.stopped;
      statusMessage.value = 'Kamera dijeda / Tekan MULAI';
    }
  }

  /// Ingests a camera landmark frame from native EventChannel.
  void onIncomingLandmarkFrame(LandmarkFrame frame, {int? nowMs}) {
    if (_isDisposed) return;

    if (state.value == BisindoLiveState.manualCapturing) {
      _manualFrames.add(frame);
      framesCollected.value = _manualFrames.length;
      return;
    }

    if (!isContinuousRunning.value || !isReadyForInput || isManualActive) {
      return;
    }

    final currentMs = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (currentMs - _lastFrameTimestampMs < kMinFrameIntervalMs) {
      return;
    }
    _lastFrameTimestampMs = currentMs;

    // Segment frame using pure-Dart BisindoSegmenter
    final segment = segmenter.add(frame, nowMs: currentMs);
    framesCollected.value = segmenter.activeFrameCount;
    captureProgress.value = segmenter.isActive
        ? (segmenter.activeFrameCount / BisindoSequenceBuffer.kSequenceLength)
            .clamp(0.0, 1.0)
        : 0.0;

    if (segmenter.isActive) {
      if (state.value == BisindoLiveState.listening ||
          state.value == BisindoLiveState.recognized ||
          state.value == BisindoLiveState.rejected) {
        _transientTimer?.cancel();
        state.value = BisindoLiveState.signing;
        _isCommittedForCurrentSegment = false;
        isCandidateConfirmed.value = false;
        _segmentStartDateTime = DateTime.now();
      } else {
        _segmentStartDateTime ??= DateTime.now();
      }
      _maybeRunStreamingPreview();
    } else {
      _segmentStartDateTime = null;
      if (state.value == BisindoLiveState.signing) {
        state.value = BisindoLiveState.listening;
      }
      if (!isCandidateConfirmed.value) {
        _resetStreamingPreviewState();
      }
    }

    if (segment != null) {
      _enqueueSegment(segment);
    }
  }

  void _enqueueSegment(BisindoSegment segment) {
    if (_isClassifying) {
      _pendingSegment = segment;
      return;
    }
    unawaited(_classifySegment(segment));
  }

  Future<void> _classifySegment(BisindoSegment segment) async {
    if (_isCommittedForCurrentSegment) {
      segmenter.reset();
      return;
    }
    _isClassifying = true;
    state.value = BisindoLiveState.classifying;
    try {
      final isSibi = currentModel.value == SignLanguageModel.sibi;
      final effectiveMargin = isSibi
          ? math.min(minContinuousMargin, 0.08)
          : minContinuousMargin;

      await _classifyFrames(
        segment.frames,
        minMargin: effectiveMargin,
        source: 'auto/${segment.reason.name}',
      );
    } finally {
      _isClassifying = false;
      final next = _pendingSegment;
      _pendingSegment = null;
      if (state.value == BisindoLiveState.classifying) {
        _settleIdleState();
      }
      if (next != null && !_isDisposed && isContinuousRunning.value) {
        unawaited(_classifySegment(next));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Streaming Preview Inference (Live Suggestions & Hold-to-Confirm)
  // ---------------------------------------------------------------------------

  void _maybeRunStreamingPreview() {
    if (_isDisposed ||
        _isClassifying ||
        _isPreviewing ||
        _isCommittedForCurrentSegment ||
        !classifierService.isInitialized) {
      return;
    }

    final activeFrames = segmenter.activeFrames;
    if (activeFrames.length < 8) return;

    final now = DateTime.now();
    final minInterval = math.max(
      280,
      _lastInferenceDurationMs > 50 ? _lastInferenceDurationMs + 90 : 280,
    );
    if (now.difference(_lastPreviewTime).inMilliseconds < minInterval) return;
    _lastPreviewTime = now;

    unawaited(_runPreviewInference(List<LandmarkFrame>.of(activeFrames)));
  }

  Future<void> _runPreviewInference(List<LandmarkFrame> frames) async {
    _isPreviewing = true;
    final stopwatch = Stopwatch()..start();
    try {
      final buffer = BisindoSequenceBuffer();
      for (final frame in frames) {
        buffer.addBaseFeature(
          BisindoFeatureExtractor.extractBaseFeature(frame),
        );
      }
      final inputTensor = buffer.prepareModelInput();
      final prediction = await classifierService.classify(
        inputTensor,
        modelType: currentModel.value.toModelType,
      );
      stopwatch.stop();
      _lastInferenceDurationMs = stopwatch.elapsedMilliseconds;

      if (_isDisposed ||
          !segmenter.isActive ||
          _isCommittedForCurrentSegment ||
          prediction == null) {
        return;
      }

      final isSibi = currentModel.value == SignLanguageModel.sibi;
      final candidateThreshold = isSibi
          ? 0.35
          : (classifierService.confidenceThreshold * 0.58).clamp(0.35, 0.52);

      if (prediction.isRecognized &&
          prediction.label.isNotEmpty &&
          prediction.confidence >= candidateThreshold) {
        confidenceScore.value = prediction.confidence;
        topCandidates.assignAll(prediction.candidates);

        final newCandidate = prediction.cleanLabel;
        final newConfidence = prediction.confidence;

        // Anti-jitter hysteresis & candidate stabilization for camera noise
        if (_lastCandidateLabel.isEmpty) {
          _lastCandidateLabel = newCandidate;
          _lastCandidateConfidence = newConfidence;
          _candidateStreak = 1;
          _pendingCandidateLabel = '';
          _pendingCandidateCount = 0;
        } else if (newCandidate == _lastCandidateLabel) {
          _candidateStreak++;
          _lastCandidateConfidence =
              0.65 * _lastCandidateConfidence + 0.35 * newConfidence;
          _pendingCandidateLabel = '';
          _pendingCandidateCount = 0;
        } else {
          if (newConfidence > _lastCandidateConfidence + 0.18 ||
              _candidateStreak <= 1) {
            _lastCandidateLabel = newCandidate;
            _lastCandidateConfidence = newConfidence;
            _candidateStreak = 1;
            _pendingCandidateLabel = '';
            _pendingCandidateCount = 0;
          } else {
            if (_pendingCandidateLabel == newCandidate) {
              _pendingCandidateCount++;
              if (_pendingCandidateCount >= 2) {
                _lastCandidateLabel = newCandidate;
                _lastCandidateConfidence = newConfidence;
                _candidateStreak = 2;
                _pendingCandidateLabel = '';
                _pendingCandidateCount = 0;
              }
            } else {
              _pendingCandidateLabel = newCandidate;
              _pendingCandidateCount = 1;
            }
          }
        }

        streamingCandidate.value = _lastCandidateLabel;

        final elapsedMs = _segmentStartDateTime != null
            ? DateTime.now().difference(_segmentStartDateTime!).inMilliseconds
            : (frames.length * 50);

        final streakFactor = (_candidateStreak / 4.0).clamp(0.0, 1.0);
        final timeFactor = (elapsedMs / 700.0).clamp(0.0, 1.0);
        final combinedProgress = math
            .max(streakFactor * 0.55 + timeFactor * 0.45, streakFactor * 0.75)
            .clamp(0.0, 1.0);

        suggestionProgress.value = combinedProgress;
        holdProgress.value = combinedProgress;

        final targetCommitConfidence = isSibi
            ? math.min(classifierService.confidenceThreshold, 0.58)
            : classifierService.confidenceThreshold;

        if (combinedProgress >= 0.92 &&
            prediction.confidence >= targetCommitConfidence &&
            !_isCommittedForCurrentSegment) {
          _confirmAndCommitCandidate(prediction);
        }
      } else {
        if (_candidateStreak > 0) {
          _candidateStreak = math.max(0, _candidateStreak - 1);
          suggestionProgress.value = (_candidateStreak / 4.0).clamp(0.0, 1.0);
          holdProgress.value = suggestionProgress.value;
        }
      }
    } catch (e) {
      debugPrint('[STREAMING_PREVIEW] error: $e');
    } finally {
      _isPreviewing = false;
    }
  }

  void _confirmAndCommitCandidate(BisindoPrediction prediction) {
    if (_isCommittedForCurrentSegment || _isDisposed) return;
    _isCommittedForCurrentSegment = true;
    isCandidateConfirmed.value = true;
    suggestionProgress.value = 1.0;
    holdProgress.value = 1.0;
    detectedLabel.value = prediction.cleanLabel;
    confidenceScore.value = prediction.confidence;
    latestPrediction.value = prediction;
    statusMessage.value =
        'Terdeteksi: ${prediction.cleanLabel} (${(prediction.confidence * 100).toStringAsFixed(0)}%)';

    HapticFeedback.mediumImpact();
    onPredictionAccepted?.call(prediction);

    _transientTimer?.cancel();
    state.value = BisindoLiveState.recognized;
    _transientTimer = Timer(kRecognizedHold, () {
      if (_isDisposed) return;
      isCandidateConfirmed.value = false;
      _resetStreamingPreviewState();
      if (segmenter.isActive) {
        state.value = BisindoLiveState.signing;
      } else {
        state.value = isContinuousRunning.value
            ? BisindoLiveState.listening
            : BisindoLiveState.stopped;
      }
    });
  }

  void _resetStreamingPreviewState() {
    streamingCandidate.value = '';
    suggestionProgress.value = 0.0;
    holdProgress.value = 0.0;
    _candidateStreak = 0;
    _lastCandidateLabel = '';
    _lastCandidateConfidence = 0.0;
    _pendingCandidateLabel = '';
    _pendingCandidateCount = 0;
    _segmentStartDateTime = null;
  }

  // ---------------------------------------------------------------------------
  // Shared classification
  // ---------------------------------------------------------------------------

  Future<void> _classifyFrames(
    List<LandmarkFrame> frames, {
    required double minMargin,
    required String source,
  }) async {
    if (_isDisposed) return;
    if (_isCommittedForCurrentSegment) {
      _settleIdleState();
      return;
    }
    try {
      final quality = SignCaptureQuality.fromFrames(frames);
      lastQuality.value = quality;
      final qualityCheck = quality.validate();
      if (!qualityCheck.isValid) {
        _reject(
          qualityCheck.userErrorMessage ??
              'Gagal mendeteksi: gerakan tangan kurang jelas. Silakan ulangi.',
        );
        return;
      }

      final buffer = BisindoSequenceBuffer();
      for (final frame in frames) {
        buffer.addBaseFeature(
          BisindoFeatureExtractor.extractBaseFeature(frame),
        );
      }
      final inputTensor = buffer.prepareModelInput();
      final prediction = await classifierService.classify(
        inputTensor,
        modelType: currentModel.value.toModelType,
      );

      if (_isDisposed || _isCommittedForCurrentSegment) {
        if (state.value == BisindoLiveState.classifying) {
          _settleIdleState();
        }
        return;
      }

      if (prediction == null) {
        _reject('Gerakan belum dikenali. Silakan ulangi.');
        return;
      }

      confidenceScore.value = prediction.confidence;
      topCandidates.assignAll(prediction.candidates);

      final isSibi = currentModel.value == SignLanguageModel.sibi;
      final minConfidenceReq = isSibi ? 0.45 : 0.50;

      if (prediction.confidence < minConfidenceReq) {
        _reject(
          'Gagal mendeteksi gestur (Keyakinan ${(prediction.confidence * 100).toStringAsFixed(0)}% < ${(minConfidenceReq * 100).toStringAsFixed(0)}%). Silakan ulangi.',
        );
        return;
      }

      final accepted = prediction.isRecognized &&
          prediction.label.isNotEmpty &&
          prediction.margin >= minMargin;

      if (!accepted) {
        _reject('Gerakan belum dikenali. Silakan ulangi gerakan.');
        return;
      }

      guidanceMessage.value = '';
      _confirmAndCommitCandidate(prediction);
    } catch (e, st) {
      debugPrint('[SIGN_LANGUAGE_CONTROLLER] Processing error: $e\n$st');
      _reject('Terjadi kesalahan pemrosesan gerakan. Silakan coba lagi.');
    }
  }

  void _reject(String message) {
    _resetStreamingPreviewState();
    guidanceMessage.value = message;
    _showTransient(BisindoLiveState.rejected, kRejectedHold);
  }

  void _showTransient(BisindoLiveState transient, Duration hold) {
    if (_isDisposed) return;
    _transientTimer?.cancel();
    state.value = transient;
    _transientTimer = Timer(hold, () {
      if (_isDisposed || state.value != transient) return;
      _settleIdleState();
    });
  }

  void _settleIdleState() {
    if (!isContinuousRunning.value) {
      state.value = BisindoLiveState.stopped;
    } else {
      state.value = segmenter.isActive
          ? BisindoLiveState.signing
          : BisindoLiveState.listening;
    }
  }

  // ---------------------------------------------------------------------------
  // Gesture Simulation (Realistic synthetic tensor for testing)
  // ---------------------------------------------------------------------------

  Future<BisindoPrediction?> simulateGesture(String label) async {
    if (!isCameraActive.value) {
      startContinuous();
    }

    state.value = BisindoLiveState.signing;
    streamingCandidate.value = label;
    suggestionProgress.value = 0.50;
    holdProgress.value = 0.50;

    final tensor =
        BisindoSyntheticGestureGenerator.generateTensorForLabel(label);
    state.value = BisindoLiveState.classifying;
    final prediction = await runInference(tensor);

    if (prediction != null) {
      suggestionProgress.value = 1.0;
      holdProgress.value = 1.0;
      _confirmAndCommitCandidate(prediction);
    } else {
      _reject('Gerakan belum dikenali');
    }
    return prediction;
  }

  Future<BisindoPrediction?> runInference(dynamic tensor) async {
    isInferring.value = true;
    try {
      final prediction = await classifierService.classify(
        tensor,
        modelType: currentModel.value.toModelType,
      );
      if (prediction != null) {
        latestPrediction.value = prediction;
        detectedLabel.value = prediction.cleanLabel;
        confidenceScore.value = prediction.confidence;
      }
      return prediction;
    } finally {
      isInferring.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Manual capture session: 3s countdown → 2.8s capture → classify
  // ---------------------------------------------------------------------------

  void startCaptureSession({bool skipCountdown = false}) {
    if (_isDisposed ||
        !isReadyForInput ||
        isManualActive ||
        state.value == BisindoLiveState.classifying) {
      return;
    }

    _cancelManualTimers();
    _transientTimer?.cancel();
    segmenter.reset();
    _pendingSegment = null;
    _manualFrames.clear();
    framesCollected.value = 0;
    captureProgress.value = 0.0;
    guidanceMessage.value = '';
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    _resetStreamingPreviewState();

    if (skipCountdown) {
      _beginManualRecording();
      return;
    }
    state.value = BisindoLiveState.manualCountdown;
    countdownSeconds.value = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (countdownSeconds.value > 1) {
        countdownSeconds.value--;
      } else {
        timer.cancel();
        _beginManualRecording();
      }
    });
  }

  void _beginManualRecording() {
    if (_isDisposed) return;
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    state.value = BisindoLiveState.manualCapturing;
    _captureStartTime = DateTime.now();

    _progressTicker = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed || state.value != BisindoLiveState.manualCapturing) {
        timer.cancel();
        return;
      }
      final elapsed =
          DateTime.now().difference(_captureStartTime!).inMilliseconds;
      captureProgress.value = (elapsed / kManualCaptureDuration.inMilliseconds)
          .clamp(0.0, 1.0);
    });

    _captureTimer = Timer(kManualCaptureDuration, () {
      _progressTicker?.cancel();
      unawaited(_finishManualRecording());
    });
  }

  Future<void> _finishManualRecording() async {
    if (_isDisposed) return;
    captureProgress.value = 1.0;
    final frames = List<LandmarkFrame>.of(_manualFrames);
    _manualFrames.clear();
    _isClassifying = true;
    _isCommittedForCurrentSegment = false;
    isCandidateConfirmed.value = false;
    state.value = BisindoLiveState.classifying;
    try {
      await _classifyFrames(frames, minMargin: 0.0, source: 'manual');
    } finally {
      _isClassifying = false;
      segmenter.reset();
      if (state.value == BisindoLiveState.classifying) {
        _settleIdleState();
      }
    }
  }

  void _cancelManualTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _captureTimer?.cancel();
    _captureTimer = null;
    _progressTicker?.cancel();
    _progressTicker = null;
  }

  @override
  void onClose() {
    _isDisposed = true;
    _cancelManualTimers();
    _transientTimer?.cancel();
    _manualFrames.clear();
    segmenter.reset();
    _pendingSegment = null;
    unawaited(classifierService.dispose());
    super.onClose();
  }
}
