import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_cache_service.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/coffee_recommender_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/order_slot_parser_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/queue_pager_service.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_cashier_sign_video_card.dart';
import 'package:speech2sign/features/cafe_pos/widgets/customer_voice_order_card.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_asset_registry.dart';
import 'package:speech2sign/features/cafe_pos/screens/cafe_cashier_counter_screen.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_mini_camera_viewport.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
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

    final testCacheDir = Directory.systemTemp.createTempSync('cafe_test_cache_');
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

  group('CustomerVoiceOrderCard Widget Tests', () {
    testWidgets('renders all voice order elements (mic, text field, quick chips, send button)',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check header (clean UI without redundant status pill)
      expect(find.text('Pesan Kopi Lewat Suara'), findsOneWidget);
      expect(find.text('Kasir Siap'), findsNothing);

      // Check microphone button and hints
      expect(find.byIcon(Icons.mic_none_rounded), findsWidgets);
      expect(find.text('Ketuk untuk Bicara'), findsOneWidget);

      // Check editable text field
      expect(find.byType(TextField), findsOneWidget);

      // Check quick chips
      expect(find.text('+ Kopi Susu'), findsOneWidget);
      expect(find.text('+ Oat Milk'), findsOneWidget);
      expect(find.text('+ Dingin'), findsOneWidget);

      // Check send button
      expect(find.text('Kirim Pesanan ke Kasir'), findsOneWidget);
    });

    testWidgets('tapping quick preference chip appends text and updates transcript',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap + Kopi Susu chip
      await tester.tap(find.text('+ Kopi Susu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cashierController.liveTranscript.value, contains('Kopi Susu'));

      // Tap + Oat Milk chip
      await tester.tap(find.text('+ Oat Milk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cashierController.liveTranscript.value, contains('Kopi Susu Oat Milk'));
    });

    testWidgets('editing text field directly updates transcript and triggers sign video search',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter custom text into the field
      await tester.enterText(find.byType(TextField), 'Kopi');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cashierController.liveTranscript.value, equals('Kopi'));
      expect(textToSignController.playlist, isNotEmpty);
      expect(textToSignController.playlist.first.label.toLowerCase(), equals('kopi'));
    });

    testWidgets('tapping Kirim Pesanan ke Kasir commits parsed slot and displays feedback',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter an order
      await tester.enterText(find.byType(TextField), 'Kopi Susu Oat Milk');
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      // Tap Send
      final sendBtn = find.text('Kirim Pesanan ke Kasir');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Order should be committed to ticket items
      expect(cashierController.currentTicket.value.items, isNotEmpty);
      expect(cashierController.currentTicket.value.items.first.drinkNameId,
          contains('Kopi Susu'));

      // Drain snackbar animation to avoid pending timers
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('ordering "saya pesan pisang goreng" syncs all words including compound phrase "Pisang Goreng" to cashier sign video',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.runAsync(() async {
        await tester.enterText(find.byType(TextField), 'saya pesan pisang goreng');
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Verify transcript
      expect(cashierController.liveTranscript.value, equals('saya pesan pisang goreng'));

      // Verify sign playlist contains ALL THREE tokens: Saya, Pesan, and Pisang Goreng
      expect(textToSignController.playlist.length, equals(3));
      expect(textToSignController.playlist[0].label, equals('Saya'));
      expect(textToSignController.playlist[1].label, equals('Pesan'));
      expect(textToSignController.playlist[2].label, equals('Pisang Goreng'));

      // Verify order slot parsed Pisang Goreng
      expect(cashierController.activeParsedSlot.value?.drinkId, equals('pisang_goreng'));
      expect(cashierController.activeParsedSlot.value?.drinkNameId, equals('Pisang Goreng Crispy'));
    });

    testWidgets('switching mode between voice and camera updates card viewport and activates camera',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial state is voice mode
      expect(find.byKey(const ValueKey('customer_voice_mode_hero')), findsOneWidget);
      expect(find.byType(CafeMiniCameraViewport), findsNothing);

      // Switch to camera sign mode
      await tester.tap(find.text('Bahasa Isyarat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify camera mode active
      expect(find.byType(CafeMiniCameraViewport), findsOneWidget);
      expect(find.text('Deteksi Isyarat Pesanan'), findsOneWidget);
      expect(find.text('Hapus Kata Terakhir'), findsOneWidget);
      expect(find.text('Reset Isyarat'), findsOneWidget);
      expect(cashierController.activeCameraFeature.value, equals(CafeCameraActiveFeature.liveOrder));

      // Switch back to voice mode
      await tester.tap(find.text('Suara (Mic)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('customer_voice_mode_hero')), findsOneWidget);
      expect(cashierController.activeCameraFeature.value, equals(CafeCameraActiveFeature.none));
    });

    testWidgets('in camera mode, quick sign chips add sign words, parse order slot, and sync video to cashier',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerVoiceOrderCard(
                controller: cashierController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to camera mode
      await tester.tap(find.text('Bahasa Isyarat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap + SAYA chip
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ActionChip, 'SAYA'), warnIfMissed: false);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      expect(cashierController.liveTranscript.value, equals('SAYA'));
      expect(textToSignController.playlist, isNotEmpty);
      expect(textToSignController.playlist.first.label, equals('Saya'));

      // Tap + PESAN chip
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ActionChip, 'PESAN'), warnIfMissed: false);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      // Tap + PISANG GORENG chip
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ActionChip, 'PISANG GORENG'), warnIfMissed: false);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      expect(cashierController.liveTranscript.value, equals('SAYA PESAN PISANG GORENG'));
      expect(textToSignController.playlist.length, equals(3));
      expect(textToSignController.playlist[2].label, equals('Pisang Goreng'));
      expect(cashierController.activeParsedSlot.value?.drinkId, equals('pisang_goreng'));

      // Test delete last sign word
      await tester.runAsync(() async {
        await tester.tap(find.text('Hapus Kata Terakhir'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      expect(cashierController.liveTranscript.value, equals('SAYA PESAN'));
      expect(textToSignController.playlist.length, equals(2));

      // Test reset isyarat
      await tester.runAsync(() async {
        await tester.tap(find.text('Reset Isyarat'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();

      expect(cashierController.liveTranscript.value, isEmpty);
      expect(textToSignController.playlist, isEmpty);
    });
  });

  group('CafeCashierSignVideoCard Widget Tests', () {
    testWidgets('renders standby state with helper hints and test chips when idle',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CafeCashierSignVideoCard(
                cashierController: cashierController,
                textToSignController: textToSignController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Video Bahasa Isyarat Pesanan'), findsOneWidget);
      expect(find.text('Siap Menampilkan Isyarat'), findsOneWidget);
      expect(find.text('Coba: Kopi'), findsOneWidget);
      expect(find.text('Coba: Minum'), findsOneWidget);
      expect(find.text('Coba: Susu'), findsOneWidget);
    });

    testWidgets('tapping demo test chip immediately triggers sign search and shows video player',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CafeCashierSignVideoCard(
                cashierController: cashierController,
                textToSignController: textToSignController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap demo chip Coba: Kopi
      await tester.tap(find.text('Coba: Kopi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cashierController.liveTranscript.value, equals('Kopi'));
      expect(textToSignController.playlist, isNotEmpty);
      expect(textToSignController.playlist.first.label, equals('Kopi'));

      // Redundant header pills removed; offline badge lives cleanly inside player
      expect(find.text('Offline (Aset)'), findsNothing);
      expect(find.text('Video Offline'), findsOneWidget);
    });

    testWidgets('allows collapsing and expanding the card',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CafeCashierSignVideoCard(
                cashierController: cashierController,
                textToSignController: textToSignController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Siap Menampilkan Isyarat'), findsOneWidget);

      // Tap collapse button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Content hidden
      expect(find.text('Siap Menampilkan Isyarat'), findsNothing);

      // Tap expand button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Content visible again
      expect(find.text('Siap Menampilkan Isyarat'), findsOneWidget);
    });
  });

  group('Real-Time Controller Synchronization Tests', () {
    test('onTranscriptReceived triggers TextToSignController.searchSign in real-time',
        () async {
      expect(textToSignController.playlist, isEmpty);

      cashierController.onTranscriptReceived('kopi susu', triggerSign: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cashierController.liveTranscript.value, equals('kopi susu'));
      expect(textToSignController.playlist, isNotEmpty);
      expect(textToSignController.playlist.first.label.toLowerCase(), equals('kopi'));
    });

    test('onTranscriptReceived triggers searchSign for "saya pesan pisang goreng"',
        () async {
      cashierController.onTranscriptReceived('saya pesan pisang goreng', triggerSign: true);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(textToSignController.playlist.length, equals(3));
      expect(textToSignController.playlist[0].label, equals('Saya'));
      expect(textToSignController.playlist[1].label, equals('Pesan'));
      expect(textToSignController.playlist[2].label, equals('Pisang Goreng'));
    });

    test('switchSignLanguageModel syncs language to textToSignController',
        () async {
      cashierController.switchSignLanguageModel(SignLanguageModel.sibi);
      expect(textToSignController.selectedLanguage.value, equals('sibi'));

      cashierController.switchSignLanguageModel(SignLanguageModel.bisindo);
      expect(textToSignController.selectedLanguage.value, equals('bisindo'));
    });

    test('clearTicket clears sign video playlist to isolate next customer session',
        () async {
      cashierController.onTranscriptReceived('kopi', triggerSign: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(textToSignController.playlist, isNotEmpty);

      cashierController.clearTicket();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(textToSignController.playlist, isEmpty);
    });
  });

  group('AppBar & Cashier Controls Tests', () {
    testWidgets('mobile screen opens CafeCashierControlSheet via more options (⋮) and switches models',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const CafeCashierCounterScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially active model is BISINDO
      expect(cashierController.activeSignModel, equals(SignLanguageModel.bisindo));

      // Verify More Options button exists on AppBar
      final moreBtnFinder = find.byTooltip(AppStrings.cafeMenuMoreTooltip.tr);
      expect(moreBtnFinder, findsOneWidget);

      // Tap More Options button to open CafeCashierControlSheet
      await tester.tap(moreBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify BottomSheet opened with title and model cards
      expect(find.text(AppStrings.cafeControlSheetTitle.tr), findsOneWidget);
      expect(find.text('BISINDO'), findsOneWidget);
      expect(find.text('SIBI'), findsOneWidget);

      // Tap SIBI inside BottomSheet
      await tester.tap(find.text('SIBI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.activeSignModel, equals(SignLanguageModel.sibi));
      expect(textToSignController.selectedLanguage.value, equals('sibi'));

      // Tap BISINDO inside BottomSheet
      await tester.tap(find.text('BISINDO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.activeSignModel, equals(SignLanguageModel.bisindo));
      expect(textToSignController.selectedLanguage.value, equals('bisindo'));

      // Close the BottomSheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Drain snackbar animation to avoid pending timers
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('tablet / large screen displays segmented model toggle directly on AppBar',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const CafeCashierCounterScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Direct AppBar segmented switcher exists on large screen
      expect(find.text('BISINDO'), findsOneWidget);
      expect(find.text('SIBI'), findsOneWidget);

      // Tap SIBI directly on AppBar
      await tester.tap(find.text('SIBI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(cashierController.activeSignModel, equals(SignLanguageModel.sibi));
      expect(textToSignController.selectedLanguage.value, equals('sibi'));

      // Drain snackbar animation
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('Customer Menu Catalog Tests', () {
    testWidgets('tapping menu catalog in customer view opens CafeMenuCatalogSheet and selects coffee',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const CafeCashierCounterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter ordering stage
      await tester.tap(find.text('Mulai Terima Pesanan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Customer View
      cashierController.toggleDualView();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ensure menu catalog button in CustomerVoiceOrderCard exists
      expect(find.text(AppStrings.cafeModeMenuCatalog.tr), findsWidgets);

      // Tap Katalog Menu button inside CustomerVoiceOrderCard
      await tester.tap(find.text(AppStrings.cafeModeMenuCatalog.tr).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // CafeMenuCatalogSheet is displayed with title & category tabs
      expect(find.text(AppStrings.cafeCatalogTitle.tr), findsOneWidget);
      expect(find.text(AppStrings.cafeCategoryAll.tr), findsOneWidget);

      // Tap quick add "+" on the first item in the catalog
      final quickAddFinder = find.byIcon(Icons.add_rounded);
      expect(quickAddFinder, findsWidgets);
      await tester.ensureVisible(quickAddFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() async {
        await tester.tap(quickAddFinder.first);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify item was added to the order ticket
      expect(cashierController.currentTicket.value.items.isNotEmpty, isTrue);

      // Verify sign language search was triggered for the cashier
      expect(textToSignController.playlist.isNotEmpty, isTrue);
    });
  });
}
