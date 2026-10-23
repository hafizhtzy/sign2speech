import 'package:get/get.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_cache_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_repository.dart';

import 'package:speech2sign/features/translator/services/speech_service.dart';

import '../../../core/localization/app_translations.dart';
import '../controllers/cafe_cashier_controller.dart';
import '../data/datasources/cafe_pos_local_data_source.dart';
import '../domain/services/coffee_recommender_service.dart';
import '../domain/services/order_slot_parser_service.dart';
import '../domain/services/queue_pager_service.dart';

class CafePosBinding extends Bindings {
  @override
  void dependencies() {
    AppTranslations.ensureLoaded();
    if (!Get.isRegistered<BisindoTtsService>()) {
      Get.lazyPut<BisindoTtsService>(() => BisindoTtsService());
    }

    if (!Get.isRegistered<SpeechService>()) {
      Get.lazyPut<SpeechService>(() => SpeechService());
    }

    if (!Get.isRegistered<CameraFeedService>()) {
      Get.put<CameraFeedService>(CameraFeedService(), permanent: true);
    }

    if (!Get.isRegistered<SignLanguageCacheService>()) {
      Get.lazyPut<SignLanguageCacheService>(() => SignLanguageCacheService());
    }

    if (!Get.isRegistered<SignLanguageRepository>()) {
      Get.lazyPut<SignLanguageRepository>(
        () => SignLanguageRepository.instance,
      );
    }

    if (!Get.isRegistered<TextToSignController>()) {
      Get.lazyPut<TextToSignController>(
        () => TextToSignController(
          repository: Get.find<SignLanguageRepository>(),
        ),
      );
    }

    if (!Get.isRegistered<CafePosLocalDataSource>()) {
      Get.lazyPut<CafePosLocalDataSource>(
        () => CafePosLocalDataSource(),
        fenix: true,
      );
    }

    Get.lazyPut<OrderSlotParserService>(
      () => OrderSlotParserService(),
      fenix: true,
    );
    Get.lazyPut<CoffeeRecommenderService>(
      () => const CoffeeRecommenderService(),
      fenix: true,
    );
    Get.lazyPut<QueuePagerService>(
      () => QueuePagerService(ttsService: Get.find<BisindoTtsService>()),
      fenix: true,
    );

    Get.lazyPut<CafeCashierController>(
      () => CafeCashierController(
        orderSlotParserService: Get.find<OrderSlotParserService>(),
        coffeeRecommenderService: Get.find<CoffeeRecommenderService>(),
        queuePagerService: Get.find<QueuePagerService>(),
        ttsService: Get.find<BisindoTtsService>(),
        speechService: Get.find<SpeechService>(),
        localDataSource: Get.find<CafePosLocalDataSource>(),
      ),
      fenix: true,
    );
  }
}

