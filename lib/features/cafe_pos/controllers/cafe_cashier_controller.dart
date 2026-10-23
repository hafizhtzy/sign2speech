import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';

import '../domain/models/cafe_order_ticket.dart';
import '../domain/models/coffee_recommendation_result.dart';
import '../domain/models/order_enums.dart';
import '../domain/models/parsed_cafe_order_slot.dart';
import '../domain/services/coffee_recommender_service.dart';
import '../domain/services/order_slot_parser_service.dart';
import '../domain/services/queue_pager_service.dart';

class CafeCashierController extends GetxController {
  final OrderSlotParserService _orderSlotParserService;
  final CoffeeRecommenderService _coffeeRecommenderService;
  final QueuePagerService _queuePagerService;
  final BisindoTtsService _ttsService;

  CafeCashierController({
    OrderSlotParserService? orderSlotParserService,
    CoffeeRecommenderService? coffeeRecommenderService,
    QueuePagerService? queuePagerService,
    BisindoTtsService? ttsService,
  })  : _orderSlotParserService =
            orderSlotParserService ?? OrderSlotParserService(),
        _coffeeRecommenderService =
            coffeeRecommenderService ?? const CoffeeRecommenderService(),
        _queuePagerService = queuePagerService ?? QueuePagerService(),
        _ttsService = ttsService ??
            (Get.isRegistered<BisindoTtsService>()
                ? Get.find<BisindoTtsService>()
                : BisindoTtsService());

  // ── 1. ACTIVE ORDER TICKET STATE ──────────────────────────────────────────
  final Rx<CafeOrderTicket> currentTicket = Rx<CafeOrderTicket>(
    CafeOrderTicket(
      orderId: 'ORD-108',
      queueNumber: 'A-108',
      customerName: '',
      items: const [],
      status: OrderStatus.draft,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 0,
      createdAt: DateTime.now(),
    ),
  );

  // ── 2. AUTO-ORDER SLOT PARSER (FITUR 1 & 6) ────────────────────────────────
  final Rx<ParsedCafeOrderSlot?> activeParsedSlot =
      Rx<ParsedCafeOrderSlot?>(null);
  final RxString liveTranscript = ''.obs;

  // ── 3. CUP NAME FINGERSELLING 1500MS BUFFER (FITUR 2) ─────────────────────
  final RxBool isSpellingCustomerName = false.obs;
  final RxString customerCupNameBuffer = ''.obs;
  Timer? _spellingInactivityTimer;
  Timer? _countdownTicker;
  final RxInt spellingRemainingMs = 1500.obs;

  // ── 4. AI BARISTA SOMMELIER (FITUR 3) ──────────────────────────────────────
  final Rx<CoffeeRecommendationResult?> activeRecommendation =
      Rx<CoffeeRecommendationResult?>(null);

  // ── 5. DUAL-MODE QUEUE PAGER (FITUR 4) ─────────────────────────────────────
  final RxBool isDeafCallActive = false.obs;
  final Rx<QueueCallEvent?> lastQueueCallEvent = Rx<QueueCallEvent?>(null);

  // ── 6. 1-TAP CASHIER QUICK DECK (FITUR 5) ─────────────────────────────────
  final RxInt activeQuickDeckIndex = (-1).obs;
  int _playSessionId = 0;

  // ── 7. WAITING SIGN CHALLENGE (FITUR 8) ───────────────────────────────────
  final RxString activeChallengeSign = 'TERIMA KASIH'.obs;
  final RxDouble challengeProgress = 0.0.obs;
  final RxBool isChallengeCompleted = false.obs;

