import 'package:get/get.dart';

import '../models/sign_capture_quality.dart';
import '../services/bisindo_classifier_service.dart';

class SignLanguageController extends GetxController {
  final Rx<SignLanguageModelType> activeModel =
      SignLanguageModelType.bisindo.obs;
  final RxDouble holdProgress = 0.0.obs;
  final RxBool isCameraActive = true.obs;
  final RxBool isFrontCamera = true.obs;
  final Rx<SignCaptureQuality> captureQuality = const SignCaptureQuality().obs;
  final RxString statusMessage = 'Kamera siap'.obs;

  void toggleModel() {
    if (activeModel.value == SignLanguageModelType.bisindo) {
      activeModel.value = SignLanguageModelType.sibi;
    } else {
      activeModel.value = SignLanguageModelType.bisindo;
    }
  }

  void setModel(SignLanguageModelType model) {
    activeModel.value = model;
  }

  void toggleCameraActive() {
    isCameraActive.value = !isCameraActive.value;
    if (!isCameraActive.value) {
      statusMessage.value = 'Kamera dijeda';
      holdProgress.value = 0.0;
    } else {
      statusMessage.value = 'Kamera siap';
    }
  }

  void flipCamera() {
    isFrontCamera.value = !isFrontCamera.value;
  }

  void updateHoldProgress(double progress) {
    holdProgress.value = progress.clamp(0.0, 1.0);
  }

  void updateQuality(SignCaptureQuality quality) {
    captureQuality.value = quality;
    statusMessage.value = quality.userFeedback;
  }
}
