import 'package:get/get.dart';

import '../controllers/text_to_sign_controller.dart';
import '../models/sign_language_catalog.dart';
import '../services/sign_language_repository.dart';
import '../../translator/services/speech_service.dart';

class TextToSignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeechService>(() => SpeechService());
    Get.lazyPut<SignLanguageCatalog>(
      () => SignLanguageCatalog.defaultCatalog(),
    );
    Get.lazyPut<SignLanguageRepository>(
      () => SignLanguageRepository(catalog: Get.find<SignLanguageCatalog>()),
    );
    Get.lazyPut<TextToSignController>(
      () => TextToSignController(
        speechService: Get.find<SpeechService>(),
        repository: Get.find<SignLanguageRepository>(),
      ),
    );
  }
}
