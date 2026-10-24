import '../../features/sign_language/models/sign_language_catalog.dart';

import 'package:get/get.dart';

import '../../features/cafe_pos/data/datasources/firestore_cafe_pos_service.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/services/history_store.dart';
import '../../features/history/services/firestore_history_service.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/settings/services/firestore_settings_service.dart';
import '../../features/sign_language/controllers/bisindo_recognition_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/services/bisindo_classifier_service.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/firestore_transcript_service.dart';
import '../../features/sign_language/services/sign_language_asset_registry.dart';
import '../../features/sign_language/services/sign_language_cache_service.dart';
import '../../features/sign_language/services/camera_feed_service.dart';
import '../../features/sign_language/services/sign_language_config.dart';
import '../../features/sign_language/services/sign_language_repository.dart';
import '../../features/sign_language/services/sign_transcript_store.dart';
import '../../features/sign_language/services/sign_translation_service.dart';
import '../../core/localization/app_translations.dart';
import '../../features/translator/services/speech_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    AppTranslations.ensureLoaded();
    // 1. Core Services & Stores
    final config = SignLanguageConfig();
    final cacheService = SignLanguageCacheService();
    final assetRegistry = SignLanguageAssetRegistry();
    final ttsService = BisindoTtsService();
    final transcriptStore = SignTranscriptStore();
    final historyStore = HistoryStore();
    final speechService = SpeechService();

    final firestoreHistoryService = FirestoreHistoryService();
    final firestoreSettingsService = FirestoreSettingsService();
    final firestoreCafePosService = FirestoreCafePosService();
    final firestoreTranscriptService = FirestoreTranscriptService();

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
    Get.put<FirestoreHistoryService>(firestoreHistoryService, permanent: true);
    Get.put<FirestoreSettingsService>(firestoreSettingsService, permanent: true);
    Get.put<FirestoreCafePosService>(firestoreCafePosService, permanent: true);
    Get.put<FirestoreTranscriptService>(firestoreTranscriptService, permanent: true);
    Get.put<SpeechService>(speechService, permanent: true);

    // 2. Machine Learning Classifier Service
    final classifier = BisindoClassifierService();
    Get.put<BisindoClassifierService>(classifier, permanent: true);

    // 3. Camera Service
    final cameraFeedService = CameraFeedService();
    Get.put<CameraFeedService>(cameraFeedService, permanent: true);

    // 4. Controllers
    Get.put<SettingsController>(
      SettingsController(firestoreSettingsService: firestoreSettingsService),
      permanent: true,
    );
    Get.put<HistoryController>(
      HistoryController(
        historyStore: historyStore,
        firestoreHistoryService: firestoreHistoryService,
      ),
      permanent: true,
    );
    Get.put<SignLanguageController>(
      SignLanguageController(
        classifierService: classifier,
        cameraFeedService: cameraFeedService,
      ),
      permanent: true,
    );

    final translationService = SignTranslationService();
    Get.put<SignTranslationService>(translationService, permanent: true);

    Get.put<BisindoRecognitionController>(
      BisindoRecognitionController(
        ttsService: ttsService,
        transcriptStore: transcriptStore,
        translationService: translationService,
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
