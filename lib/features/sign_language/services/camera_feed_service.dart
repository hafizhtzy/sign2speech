import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/landmark_frame.dart';

/// CameraFeedService connects Flutter to native Android CameraX + MediaPipe Holistic
/// via MethodChannel and EventChannel without external camera / permission plugins.
class CameraFeedService extends GetxService {
  static const String kMethodChannelName =
      'com.speech2sign.bisindo/camera_control';
  static const String kEventChannelName =
      'com.speech2sign.bisindo/landmarks';

  final MethodChannel _methodChannel = const MethodChannel(kMethodChannelName);
  final EventChannel _eventChannel = const EventChannel(kEventChannelName);

  void Function(LandmarkFrame frame)? onFrame;

  StreamSubscription<dynamic>? _eventSubscription;
  int _generation = 0;

  // Reactive state
  final isInitialized = false.obs;
  final isLoading = false.obs;
  final isPermissionGranted = false.obs;
  final isPermissionPermanentlyDenied = false.obs;
  final isFrontCamera = true.obs;
  final isCameraActive = false.obs;
  final errorMessage = ''.obs;
  final hasCameraHardware = true.obs;
  final receivedFramesCount = 0.obs;

  bool get isCameraReady => isInitialized.value && isCameraActive.value;

  @override
  void onInit() {
    super.onInit();
    checkPermission();
  }

  /// Checks the current camera permission status from native OS.
  Future<bool> checkPermission() async {
    try {
      final String? result = await _methodChannel.invokeMethod<String>(
        'checkPermission',
      );
      final granted = result == 'granted';
      isPermissionGranted.value = granted;
      if (granted) {
        errorMessage.value = '';
      }
      return granted;
    } catch (_) {
      // In test / desktop environments
      return false;
    }
  }

  /// Requests runtime camera permission directly from Android OS without third-party plugins.
  Future<bool> requestPermission() async {
    try {
      final String? result = await _methodChannel.invokeMethod<String>(
        'requestPermission',
      );
      final granted = result == 'granted';
      isPermissionGranted.value = granted;
      if (granted) {
        errorMessage.value = '';
      } else {
        errorMessage.value =
            'Izin kamera dibutuhkan untuk mendeteksi bahasa isyarat.';
      }
      return granted;
    } catch (e) {
      debugPrint('[CameraFeedService] requestPermission error: $e');
      return false;
    }
  }

  /// Opens native app settings or TTS settings.
  Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openSettings');
    } catch (_) {}
  }

  /// Starts native CameraX and subscribes to MediaPipe landmark events.
  Future<bool> startCamera() async {
    if (isLoading.value) return false;
    isLoading.value = true;
    errorMessage.value = '';
    final gen = ++_generation;

    try {
      // 1. Verify / Request runtime camera permission
      final hasPerm = await requestPermission();
      if (!hasPerm) {
        isLoading.value = false;
        return false;
      }

      // 2. Subscribe to native landmark event channel
      await _eventSubscription?.cancel();
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _onLandmarkEvent,
        onError: _onStreamError,
        cancelOnError: false,
      );

      // 3. Start native CameraX
      final bool? success = await _methodChannel.invokeMethod<bool>(
        'startCamera',
      );

      if (gen != _generation) {
        await _eventSubscription?.cancel();
        return false;
      }

      final active = success == true;
      isCameraActive.value = active;
      isInitialized.value = active;
      isLoading.value = false;

      if (!active) {
        errorMessage.value =
            'Tidak dapat memulai sensor kamera. Pastikan perangkat memiliki kamera.';
      }

      return active;
    } catch (e) {
      debugPrint('[CameraFeedService] startCamera error: $e');
      isLoading.value = false;
      isCameraActive.value = false;
      isInitialized.value = false;
      errorMessage.value =
          'Sensor kamera fisik tidak aktif. Mode simulator siap digunakan.';
      return false;
    }
  }

  /// Stops native CameraX and cancels landmark subscription.
  Future<void> stopCamera() async {
    _generation++;
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _methodChannel.invokeMethod<bool>('stopCamera');
    } catch (_) {}
    isCameraActive.value = false;
    isInitialized.value = false;
  }

  /// Switches native CameraX between front and back lens.
  Future<void> switchCamera() async {
    try {
      final String? result = await _methodChannel.invokeMethod<String>(
        'switchCamera',
      );
      isFrontCamera.value = result == 'front';
    } catch (e) {
      isFrontCamera.value = !isFrontCamera.value;
      debugPrint('[CameraFeedService] switchCamera error: $e');
    }
  }

  /// Sets lens facing explicitly ('front' or 'back').
  Future<void> setLensFacing(bool front) async {
    isFrontCamera.value = front;
    try {
      await _methodChannel.invokeMethod<bool>('setLensFacing', {
        'facing': front ? 'front' : 'back',
      });
    } catch (_) {}
  }

  int _lastStatUpdateMs = 0;

  void _onLandmarkEvent(dynamic event) {
    if (event is! Map) return;
    try {
      final frame = LandmarkFrame.fromEvent(event);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastStatUpdateMs >= 500) {
        _lastStatUpdateMs = now;
        receivedFramesCount.value++;
      }
      onFrame?.call(frame);
    } catch (e) {
      debugPrint('[CameraFeedService] Frame parse error: $e');
    }
  }

  void _onStreamError(dynamic error) {
    debugPrint('[CameraFeedService] Stream error: $error');
  }

  @override
  void onClose() {
    stopCamera();
    super.onClose();
  }
}
