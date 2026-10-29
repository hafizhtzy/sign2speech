import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/coffee_recommender_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/order_slot_parser_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/queue_pager_service.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_mini_camera_viewport.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cashier_order_deck_card.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cashier_quick_deck.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_asset_registry.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_cache_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_repository.dart';
import 'package:speech2sign/features/translator/services/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CafeCashierController cashierController;
  late TextToSignController textToSignController;
  late SignLanguageRepository repository;

  setUp(() async {
    Get.testMode = true;
    AppTranslations.ensureLoaded();

    final assetRegistry = SignLanguageAssetRegistry(
      preloadedAssets: {
        ...SignLanguageAssetRegistry.defaultOfflineAssets,
        'assets/sign_language/offline/bisindo/kalimat/Susu.mp4',
        'assets/sign_language/offline/bisindo/kalimat/Dingin.mp4',
        'assets/sign_language/offline/bisindo/kalimat/Saya.mp4',
        'assets/sign_language/offline/bisindo/kalimat/Pesan.mp4',
        'assets/sign_language/offline/bisindo/kalimat/Pisang_Goreng.mp4',
      },
    );

    final testCacheDir = Directory.systemTemp.createTempSync('cashier_deck_test_cache_');
    final cacheService = SignLanguageCacheService(cacheDir: testCacheDir);

    repository = SignLanguageRepository(
      catalog: SignLanguageCatalog.defaultCatalog(),
      assetRegistry: assetRegistry,
      cacheService: cacheService,
    );

    textToSignController = TextToSignController(
      repository: repository,
      useInternalPlayer: false,
    );
    await textToSignController.loadAvailableVideos();
    Get.put<TextToSignController>(textToSignController);

    final cameraFeedService = CameraFeedService();
    Get.put<CameraFeedService>(cameraFeedService);

    cashierController = CafeCashierController(
      orderSlotParserService: OrderSlotParserService(),
      coffeeRecommenderService: const CoffeeRecommenderService(),
      queuePagerService: QueuePagerService(ttsService: BisindoTtsService()),
      ttsService: BisindoTtsService(),
      speechService: SpeechService(),
      cameraFeedService: cameraFeedService,
      textToSignController: textToSignController,
    );
    Get.put<CafeCashierController>(cashierController);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'),
      fallbackLocale: const Locale('id', 'ID'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CashierOrderDeckCard(
            controller: cashierController,
          ),
        ),
      ),
    );
  }

  group('CashierOrderDeckCard 3-Tab Architecture & Functionality Tests', () {
    testWidgets('renders 3 tabs with exact order: Bahasa Isyarat, 1-Tap, Suara (Mic)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check titles & card elements
      expect(find.text(AppStrings.cafeCashierDeckTitle.tr), findsOneWidget);
      expect(find.text(AppStrings.cafeCashierDeckSubtitle.tr), findsOneWidget);

      // Verify the 3 tabs are present in order
      final signTab = find.text(AppStrings.cafeCashierTabSign.tr);
      final quickTab = find.text(AppStrings.cafeCashierTabQuick.tr);
      final micTab = find.text(AppStrings.cafeCashierTabMic.tr);

      expect(signTab, findsOneWidget);
      expect(quickTab, findsOneWidget);
      expect(micTab, findsOneWidget);

      // Verify tab order visually from left to right (X coordinate)
      final signOffset = tester.getTopLeft(signTab);
      final quickOffset = tester.getTopLeft(quickTab);
      final micOffset = tester.getTopLeft(micTab);

      expect(signOffset.dx, lessThan(quickOffset.dx));
      expect(quickOffset.dx, lessThan(micOffset.dx));
    });

    testWidgets('default tab is Tab 1: Bahasa Isyarat with camera closed by default and toggle open/close', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Camera should be CLOSED by default
      expect(find.byKey(const ValueKey('closed_camera_placeholder')), findsOneWidget);
      expect(find.text(AppStrings.cafeCashierCameraClosedTitle.tr), findsOneWidget);
      expect(find.byType(CafeMiniCameraViewport), findsNothing);

      // Quick sign simulation chips should be visible even when camera is closed
      expect(find.text(AppStrings.cafeCustomerQuickSignChips.tr), findsOneWidget);
      expect(find.text('PISANG GORENG'), findsOneWidget);
      expect(find.text('KOPI SUSU'), findsOneWidget);

      // Action buttons for sign deletion and reset should be visible
      expect(find.text(AppStrings.cafeCustomerDeleteLastWord.tr), findsOneWidget);
      expect(find.text(AppStrings.cafeCustomerClearSentence.tr), findsOneWidget);

      // Open camera by tapping Buka Kamera Isyarat
      await tester.tap(find.text(AppStrings.cafeOpenLiveCamera.tr).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Camera is now active
      expect(find.byType(CafeMiniCameraViewport), findsOneWidget);
      expect(find.text(AppStrings.cafeCashierCameraActiveTitle.tr), findsOneWidget);

      // Close camera by tapping Tutup Kamera Isyarat button
      await tester.tap(find.text(AppStrings.cafeCloseLiveCamera.tr));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Camera is closed again
      expect(find.byKey(const ValueKey('closed_camera_placeholder')), findsOneWidget);
      expect(find.byType(CafeMiniCameraViewport), findsNothing);
    });

    testWidgets('tapping quick sign chip in Tab 1 updates live order and transcript', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap KOPI SUSU chip
      await tester.tap(find.text('KOPI SUSU'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.liveOrderWords.contains('KOPI SUSU'), isTrue);
      expect(cashierController.liveTranscript.value, contains('KOPI SUSU'));

      // Tap DINGIN chip
      await tester.tap(find.text('DINGIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.liveTranscript.value, contains('DINGIN'));
    });

    testWidgets('switching to Tab 2: 1-Tap displays CashierQuickDeck items and handles execution', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Tab 2: 1-Tap
      await tester.tap(find.text(AppStrings.cafeCashierTabQuick.tr));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify CashierQuickDeck is rendered
      expect(find.byType(CashierQuickDeck), findsOneWidget);
      expect(find.text(AppStrings.quickDeck1.tr), findsOneWidget);
      expect(find.text(AppStrings.quickDeck2.tr), findsOneWidget);
      expect(find.text(AppStrings.quickDeck5.tr), findsOneWidget);

      // Tap item 1 (Dine-in / Takeaway)
      await tester.tap(find.text(AppStrings.quickDeck1.tr));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.activeQuickDeckIndex.value, equals(0));
    });

    testWidgets('switching to Tab 3: Suara (Mic) displays mic hero and toggles listening', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Tab 3: Suara (Mic)
      await tester.tap(find.text(AppStrings.cafeCashierTabMic.tr));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Mic hero is visible
      expect(find.text(AppStrings.cafeCashierMicTap.tr), findsOneWidget);

      // Tap Mic button to toggle listening
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.isListening.value, isTrue);
    });

    testWidgets('quick preferences chips append to text field and submitting commits to ticket', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap preference chip "+ Pisang Goreng"
      final chipFinder = find.text('+ Pisang Goreng');
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.liveTranscript.value, contains('Pisang Goreng'));

      // Tap "Proses Pesanan ke Nota"
      final submitFinder = find.text(AppStrings.cafeCashierSubmitOrder.tr);
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify order processing
      expect(cashierController.liveTranscript.value, isNotEmpty);

      // Drain snackbar animation to avoid pending timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
