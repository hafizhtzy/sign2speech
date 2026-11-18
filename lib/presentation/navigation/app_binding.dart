import '../../features/sign_language/models/sign_language_catalog.dart';

import 'package:get/get.dart';

import '../../core/auth/controllers/auth_controller.dart';
import '../../core/auth/services/supabase_auth_service.dart';
import '../../features/cafe_pos/data/datasources/cafe_menu_storage_service.dart';
import '../../features/cafe_pos/data/datasources/supabase_cafe_pos_service.dart';
import '../../features/cafe_pos/data/datasources/supabase_counter_session_service.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/services/history_store.dart';
import '../../features/history/services/supabase_history_service.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/settings/services/supabase_settings_service.dart';
import '../../features/sign_language/controllers/bisindo_recognition_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/services/bisindo_classifier_service.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/supabase_transcript_service.dart';
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
    // 0. Core Three-Role Auth Service & Controller (Addendum V3)
    final supabaseAuthService = SupabaseAuthService();
    Get.put<SupabaseAuthService>(supabaseAuthService, permanent: true);
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authService: supabaseAuthService),
        permanent: true,
      );
    }

    // 1. Core Services & Stores
    final config = SignLanguageConfig();
    final cacheService = SignLanguageCacheService();
    final assetRegistry = SignLanguageAssetRegistry();
    final ttsService = BisindoTtsService();
    final transcriptStore = SignTranscriptStore();
    final historyStore = HistoryStore();
    final speechService = SpeechService();

    final supabaseHistoryService = SupabaseHistoryService();
    final supabaseSettingsService = SupabaseSettingsService();
    final supabaseCafePosService = SupabaseCafePosService();
    final supabaseTranscriptService = SupabaseTranscriptService();

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
    Get.put<SupabaseHistoryService>(supabaseHistoryService, permanent: true);
    Get.put<SupabaseSettingsService>(supabaseSettingsService, permanent: true);
    Get.put<SupabaseCafePosService>(supabaseCafePosService, permanent: true);
    Get.put<SupabaseTranscriptService>(supabaseTranscriptService, permanent: true);
    Get.lazyPut<SupabaseCounterSessionService>(
      () => SupabaseCounterSessionService(),
      fenix: true,
    );
    Get.lazyPut<CafeMenuStorageService>(
      () => CafeMenuStorageService(),
      fenix: true,
    );
    Get.put<SpeechService>(speechService, permanent: true);

    // 2. Machine Learning Classifier Service
    final classifier = BisindoClassifierService();
    Get.put<BisindoClassifierService>(classifier, permanent: true);

    // 3. Camera Service
    final cameraFeedService = CameraFeedService();
    Get.put<CameraFeedService>(cameraFeedService, permanent: true);

    // 4. Controllers
    Get.put<SettingsController>(
      SettingsController(supabaseSettingsService: supabaseSettingsService),
      permanent: true,
    );
    Get.put<HistoryController>(
      HistoryController(
        historyStore: historyStore,
        supabaseHistoryService: supabaseHistoryService,
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
