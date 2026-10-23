import 'package:get/get.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_cache_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_repository.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/services/coffee_recommender_service.dart';
import '../domain/services/order_slot_parser_service.dart';
import '../domain/services/queue_pager_service.dart';

class CafePosBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BisindoTtsService>()) {
      Get.lazyPut<BisindoTtsService>(() => BisindoTtsService());
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

    Get.lazyPut<OrderSlotParserService>(() => OrderSlotParserService());
    Get.lazyPut<CoffeeRecommenderService>(() => const CoffeeRecommenderService());
    Get.lazyPut<QueuePagerService>(
      () => QueuePagerService(ttsService: Get.find<BisindoTtsService>()),
    );

    Get.lazyPut<CafeCashierController>(
      () => CafeCashierController(
        orderSlotParserService: Get.find<OrderSlotParserService>(),
        coffeeRecommenderService: Get.find<CoffeeRecommenderService>(),
        queuePagerService: Get.find<QueuePagerService>(),
        ttsService: Get.find<BisindoTtsService>(),
      ),
    );
  }
}
