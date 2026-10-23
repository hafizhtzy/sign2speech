import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
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

  group('CafeCashierController - Mode Eja Nama Cup 1500ms (Fitur 2)', () {
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

  group('CafeCashierController - Waiting Sign Challenge (Fitur 8)', () {
    test('updates challenge progress and completes at 1.0', () async {
      controller.startWaitingChallenge(signWord: 'TERIMA KASIH');
      expect(controller.challengeProgress.value, 0.0);
      expect(controller.isChallengeCompleted.value, isFalse);

      await controller.updateChallengeProgress(0.5);
      expect(controller.challengeProgress.value, 0.5);
      expect(controller.isChallengeCompleted.value, isFalse);

      await controller.updateChallengeProgress(1.0);
      expect(controller.isChallengeCompleted.value, isTrue);
      expect(
        mockTts.spokenTexts.any((t) => t.contains('Luar biasa')),
        isTrue,
      );
    });
  });
}