  // ── 8. VIEW TOGGLES ────────────────────────────────────────────────────────
  final RxBool isCashierView = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Default initial recommendation
    activeRecommendation.value =
        _coffeeRecommenderService.recommendCoffee('kopi susu oat');
  }

  @override
  void onClose() {
    _spellingInactivityTimer?.cancel();
    _countdownTicker?.cancel();
    super.onClose();
  }

  // ── 1. TRANSCRIPT & AUTO-PARSING (FITUR 1 & 3 & 6) ─────────────────────────

  /// Ingests live transcript from Camera Sign Recognition or Mic Speech-to-Sign.
  void onTranscriptReceived(String transcript) {
    liveTranscript.value = transcript.trim();
    if (transcript.trim().isEmpty) return;

    // Feature 1 & 6: Parse structured slot & dietary alerts
    final parsed = _orderSlotParserService.parseTranscript(transcript);
    activeParsedSlot.value = parsed;

    // Feature 3: Evaluate Barista Sommelier Recommendation
    final recommendation =
        _coffeeRecommenderService.recommendCoffee(transcript);
    activeRecommendation.value = recommendation;
  }

  /// 1-Tap action to move auto-parsed slot into ticket.
  void confirmParsedSlotToTicket() {
    final slot = activeParsedSlot.value;
    if (slot != null) {
      addItemToTicket(slot);
      activeParsedSlot.value = null;
    }
  }

  void addItemToTicket(ParsedCafeOrderSlot slot) {
    final updatedList = List<ParsedCafeOrderSlot>.from(currentTicket.value.items)
      ..add(slot);
    currentTicket.value = currentTicket.value.copyWith(
      items: updatedList,
      status: OrderStatus.draft,
    );
  }

  void removeItemFromTicket(int index) {
    if (index >= 0 && index < currentTicket.value.items.length) {
      final updatedList =
          List<ParsedCafeOrderSlot>.from(currentTicket.value.items)
            ..removeAt(index);
      currentTicket.value = currentTicket.value.copyWith(items: updatedList);
    }
  }

  void clearTicket() {
    final nextQueue = _incrementQueue(currentTicket.value.queueNumber);
    currentTicket.value = CafeOrderTicket(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      queueNumber: nextQueue,
      customerName: '',
      items: const [],
      status: OrderStatus.draft,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 0,
      createdAt: DateTime.now(),
    );
    activeParsedSlot.value = null;
    isDeafCallActive.value = false;
    isChallengeCompleted.value = false;
    challengeProgress.value = 0.0;
  }

  String _incrementQueue(String current) {
    final parts = current.split('-');
    if (parts.length == 2) {
      final numVal = int.tryParse(parts[1]) ?? 1;
      final nextNum = (numVal + 1).toString().padLeft(3, '0');
      return '${parts[0]}-$nextNum';
    }
    return 'A-101';
  }

  // ── 2. 1500MS FINGERSELLING CUP NAME BUFFER (FITUR 2) ──────────────────────

  void startCustomerNameSpelling() {
    isSpellingCustomerName.value = true;
    customerCupNameBuffer.value = '';
    spellingRemainingMs.value = 1500;
    _resetSpellingTimer();
  }

  void addSpellingLetter(String letter) {
    if (!isSpellingCustomerName.value) {
      isSpellingCustomerName.value = true;
    }
    customerCupNameBuffer.value += letter.toUpperCase();
    _resetSpellingTimer();
  }

  void _resetSpellingTimer() {
    _spellingInactivityTimer?.cancel();
    _countdownTicker?.cancel();
    spellingRemainingMs.value = 1500;

    _countdownTicker =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (spellingRemainingMs.value > 100) {
        spellingRemainingMs.value -= 100;
      } else {
        spellingRemainingMs.value = 0;
        timer.cancel();
      }
    });

    _spellingInactivityTimer = Timer(const Duration(milliseconds: 1500), () {
      finishCustomerNameSpelling();
    });
  }

  Future<void> finishCustomerNameSpelling() async {
    _spellingInactivityTimer?.cancel();
    _countdownTicker?.cancel();
    final name = customerCupNameBuffer.value.trim();
    if (name.isNotEmpty) {
      currentTicket.value = currentTicket.value.copyWith(customerName: name);
      // Serial FIFO TTS: "Atas nama [Name]"
      await _ttsService.speak('Atas nama $name', languageCode: 'id-ID');
    }
    isSpellingCustomerName.value = false;
    spellingRemainingMs.value = 0;
  }

  // ── 3. DUAL-MODE QUEUE PAGER (FITUR 4) ─────────────────────────────────────

  Future<void> callHearingCustomer() async {
    final ticket = currentTicket.value;
    final event = await _queuePagerService.callHearingCustomer(
      queueNumber: ticket.queueNumber,
      customerName: ticket.customerName,
      ttsServiceOverride: _ttsService,
    );
    lastQueueCallEvent.value = event;
  }

  Future<void> callDeafCustomer() async {
    final ticket = currentTicket.value;
    final event = await _queuePagerService.callDeafCustomer(
      queueNumber: ticket.queueNumber,
      customerName: ticket.customerName,
    );
    lastQueueCallEvent.value = event;
    isDeafCallActive.value = true;

    // Trigger Sign Video for "PESANAN SIAP DIAMBIL"
    _triggerSignVideo(event.signVideoKeyword);
  }

  void dismissDeafCall() {
    isDeafCallActive.value = false;
  }

  // ── 4. 1-TAP CASHIER QUICK DECK (FITUR 5) ──────────────────────────────────

  static const List<String> quickDeckTextsId = [
    'Minum di sini (Dine-in) atau bawa pulang (Takeaway)?',
    'Mau ukuran Small, Medium, atau Large?',
    'Takaran es dan gulanya normal atau dikurangi?',
    'Untuk atas nama siapa di cup-nya?',
    'Silakan scan QRIS di layar, totalnya sudah sesuai.',
    'Terima kasih, mohon tunggu sebentar di area pickup.',
  ];

  static const List<String> quickDeckSignKeywords = [
    'MINUM SINI ATAU BAWA PULANG',
    'UKURAN GELAS',
    'ES DAN GULA',
    'NAMA SIAPA',
    'BAYAR QRIS',
    'TERIMA KASIH TUNGGU',
  ];

  Future<void> executeQuickDeck(int index) async {
    if (index < 0 || index >= quickDeckTextsId.length) return;
    activeQuickDeckIndex.value = index;
    final spokenText = quickDeckTextsId[index];
    final signKeyword = quickDeckSignKeywords[index];

    final currentSession = ++_playSessionId;

    // Action 1: Serial FIFO TTS
    unawaited(_ttsService.speak(spokenText, languageCode: 'id-ID'));

    // Action 2: Sign Video trigger guarded by session token
    _triggerSignVideo(signKeyword, sessionId: currentSession);

    // If Quick Action 4 is selected ("Untuk atas nama siapa"), automatically activate spelling mode!
    if (index == 3) {
      startCustomerNameSpelling();
    } else if (index == 5) {
      // Transition ticket to preparing status
      currentTicket.value =
          currentTicket.value.copyWith(status: OrderStatus.preparing);
    }
  }

  void _triggerSignVideo(String keyword, {int? sessionId}) {
    if (Get.isRegistered<TextToSignController>()) {
      final signController = Get.find<TextToSignController>();
      if (sessionId == null || sessionId == _playSessionId) {
        signController.searchSign(keyword, force: true);
      }
    }
  }

  // ── 5. BILL & CHANGE SYNC (FITUR 7) ────────────────────────────────────────

  void setPaymentMethod(OrderPaymentMethod method) {
    currentTicket.value = currentTicket.value.copyWith(paymentMethod: method);
  }

  void setAmountPaid(int amount) {
    currentTicket.value = currentTicket.value.copyWith(amountPaid: amount);
  }

  void addCashNominal(int addition) {
    final current = currentTicket.value.amountPaid;
    setAmountPaid(current + addition);
  }

  Future<void> translateBillToSignAndSpeech() async {
    final total = currentTicket.value.grandTotal;
    final text = 'Total pembayaran $total rupiah.';
    await _ttsService.speak(text, languageCode: 'id-ID');
    _triggerSignVideo('BAYAR $total');
  }

  // ── 6. WAITING SIGN CHALLENGE (FITUR 8) ────────────────────────────────────

  void startWaitingChallenge({String signWord = 'TERIMA KASIH'}) {
    activeChallengeSign.value = signWord;
    challengeProgress.value = 0.0;
    isChallengeCompleted.value = false;
  }

  Future<void> updateChallengeProgress(double progress) async {
    challengeProgress.value = progress.clamp(0.0, 1.0);
    if (challengeProgress.value >= 1.0 && !isChallengeCompleted.value) {
      isChallengeCompleted.value = true;
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
      await _ttsService.speak(
        'Luar biasa! Gestur isyarat kamu terkonfirmasi!',
        languageCode: 'id-ID',
      );
    }
  }

  void toggleDualView() {
    isCashierView.value = !isCashierView.value;
  }
}
