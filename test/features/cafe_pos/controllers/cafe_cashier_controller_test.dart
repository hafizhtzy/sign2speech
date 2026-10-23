import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/cafe_pos_local_data_source.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_order_ticket.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/dietary_alert_tag.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/coffee_recommender_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/order_slot_parser_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/queue_pager_service.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';

class MockTtsService extends BisindoTtsService {
  final List<String> spokenTexts = [];

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    spokenTexts.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CafeCashierController controller;
  late MockTtsService mockTts;

  setUp(() {
    mockTts = MockTtsService();
    controller = CafeCashierController(
      orderSlotParserService: OrderSlotParserService(),
      coffeeRecommenderService: const CoffeeRecommenderService(),
      queuePagerService: QueuePagerService(ttsService: mockTts),
      ttsService: mockTts,
    );
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  group('CafeCashierController - Auto Order Slot (Fitur 1 & 6)', () {
    test('parses transcript and updates activeParsedSlot and sommelier', () {
      controller.onTranscriptReceived(
        'mau es karamel latte large less sweet extra shot alergi kacang',
      );

      final slot = controller.activeParsedSlot.value;
      expect(slot, isNotNull);
      expect(slot!.drinkId, 'iced_caramel_latte');
      expect(slot.cupSize, OrderCupSize.large);
      expect(slot.dietaryAlerts, isNotEmpty);

      final rec = controller.activeRecommendation.value;
      expect(rec, isNotNull);
      expect(rec!.item.id, 'iced_caramel_latte');
    });

    test('confirmParsedSlotToTicket moves slot into active ticket items', () {
      controller.onTranscriptReceived('pesan kopi susu aren dingin');
      expect(controller.activeParsedSlot.value, isNotNull);

      controller.confirmParsedSlotToTicket();

      expect(controller.activeParsedSlot.value, isNull);
      expect(controller.currentTicket.value.items.length, 1);
      expect(
        controller.currentTicket.value.items.first.drinkId,
        'kopi_susu_aren',
      );
      expect(controller.currentTicket.value.subtotal, greaterThan(0));
      expect(controller.currentTicket.value.grandTotal, greaterThan(0));
    });
  });

  group('CafeCashierController - Mode Eja Nama Cup (Fitur 2)', () {
    test('buffers fingerspelling letters and commits on finish', () async {
      controller.startCustomerNameSpelling();
      expect(controller.isSpellingCustomerName.value, isTrue);

      controller.addSpellingLetter('r');
      controller.addSpellingLetter('i');
      controller.addSpellingLetter('a');
      controller.addSpellingLetter('n');

      expect(controller.customerCupNameBuffer.value, 'RIAN');

      await controller.finishCustomerNameSpelling();

      expect(controller.currentTicket.value.customerName, 'RIAN');
      expect(controller.isSpellingCustomerName.value, isFalse);
      expect(mockTts.spokenTexts, contains('Atas nama RIAN'));
    });

    test('does NOT automatically timeout after 1500ms; stays active until user finishes', () async {
      controller.startCustomerNameSpelling();
      expect(controller.isSpellingCustomerName.value, isTrue);

      controller.addSpellingLetter('b');
      controller.addSpellingLetter('u');
      controller.addSpellingLetter('d');
      controller.addSpellingLetter('i');

      // Even after 1600ms, spelling remains active without premature termination
      await Future.delayed(const Duration(milliseconds: 1600));

      expect(controller.isSpellingCustomerName.value, isTrue);
      expect(controller.customerCupNameBuffer.value, 'BUDI');

      await controller.finishCustomerNameSpelling();
      expect(controller.isSpellingCustomerName.value, isFalse);
      expect(controller.currentTicket.value.customerName, 'BUDI');
    });
  });

  group('CafeCashierController - 1-Tap Cashier Quick Deck (Fitur 5)', () {
    test('executes action 3 and automatically opens spelling mode', () async {
      await controller.executeQuickDeck(3);

      expect(controller.activeQuickDeckIndex.value, 3);
      expect(controller.isSpellingCustomerName.value, isTrue);
      expect(
        mockTts.spokenTexts,
        contains('Untuk atas nama siapa di cup-nya?'),
      );
    });

    test('executes action 5 and marks order preparing', () async {
      await controller.executeQuickDeck(5);

      expect(controller.activeQuickDeckIndex.value, 5);
      expect(controller.currentTicket.value.status, OrderStatus.preparing);
      expect(
        mockTts.spokenTexts,
        contains('Terima kasih, mohon tunggu sebentar di area pickup.'),
      );
    });
  });

  group('CafeCashierController - Dual-Mode Queue Pager (Fitur 4)', () {
    test('calls hearing customer via FIFO TTS', () async {
      controller.currentTicket.value = controller.currentTicket.value.copyWith(
        queueNumber: 'A-108',
        customerName: 'Rian',
      );

      await controller.callHearingCustomer();

      expect(controller.lastQueueCallEvent.value, isNotNull);
      expect(controller.lastQueueCallEvent.value!.isHearingTarget, isTrue);
      expect(
        mockTts.spokenTexts.any((t) => t.contains('A seratus delapan')),
        isTrue,
      );
    });

    test('calls deaf customer and activates visual flash state', () async {
      controller.currentTicket.value = controller.currentTicket.value.copyWith(
        queueNumber: 'A-108',
        customerName: 'Rian',
      );

      await controller.callDeafCustomer();

      expect(controller.isDeafCallActive.value, isTrue);
      expect(controller.lastQueueCallEvent.value!.isHearingTarget, isFalse);
      expect(
        controller.lastQueueCallEvent.value!.signVideoKeyword,
        'PESANAN SIAP DIAMBIL',
      );
    });
  });

  group('CafeCashierController - Payment & Bill (Fitur 7)', () {
    test('calculates correct cash change', () {
      final slot = const ParsedCafeOrderSlot(
        drinkId: 'cappuccino',
        drinkLabelKey: 'cappuccino',
        drinkNameId: 'Cappuccino',
        drinkNameEn: 'Cappuccino',
        basePrice: 30000,
        cupSize: OrderCupSize.medium,
        milkType: OrderMilkType.freshDairy,
      );
      controller.addItemToTicket(slot);

      // subtotal = 30000, tax 10% = 3000, grand total = 33000
      expect(controller.currentTicket.value.grandTotal, 33000);

      controller.setPaymentMethod(OrderPaymentMethod.cash);
      controller.setAmountPaid(50000);

      expect(controller.currentTicket.value.changeAmount, 17000);
    });
  });

  group('CafeCashierController - Dynamic 8 Killer Features Enhancements', () {
    test('dynamic fingerspelling supports backspace, space, and clear', () {
      controller.startCustomerNameSpelling();
      controller.addSpellingLetter('f');
      controller.addSpellingLetter('a');
      controller.addSpellingLetter('d');
      controller.addSpellingLetter('l');
      controller.addSpellingLetter('i');
      expect(controller.customerCupNameBuffer.value, 'FADLI');

      controller.deleteSpellingLetter();
      expect(controller.customerCupNameBuffer.value, 'FADL');

      controller.addSpellingLetter('i');
      controller.addSpellingSpace();
      controller.addSpellingLetter('a');
      expect(controller.customerCupNameBuffer.value, 'FADLI A');

      controller.clearSpellingBuffer();
      expect(controller.customerCupNameBuffer.value, '');
    });

    test('2-way Quick Deck generates replies and records customer selection', () async {
      await controller.executeQuickDeck(0);
      expect(controller.activeCustomerQuickReplies, contains('Dine-In (Minum Sini)'));
      expect(controller.activeCustomerQuickReplies, contains('Takeaway (Bawa Pulang)'));

      controller.onCustomerSelectReply('Dine-In (Minum Sini)');
      expect(controller.lastCustomerReply.value, 'Dine-In (Minum Sini)');
      expect(controller.currentTicket.value.customerNotes, 'Dine-In (Minum Sini)');
    });

    test('addRecommendedItemToTicket adds coffee item to ticket dynamically', () {
      final item = CoffeeMenuItem.standardCatalog[0];
      controller.addRecommendedItemToTicket(item);

      expect(controller.currentTicket.value.items.length, 1);
      expect(controller.currentTicket.value.items.first.drinkId, item.id);
      expect(mockTts.spokenTexts.any((t) => t.contains(item.nameId)), isTrue);
    });

    test('substituteMilkInTicket replaces milk and clears lactose warnings', () {
      const slot = ParsedCafeOrderSlot(
        drinkId: 'kopi_susu_aren',
        drinkLabelKey: 'kopi_susu_aren',
        drinkNameId: 'Kopi Susu Aren',
        drinkNameEn: 'Palm Sugar Coffee',
        milkType: OrderMilkType.freshDairy,
        dietaryAlerts: [
          DietaryAlertTag(
            type: DietaryAlertType.lactoseIntolerant,
            severity: DietaryAlertSeverity.warning,
            labelKey: 'alert_lactose',
            defaultMessageId: 'Mengandung laktosa',
            defaultMessageEn: 'Contains lactose',
            detectedKeyword: 'laktosa',
          ),
        ],
      );
      controller.addItemToTicket(slot);
      expect(controller.currentTicket.value.items.first.dietaryAlerts, isNotEmpty);

      controller.substituteMilkInTicket(0, OrderMilkType.oatMilk);

      expect(controller.currentTicket.value.items.first.milkType, OrderMilkType.oatMilk);
      expect(controller.currentTicket.value.items.first.dietaryAlerts, isEmpty);
      expect(mockTts.spokenTexts.any((t) => t.contains('Susu Oat')), isTrue);
    });

    test('processQrisPayment verifies and marks ticket completed', () async {
      controller.addItemToTicket(const ParsedCafeOrderSlot(
        drinkId: 'americano',
        drinkLabelKey: 'americano',
        drinkNameId: 'Americano',
        drinkNameEn: 'Americano',
        basePrice: 25000,
      ));
      controller.setPaymentMethod(OrderPaymentMethod.qris);

      await controller.processQrisPayment();

      expect(controller.isOrderCompleted.value, isTrue);
      expect(controller.currentTicket.value.status, OrderStatus.completed);
      expect(controller.currentTicket.value.amountPaid, controller.currentTicket.value.grandTotal);
      expect(mockTts.spokenTexts.any((t) => t.contains('QRIS')), isTrue);
    });

    test('setExactCash and completeCashPayment marks ticket completed', () async {
      controller.addItemToTicket(const ParsedCafeOrderSlot(
        drinkId: 'americano',
        drinkLabelKey: 'americano',
        drinkNameId: 'Americano',
        drinkNameEn: 'Americano',
        basePrice: 25000,
      ));
      controller.setPaymentMethod(OrderPaymentMethod.cash);
      controller.setExactCash();

      expect(controller.currentTicket.value.amountPaid, controller.currentTicket.value.grandTotal);

      await controller.completeCashPayment();
      expect(controller.isOrderCompleted.value, isTrue);
      expect(controller.currentTicket.value.status, OrderStatus.completed);
    });

    test('updates challenge progress and completes at 1.0', () async {
      controller.startWaitingChallenge(signWord: 'TERIMA KASIH');
      expect(controller.challengeProgress.value, 0.0);
      expect(controller.isChallengeCompleted.value, isFalse);

      await controller.updateChallengeProgress(0.5);
      expect(controller.challengeProgress.value, 0.5);
      expect(controller.isChallengeCompleted.value, isFalse);

      await controller.updateChallengeProgress(1.0);
      expect(controller.isChallengeCompleted.value, isTrue);
      expect(controller.showTrophyDialog.value, isTrue);
      expect(
        mockTts.spokenTexts.any((t) => t.contains('Luar biasa')),
        isTrue,
      );
    });

    test('cycleNextChallengeWord cycles through challenge vocabulary', () {
      controller.startWaitingChallenge(signWord: 'TERIMA KASIH');
      expect(controller.activeChallengeSign.value, 'TERIMA KASIH');

      controller.cycleNextChallengeWord();
      expect(controller.activeChallengeSign.value, 'KOPI');

      controller.cycleNextChallengeWord();
      expect(controller.activeChallengeSign.value, 'SUSU');
    });
  });

  group('CafeCashierController - Local Storage Persistence', () {
    test('restores saved ticket on initialization and auto-persists updates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = CafePosLocalDataSource(prefs: prefs);

      const slot = ParsedCafeOrderSlot(
        drinkId: 'coffee_espresso',
        drinkLabelKey: 'coffee_espresso',
        drinkNameId: 'Espresso',
        drinkNameEn: 'Espresso',
      );

      final initialTicket = CafeOrderTicket(
        orderId: 'ORD-777',
        queueNumber: 'A-777',
        customerName: 'Sarah',
        items: const [slot],
        createdAt: DateTime.now(),
      );
      await localDataSource.saveActiveTicket(initialTicket);

      final mockTtsLocal = MockTtsService();
      final persistedController = CafeCashierController(
        orderSlotParserService: OrderSlotParserService(),
        coffeeRecommenderService: const CoffeeRecommenderService(),
        queuePagerService: QueuePagerService(ttsService: mockTtsLocal),
        ttsService: mockTtsLocal,
        localDataSource: localDataSource,
      );

      persistedController.onInit();
      await persistedController.loadPersistedTicket();

      expect(persistedController.currentTicket.value.orderId, equals('ORD-777'));
      expect(persistedController.currentTicket.value.customerName, equals('Sarah'));
      expect(persistedController.currentTicket.value.items.length, equals(1));

      // Now add another item
      const slot2 = ParsedCafeOrderSlot(
        drinkId: 'coffee_latte',
        drinkLabelKey: 'coffee_latte',
        drinkNameId: 'Latte',
        drinkNameEn: 'Latte',
      );
      persistedController.addItemToTicket(slot2);
      expect(persistedController.currentTicket.value.items.length, equals(2));

      // Verify the update was persisted to local storage
      final storedTicket = await localDataSource.loadActiveTicket();
      expect(storedTicket, isNotNull);
      expect(storedTicket!.items.length, equals(2));

      persistedController.onClose();
    });

    test('onCustomerSelectReply sets feedback and synchronizes activeParsedSlot', () {
      const initialSlot = ParsedCafeOrderSlot(
        drinkId: 'coffee_latte',
        drinkLabelKey: 'coffee_latte',
        drinkNameId: 'Latte',
        drinkNameEn: 'Latte',
        cupSize: OrderCupSize.small,
      );
      controller.activeParsedSlot.value = initialSlot;

      controller.onCustomerSelectReply('Ukuran Large');

      expect(controller.lastCustomerReply.value, equals('Ukuran Large'));
      expect(controller.lastCustomerActionFeedback.value, contains('terkirim ke Barista'));
      expect(controller.activeParsedSlot.value?.cupSize, equals(OrderCupSize.large));

      controller.dismissCustomerReply();
      expect(controller.lastCustomerReply.value, isEmpty);
    });

    test('updateChallengeProgress at 1.0 increments loyalty stamp and persists', () async {
      SharedPreferences.setMockInitialValues({'cafe_pos_loyalty_stamps_count': 2});
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = CafePosLocalDataSource(prefs: prefs);

      final mockTts = MockTtsService();
      final stampController = CafeCashierController(
        orderSlotParserService: OrderSlotParserService(),
        coffeeRecommenderService: const CoffeeRecommenderService(),
        queuePagerService: QueuePagerService(ttsService: mockTts),
        ttsService: mockTts,
        localDataSource: localDataSource,
      );

      await stampController.loadPersistedTicket();
      expect(stampController.loyaltyStampsCount.value, equals(2));

      await stampController.updateChallengeProgress(1.0);

      expect(stampController.isChallengeCompleted.value, isTrue);
      expect(stampController.showTrophyDialog.value, isTrue);
      expect(stampController.loyaltyStampsCount.value, equals(3));

      final persistedCount = await localDataSource.loadLoyaltyStamps();
      expect(persistedCount, equals(3));

      stampController.onClose();
    });
  });
}


