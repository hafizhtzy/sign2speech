import '../../features/sign_language/models/sign_language_catalog.dart';

import 'package:get/get.dart';

import '../../features/history/controllers/history_controller.dart';
import '../../features/history/services/history_store.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/bisindo_recognition_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/services/bisindo_classifier_service.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/sign_language_asset_registry.dart';
import '../../features/sign_language/services/sign_language_cache_service.dart';
import '../../features/sign_language/services/camera_feed_service.dart';
import '../../features/sign_language/services/sign_language_config.dart';
import '../../features/sign_language/services/sign_language_repository.dart';
import '../../features/sign_language/services/sign_transcript_store.dart';
import '../../features/translator/services/speech_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Core Services & Stores
    final config = SignLanguageConfig();
    final cacheService = SignLanguageCacheService();
    final assetRegistry = SignLanguageAssetRegistry();
    final ttsService = BisindoTtsService();
    final transcriptStore = SignTranscriptStore();
    final historyStore = HistoryStore();
    final speechService = SpeechService();

    final catalog = SignLanguageCatalog.defaultCatalog();
    final repository = SignLanguageRepository(
      catalog: catalog,
      config: config,
      cacheService: cacheService,
      assetRegistry: assetRegistry,
    );

    Get.put<SignLanguageConfig>(config, permanent: true);
    Get.put<SignLanguageCacheService>(cacheService, permanent: true);
    Get.put<SignLanguageAssetRegistry>(assetRegistry, permanent: true);
    Get.put<SignLanguageRepository>(repository, permanent: true);
    Get.put<BisindoTtsService>(ttsService, permanent: true);
    Get.put<SignTranscriptStore>(transcriptStore, permanent: true);
    Get.put<HistoryStore>(historyStore, permanent: true);
    Get.put<SpeechService>(speechService, permanent: true);

    // 2. Machine Learning Classifier Service
    final classifier = BisindoClassifierService();
    Get.put<BisindoClassifierService>(classifier, permanent: true);

    // 3. Camera Service
    final cameraFeedService = CameraFeedService();
    Get.put<CameraFeedService>(cameraFeedService, permanent: true);

    // 4. Controllers
    Get.put<SettingsController>(SettingsController(), permanent: true);
    Get.put<HistoryController>(
      HistoryController(historyStore: historyStore),
      permanent: true,
    );
    Get.put<SignLanguageController>(
      SignLanguageController(
        classifierService: classifier,
        cameraFeedService: cameraFeedService,
      ),
      permanent: true,
    );

    Get.put<BisindoRecognitionController>(
      BisindoRecognitionController(
        ttsService: ttsService,
        transcriptStore: transcriptStore,
      ),
      permanent: true,
    );

    Get.put<TextToSignController>(
      TextToSignController(
        speechService: speechService,
        repository: repository,
      ),
      permanent: true,
    );
  }
}
