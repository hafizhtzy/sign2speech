import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/features/sign_language/controllers/sign_language_controller.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/bisindo_prediction.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/camera_feed_service.dart';
import 'package:speech2sign/features/translator/services/speech_service.dart';

import '../../../core/supabase/supabase_result.dart';
import '../../../core/localization/app_translations.dart';

import 'package:image_picker/image_picker.dart';

import '../data/datasources/cafe_menu_storage_service.dart';
import '../data/datasources/cafe_pos_local_data_source.dart';
import '../data/datasources/supabase_cafe_pos_service.dart';
import '../data/datasources/supabase_counter_session_service.dart';
import '../domain/models/cafe_order_ticket.dart';
import '../domain/models/coffee_customization_draft.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/coffee_recommendation_result.dart';
import '../domain/models/dietary_alert_tag.dart';
import '../domain/models/order_enums.dart';
import '../domain/models/parsed_cafe_order_slot.dart';
import '../domain/services/coffee_recommender_service.dart';
import '../domain/services/order_slot_parser_service.dart';
import '../domain/services/queue_pager_service.dart';

enum CafeCameraActiveFeature {
  none,
  liveOrder,
  cupNameSpelling,
  waitingChallenge,
}

class CafeCashierController extends GetxController {
  final OrderSlotParserService _orderSlotParserService;
  final CoffeeRecommenderService _coffeeRecommenderService;
  final QueuePagerService _queuePagerService;
  final BisindoTtsService _ttsService;
  final SpeechService _speechService;
  CameraFeedService? _cameraFeedService;
  SignLanguageController? _signLanguageController;
  final CafePosLocalDataSource _localDataSource;
  final SupabaseCafePosService? _supabaseCafePosService;
  final SupabaseCounterSessionService? _counterSessionService;
  final CafeMenuStorageService? _menuStorageService;

  SignLanguageController? get signLanguageController {
    if (_signLanguageController != null) return _signLanguageController;
    if (Get.isRegistered<SignLanguageController>()) {
      try {
        final found = Get.find<SignLanguageController>();
        _signLanguageController = found;
        return found;
      } catch (_) {}
    }
    return null;
  }

  TextToSignController? _textToSignController;

  TextToSignController? get textToSignController {
    if (_textToSignController != null) return _textToSignController;
    if (Get.isRegistered<TextToSignController>()) {
      try {
        final found = Get.find<TextToSignController>();
        _textToSignController = found;
        return found;
      } catch (_) {}
    }
    return null;
  }

  final Rx<SignLanguageModel> _activeSignModel = SignLanguageModel.bisindo.obs;
  SignLanguageModel get activeSignModel => _activeSignModel.value;

  CameraFeedService get cameraFeedService {
    if (_cameraFeedService != null) return _cameraFeedService!;
    if (Get.isRegistered<CameraFeedService>()) {
      try {
        final found = Get.find<CameraFeedService>();
        _cameraFeedService = found;
        return found;
      } catch (_) {}
    }
    final fallback = CameraFeedService();
    if (!Get.isRegistered<CameraFeedService>()) {
      Get.put<CameraFeedService>(fallback, permanent: true);
    }
    _cameraFeedService = fallback;
    return fallback;
  }

  CafePosLocalDataSource get localDataSource => _localDataSource;
  SupabaseCafePosService? get supabaseCafePosService => _supabaseCafePosService;
  SupabaseCounterSessionService? get counterSessionService =>
      _counterSessionService;
  CafeMenuStorageService? get menuStorageService => _menuStorageService;
  Worker? _ticketStorageWorker;
  Worker? _queueStorageWorker;
  StreamSubscription<dynamic>? _sessionStreamSub;

  /// Reactive catalog of coffee menus (merges standardCatalog with dynamic Supabase `cafe_menus`).
  final RxList<CoffeeMenuItem> menuCatalog = <CoffeeMenuItem>[
    ...CoffeeMenuItem.standardCatalog,
  ].obs;
  final RxBool isUploadingMenuPhoto = false.obs;

  CafeCashierController({
    OrderSlotParserService? orderSlotParserService,
    CoffeeRecommenderService? coffeeRecommenderService,
    QueuePagerService? queuePagerService,
    BisindoTtsService? ttsService,
    SpeechService? speechService,
    CameraFeedService? cameraFeedService,
    SignLanguageController? signLanguageController,
    CafePosLocalDataSource? localDataSource,
    SupabaseCafePosService? supabaseCafePosService,
    SupabaseCounterSessionService? counterSessionService,
    CafeMenuStorageService? menuStorageService,
    TextToSignController? textToSignController,
  }) : _orderSlotParserService =
           orderSlotParserService ?? OrderSlotParserService(),
       _coffeeRecommenderService =
           coffeeRecommenderService ?? const CoffeeRecommenderService(),
       _queuePagerService = queuePagerService ?? QueuePagerService(),
       _ttsService =
           ttsService ??
           (Get.isRegistered<BisindoTtsService>()
               ? Get.find<BisindoTtsService>()
               : BisindoTtsService()),
       _speechService =
           speechService ??
           (Get.isRegistered<SpeechService>()
               ? Get.find<SpeechService>()
               : SpeechService()),
       _cameraFeedService =
           cameraFeedService ??
           (Get.isRegistered<CameraFeedService>()
               ? Get.find<CameraFeedService>()
               : null),
       _signLanguageController =
           signLanguageController ??
           (Get.isRegistered<SignLanguageController>()
               ? Get.find<SignLanguageController>()
               : null),
       _textToSignController =
           textToSignController ??
           (Get.isRegistered<TextToSignController>()
               ? Get.find<TextToSignController>()
               : null),
       _localDataSource =
           localDataSource ??
           (Get.isRegistered<CafePosLocalDataSource>()
               ? Get.find<CafePosLocalDataSource>()
               : CafePosLocalDataSource()),
       _supabaseCafePosService =
           supabaseCafePosService ??
           (Get.isRegistered<SupabaseCafePosService>()
               ? Get.find<SupabaseCafePosService>()
               : null),
       _counterSessionService =
           counterSessionService ??
           (Get.isRegistered<SupabaseCounterSessionService>()
               ? Get.find<SupabaseCounterSessionService>()
               : null),
       _menuStorageService =
           menuStorageService ??
           (Get.isRegistered<CafeMenuStorageService>()
               ? Get.find<CafeMenuStorageService>()
               : CafeMenuStorageService());

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

  // ── ACTIVE ORDERS QUEUE (ORDER MANAGEMENT) ───────────────────────────────
  final RxList<CafeOrderTicket> activeOrdersQueue = <CafeOrderTicket>[].obs;

  // ── 2. AUTO-ORDER SLOT PARSER & SPEECH (FITUR 1 & 6) ──────────────────────
  final Rx<ParsedCafeOrderSlot?> activeParsedSlot = Rx<ParsedCafeOrderSlot?>(
    null,
  );
  final RxString liveTranscript = ''.obs;
  final RxList<String> liveOrderWords = <String>[].obs;
  DateTime _lastLiveSignTime = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastLiveSignWord = '';
  final RxBool isListening = false.obs;

  // ── 3. CUP NAME FINGERSELLING 1500MS BUFFER (FITUR 2) ─────────────────────
  final RxBool isSpellingCustomerName = false.obs;
  final RxString customerCupNameBuffer = ''.obs;
  Timer? _spellingInactivityTimer;
  Timer? _countdownTicker;
  final RxInt spellingRemainingMs = 1500.obs;

  static const List<String> fullAlphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  // ── 4. AI BARISTA SOMMELIER (FITUR 3) ──────────────────────────────────────
  final Rx<CoffeeRecommendationResult?> activeRecommendation =
      Rx<CoffeeRecommendationResult?>(null);
  final RxString selectedSommelierTag = 'Semua'.obs;

  // ── 5. DUAL-MODE QUEUE PAGER (FITUR 4) ─────────────────────────────────────
  final RxBool isDeafCallActive = false.obs;
  final Rx<QueueCallEvent?> lastQueueCallEvent = Rx<QueueCallEvent?>(null);

  // ── 6. 1-TAP CASHIER QUICK DECK (FITUR 5) ─────────────────────────────────
  final RxInt activeQuickDeckIndex = (-1).obs;
  final RxList<String> activeCustomerQuickReplies = <String>[].obs;
  final RxString lastCustomerReply = ''.obs;
  final RxString lastCustomerActionFeedback = ''.obs;
  final RxInt loyaltyStampsCount = 0.obs;
  int _playSessionId = 0;

  // ── 7. WAITING SIGN CHALLENGE (FITUR 8) ───────────────────────────────────
  static const List<String> challengeVocabulary = [
    'TERIMA KASIH',
    'KOPI',
    'SUSU',
    'DINGIN',
    'PANAS',
    'SAMA-SAMA',
  ];

  static const List<String> sibiChallengeVocabulary = [
    'TERIMA',
    'KASIH',
    'MINUM',
    'AIR',
    'MAKAN',
  ];

  List<String> get currentChallengeVocabulary =>
      _activeSignModel.value == SignLanguageModel.sibi
      ? sibiChallengeVocabulary
      : challengeVocabulary;

  final RxInt challengeWordIndex = 0.obs;
  final RxString activeChallengeSign = 'TERIMA KASIH'.obs;
  final RxDouble challengeProgress = 0.0.obs;
  final RxBool isChallengeCompleted = false.obs;
  final RxBool isMiniCameraModalOpen = false.obs;
  final RxBool showTrophyDialog = false.obs;

  // ── 8. PAYMENT & BILL (FITUR 7) ───────────────────────────────────────────
  final RxBool isQrisProcessing = false.obs;
  final RxBool isOrderCompleted = false.obs;

  // ── 9. VIEW TOGGLES ────────────────────────────────────────────────────────
  final RxBool isCashierView = true.obs;

  // ── 10. ACTIVE CAMERA FEATURE & LIVE RECOGNITION ───────────────────────────
  final Rx<CafeCameraActiveFeature> activeCameraFeature =
      CafeCameraActiveFeature.none.obs;
  final RxString detectedSpellingLetter = ''.obs;
  final RxDouble letterHoldProgress = 0.0.obs;
  String _lastDetectedCandidate = '';
  int _letterStreakCount = 0;

  // ── 11. MASTER PROMPT V2: 3-STAGE STATE MACHINE ───────────────────────────
  /// Tahap alur pesanan aktif (idle / ordering / naming / pickup).
  final Rx<CafeOrderStage> currentStage = CafeOrderStage.idle.obs;

  /// Mode perangkat (1-tablet geser / 2-tablet paired).
  final Rx<CounterDeviceMode> deviceMode =
      CounterDeviceMode.singleTabletSwitch.obs;

  /// Counter ID permanen untuk pairing (default: KAFE-01).
  static const String defaultCounterId = 'KAFE-01';
  final RxString counterId = defaultCounterId.obs;

  /// Menandai apakah tablet ber-role CUSTOMER sudah berhasil melakukan pairing
  /// dengan kode ruangan Kasir (untuk tablet kafe yang tertempel di meja kasir).
  RxBool? _isPairedCustomerSession;
  RxBool get isPairedCustomerSession => _isPairedCustomerSession ??= false.obs;

  // ── 12. SINGLE-TABLET FLIP MODE ───────────────────────────────────────────
  /// True = layar di-flip 180° untuk mode hadap-harap (1 tablet, kasir + pembeli).
  final RxBool isFlipped = false.obs;

  /// Toggle flip state (putar/kembalikan layar 180°).
  void toggleFlip() {
    isFlipped.toggle();
    if (deviceMode.value == CounterDeviceMode.singleTabletSwitch) {
      isCashierView.value = !isFlipped.value;
    }
  }

  /// Reset flip ke posisi normal kasir.
  void resetFlip() {
    isFlipped.value = false;
  }

  /// Status auth PIN staff (Quick Staff PIN offline-first).
  final RxBool staffPinAuthenticated = false.obs;
  final RxString staffPin = ''.obs; // Offline PIN (4 digit)

  /// Flag apakah alergi susu sudah di-auto-switch ke Oat Milk.
  final RxBool dairyAllergyAutoSwitched = false.obs;

  /// Pesan notif auto-switch susu untuk ditampilkan di UI.
  final RxString dairyAllergyBannerMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    AppTranslations.ensureLoaded();
    // Default initial recommendation
    activeRecommendation.value = _coffeeRecommenderService.recommendCoffee(
      'kopi susu oat',
    );
    _syncModelWithSettings();
    if (Get.isRegistered<SettingsController>()) {
      ever(Get.find<SettingsController>().selectedSignLanguage, (lang) {
        _syncModelWithSettings();
      });
    }
    _connectSignLanguageFeed();
    loadPersistedTicket();
    unawaited(refreshCloudMenus());
    // V2: Sync stage to Supabase whenever it changes
    ever<CafeOrderStage>(currentStage, (stage) {
      _counterSessionService?.syncStage(
        counterId.value,
        stage,
        currentOrderId: currentTicket.value.orderId,
      );
    });
  }

  // ── DYNAMIC CAFE MENU & PHOTO CRUD (SUPABASE STORAGE) ─────────────────────

  /// Refreshes menu items from Supabase `cafe_menus` and merges with `standardCatalog`.
  Future<void> refreshCloudMenus() async {
    final service = _menuStorageService;
    if (service == null) return;
    final res = await service.fetchMenus();
    switch (res) {
      case SupabaseSuccess<List<CoffeeMenuItem>>(data: final cloudMenus):
        if (cloudMenus.isEmpty) return;
        final mergedById = <String, CoffeeMenuItem>{
          for (final item in CoffeeMenuItem.standardCatalog) item.id: item,
        };
        for (final cloudItem in cloudMenus) {
          mergedById[cloudItem.id] = cloudItem;
        }
        menuCatalog.assignAll(mergedById.values.toList());
      case SupabaseFailure<List<CoffeeMenuItem>>():
        // Offline or Supabase not initialized — keep local standardCatalog
        break;
    }
  }

  /// Picks a photo from Camera or Gallery, compresses it, uploads to `menu-photos` bucket,
  /// deletes the previous photo if present, and updates `cafe_menus`.
  Future<CoffeeMenuItem?> pickAndUploadMenuPhoto(
    CoffeeMenuItem item, {
    bool fromCamera = false,
  }) async {
    final service = _menuStorageService ?? CafeMenuStorageService();
    isUploadingMenuPhoto.value = true;
    try {
      final pickRes = await service.pickAndCompressPhoto(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      switch (pickRes) {
        case SupabaseSuccess<Uint8List?>(data: final bytes):
          if (bytes == null || bytes.isEmpty) {
            return null;
          }
          final uploadRes = await service.uploadMenuPhoto(
            menuId: item.id,
            imageBytes: bytes,
            oldStoragePath: item.storagePath,
            fallbackMenuTemplate: item,
          );
          switch (uploadRes) {
            case SupabaseSuccess<MenuPhotoUploadResult>(data: final uploaded):
              final updated = item.copyWith(
                imageUrl: uploaded.imageUrl,
                storagePath: uploaded.storagePath,
              );
              final idx = menuCatalog.indexWhere((m) => m.id == item.id);
              if (idx >= 0) {
                menuCatalog[idx] = updated;
              } else {
                menuCatalog.add(updated);
              }
              return updated;
            case SupabaseFailure<MenuPhotoUploadResult>():
              return null;
          }
        case SupabaseFailure<Uint8List?>():
          return null;
      }
    } finally {
      isUploadingMenuPhoto.value = false;
    }
  }

  /// Creates or updates a menu item in Supabase `cafe_menus`.
  Future<bool> upsertMenuItem(
    CoffeeMenuItem item, {
    Uint8List? newPhotoBytes,
  }) async {
    final service = _menuStorageService;
    if (service == null) return false;
    final res = await service.upsertMenu(item, newPhotoBytes: newPhotoBytes);
    switch (res) {
      case SupabaseSuccess<CoffeeMenuItem>(data: final saved):
        final idx = menuCatalog.indexWhere((m) => m.id == saved.id);
        if (idx >= 0) {
          menuCatalog[idx] = saved;
        } else {
          menuCatalog.add(saved);
        }
        return true;
      case SupabaseFailure<CoffeeMenuItem>():
        return false;
    }
  }

  /// Deletes a menu item from Supabase `cafe_menus` and removes its photo from `menu-photos`.
  Future<bool> deleteMenuItem(CoffeeMenuItem item) async {
    final service = _menuStorageService;
    if (service == null) return false;
    final res = await service.deleteMenu(
      menuId: item.id,
      storagePath: item.storagePath,
    );
    switch (res) {
      case SupabaseSuccess<void>():
        menuCatalog.removeWhere((m) => m.id == item.id);
        return true;
      case SupabaseFailure<void>():
        return false;
    }
  }

  Future<void> _syncModelWithSettings() async {
    SignLanguageModel targetModel = SignLanguageModel.bisindo;
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      if (settings.selectedSignLanguage.value.toUpperCase() == 'SIBI') {
        targetModel = SignLanguageModel.sibi;
      }
    }
    _activeSignModel.value = targetModel;
    _syncChallengeVocabularyForModel(targetModel);

    final signCtrl = signLanguageController;
    if (signCtrl != null) {
      if (signCtrl.currentModel.value != targetModel ||
          !signCtrl.classifierService.isInitialized) {
        try {
          await signCtrl.switchModel(targetModel);
        } catch (_) {}
      }
    }
  }

  Future<void> switchSignLanguageModel(SignLanguageModel model) async {
    _activeSignModel.value = model;
    _syncChallengeVocabularyForModel(model);
    if (Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>().setSignLanguage(
        model == SignLanguageModel.sibi ? 'SIBI' : 'BISINDO',
      );
    }
    textToSignController?.selectedLanguage.value =
        model == SignLanguageModel.sibi ? 'sibi' : 'bisindo';
    final signCtrl = signLanguageController;
    if (signCtrl != null) {
      try {
        await signCtrl.switchModel(model);
      } catch (_) {}
    }
    if (liveTranscript.value.isNotEmpty) {
      _triggerSignVideo(liveTranscript.value);
    }
  }

  void _syncChallengeVocabularyForModel(SignLanguageModel model) {
    final vocab = model == SignLanguageModel.sibi
        ? sibiChallengeVocabulary
        : challengeVocabulary;
    if (challengeWordIndex.value >= vocab.length) {
      challengeWordIndex.value = 0;
    }
    activeChallengeSign.value = vocab[challengeWordIndex.value];
    challengeProgress.value = 0.0;
    isChallengeCompleted.value = false;
  }

  /// Restores active ticket and order queue from local storage and initiates auto-save workers.
  Future<void> loadPersistedTicket() async {
    final saved = await _localDataSource.loadActiveTicket();
    if (saved != null) {
      currentTicket.value = saved;
    }
    final savedQueue = await _localDataSource.loadActiveQueue();
    if (savedQueue.isNotEmpty) {
      activeOrdersQueue.assignAll(savedQueue);
    }
    loyaltyStampsCount.value = await _localDataSource.loadLoyaltyStamps();
    _ticketStorageWorker?.dispose();
    _ticketStorageWorker = ever<CafeOrderTicket>(currentTicket, (ticket) {
      _localDataSource.saveActiveTicket(ticket);
    });

    _queueStorageWorker?.dispose();
    _queueStorageWorker = ever<List<CafeOrderTicket>>(activeOrdersQueue, (
      queue,
    ) {
      _localDataSource.saveActiveQueue(queue);
    });
  }

  /// Manually trigger immediate persistence of the current ticket and queue.
  Future<void> persistCurrentTicket() async {
    await _localDataSource.saveActiveTicket(currentTicket.value);
    await _localDataSource.saveActiveQueue(activeOrdersQueue.toList());
  }

  // ── COFFEE DRAFT CUSTOMIZATION ACCESSORS ─────────────────────────────────
  Future<CoffeeCustomizationDraft?> getDraftForDrink(String drinkId) =>
      _localDataSource.loadCustomizationDraft(drinkId);

  Future<void> saveDraftForDrink(CoffeeCustomizationDraft draft) =>
      _localDataSource.saveCustomizationDraft(draft);

  Future<void> clearDraftForDrink(String drinkId) =>
      _localDataSource.clearCustomizationDraft(drinkId);

  @override
  void onClose() {
    _ticketStorageWorker?.dispose();
    _ticketStorageWorker = null;
    _queueStorageWorker?.dispose();
    _queueStorageWorker = null;
    _sessionStreamSub?.cancel();
    _sessionStreamSub = null;
    _spellingInactivityTimer?.cancel();
    _countdownTicker?.cancel();
    if (isListening.value) {
      _speechService.stopListening();
    }
    try {
      final signCtrl = signLanguageController;
      if (signCtrl != null && signCtrl.isContinuousRunning.value) {
        signCtrl.stopContinuous();
      }
      _cameraFeedService?.stopCamera();
    } catch (_) {}
    super.onClose();
  }

  // ── MASTER PROMPT V2: 3-STAGE STATE MACHINE METHODS ────────────────────────

  void _showStageSnackbar(String title, String message) {
    if (Get.context != null) {
      AppSnackbar.warning(
        title: title,
        message: message,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Maju ke tahap berikutnya: idle → ordering → naming → pickup → idle
  void advanceStage() {
    switch (currentStage.value) {
      case CafeOrderStage.idle:
        currentStage.value = CafeOrderStage.ordering;
        break;
      case CafeOrderStage.ordering:
        if (currentTicket.value.items.isNotEmpty) {
          currentStage.value = CafeOrderStage.naming;
        } else {
          _showStageSnackbar(
            'Pesanan Masih Kosong',
            'Silakan konfirmasi minimal 1 item pesanan sebelum lanjut ke tahap penamaan cup.',
          );
        }
        break;
      case CafeOrderStage.naming:
        if (!currentTicket.value.isPaid) {
          _showStageSnackbar(
            'Pembayaran Belum Dilakukan',
            'Silakan lakukan simulasi pembayaran (QRIS atau Tunai) terlebih dahulu sebelum lanjut ke tahap pengambilan kopi.',
          );
          return;
        }
        currentStage.value = CafeOrderStage.pickup;
        break;
      case CafeOrderStage.pickup:
        if (!currentTicket.value.isPaid) {
          _showStageSnackbar(
            'Pembayaran Belum Dilakukan',
            'Pesanan belum dibayar. Silakan lakukan pembayaran terlebih dahulu.',
          );
          return;
        }
        // Selesai → bersihkan tiket dan kembali ke idle
        clearTicket();
        currentStage.value = CafeOrderStage.idle;
        break;
    }
  }

  /// Lompat langsung ke tahap tertentu (dipanggil dari UI button).
  void goToStage(CafeOrderStage stage, {bool force = false}) {
    if (!force &&
        stage == CafeOrderStage.pickup &&
        !currentTicket.value.isPaid) {
      _showStageSnackbar(
        'Pembayaran Belum Dilakukan',
        'Silakan selesaikan simulasi pembayaran (QRIS atau Tunai) terlebih dahulu sebelum ke tahap Ambil Kopi.',
      );
      return;
    }
    if (stage == CafeOrderStage.ordering) {
      resetFlip();
      isCashierView.value = true;
    }
    currentStage.value = stage;
  }

  /// Reset ke idle & bersihkan semua state.
  void resetToIdle() {
    resetFlip();
    currentStage.value = CafeOrderStage.idle;
    dairyAllergyAutoSwitched.value = false;
    dairyAllergyBannerMessage.value = '';
    clearTicket();
  }

  // ── MASTER PROMPT V2: QUICK STAFF PIN ──────────────────────────────────────

  /// Verifikasi PIN staff (4 digit, offline-first).
  /// PIN default '0000' jika belum pernah diset.
  bool verifyStaffPin(String inputPin) {
    final savedPin = staffPin.value.isEmpty ? '0000' : staffPin.value;
    final authenticated = inputPin == savedPin;
    staffPinAuthenticated.value = authenticated;
    if (authenticated) {
      // Tablet kasir terautentikasi: otomatis sisi kasir
      isCashierView.value = true;
      if (deviceMode.value == CounterDeviceMode.dualTabletLocked) {
        if (counterId.value.isEmpty || counterId.value == defaultCounterId) {
          createRoomSession();
        }
      }
    }
    return authenticated;
  }

  /// Set PIN baru staff (hanya setelah authenticated).
  bool setNewStaffPin(String newPin) {
    if (newPin.length != 4) return false;
    staffPin.value = newPin;
    return true;
  }

  /// Logout staff (reset authenticated state).
  void logoutStaff() {
    staffPinAuthenticated.value = false;
    // Jika mode 2-tablet, tablet tanpa PIN otomatis menjadi sisi pembeli
    if (deviceMode.value == CounterDeviceMode.dualTabletLocked) {
      isCashierView.value = false;
    }
  }

  // ── MASTER PROMPT V2: DAIRY ALLERGY AUTO-SWITCH ───────────────────────────

  /// Auto-switch susu sapi ke Oat Milk jika ada alergi dairy terdeteksi.
  /// Dipanggil dari onTranscriptReceived saat allergy terdeteksi.
  void _checkAndAutoSwitchDairyAllergy(List<DietaryAlertTag> alerts) {
    if (dairyAllergyAutoSwitched.value) return;
    final hasDairyAllergy = alerts.any(
      (a) =>
          a.type == DietaryAlertType.dairyAllergy ||
          a.type == DietaryAlertType.lactoseIntolerant,
    );
    if (!hasDairyAllergy) return;

    // Auto-switch semua item yang menggunakan freshDairy ke oatMilk
    final updatedItems = currentTicket.value.items.map((item) {
      if (item.milkType == OrderMilkType.freshDairy) {
        return item.copyWith(milkType: OrderMilkType.oatMilk);
      }
      return item;
    }).toList();

    currentTicket.value = currentTicket.value.copyWith(items: updatedItems);
    dairyAllergyAutoSwitched.value = true;
    dairyAllergyBannerMessage.value =
        '⚠️ Alergi susu terdeteksi — otomatis diganti ke Susu Oat';
  }

  // ── MASTER PROMPT V2: DEVICE PAIRING ───────────────────────────────────────

  /// Switch mode perangkat (1-tablet <-> 2-tablet).
  Future<void> setDeviceMode(CounterDeviceMode mode) async {
    deviceMode.value = mode;
    if (mode == CounterDeviceMode.dualTabletLocked) {
      resetFlip();
      // Otoritas peran: Kasir jika staff terautentikasi PIN, Pembeli jika tanpa PIN
      if (staffPinAuthenticated.value) {
        isCashierView.value = true;
      } else {
        isCashierView.value = false;
      }
    }
    await _counterSessionService?.pairDevices(
      counterId: counterId.value,
      cashierTabletId: 'cashier-${counterId.value}',
      customerTabletId: mode == CounterDeviceMode.dualTabletLocked
          ? 'customer-${counterId.value}'
          : '',
      mode: mode,
    );
  }

  /// Set pairing code / counter ID.
  void setPairingCounterId(String id) {
    counterId.value = id.trim().toUpperCase();
  }

  /// Generate kode room unik dan aktifkan mode sinkronisasi 2-tablet (Host Kasir).
  Future<String> createRoomSession([String? customCode]) async {
    final code = (customCode != null && customCode.trim().isNotEmpty)
        ? customCode.trim().toUpperCase()
        : 'KAFE-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    setPairingCounterId(code);
    isCashierView.value = true;
    await setDeviceMode(CounterDeviceMode.dualTabletLocked);
    return code;
  }

  /// Hubungkan ke room counter session yang ada (untuk tablet pembeli).
  Future<void> joinRoomSession(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;
    setPairingCounterId(cleanCode);
    isPairedCustomerSession.value = true;
    isCashierView.value =
        false; // Tablet yang menghubungkan adalah sisi pembeli
    if (currentStage.value == CafeOrderStage.idle) {
      currentStage.value = CafeOrderStage.ordering;
    }
    await setDeviceMode(CounterDeviceMode.dualTabletLocked);
    startSessionStream();
  }

  /// Putuskan sesi pairing tablet pembeli dari meja kasir.
  void disconnectPairedCustomerSession() {
    isPairedCustomerSession.value = false;
    _sessionStreamSub?.cancel();
    _sessionStreamSub = null;
  }

  /// Mulai listen real-time session dari Supabase (untuk tablet pembeli).
  void startSessionStream() {
    _sessionStreamSub?.cancel();
    final svc = _counterSessionService;
    if (svc == null) return;
    _sessionStreamSub = svc.streamSession(counterId.value).listen((session) {
      // Sinkronisasi stage dari cloud ke tablet pembeli
      if (session.stage != currentStage.value) {
        currentStage.value = session.stage;
      }
    });
  }

  // ── CAMERA & GESTURE RECOGNITION COORDINATION ────────────────────────────

  Future<void> openCameraFor(CafeCameraActiveFeature feature) async {
    activeCameraFeature.value = feature;
    if (feature == CafeCameraActiveFeature.cupNameSpelling) {
      if (!isSpellingCustomerName.value) {
        startCustomerNameSpelling();
      }
    } else if (feature == CafeCameraActiveFeature.waitingChallenge) {
      isMiniCameraModalOpen.value = true;
    }

    await _syncModelWithSettings();
    _connectSignLanguageFeed();

    final signCtrl = signLanguageController;
    if (signCtrl != null) {
      await signCtrl.startContinuous();
    } else {
      await cameraFeedService.startCamera();
    }
  }

  Future<void> closeCamera() async {
    activeCameraFeature.value = CafeCameraActiveFeature.none;
    isMiniCameraModalOpen.value = false;

    final signCtrl = signLanguageController;
    if (signCtrl != null && signCtrl.isContinuousRunning.value) {
      await signCtrl.stopContinuous();
    } else {
      await cameraFeedService.stopCamera();
    }

    letterHoldProgress.value = 0.0;
    detectedSpellingLetter.value = '';
    _lastDetectedCandidate = '';
    _letterStreakCount = 0;
  }

  Future<void> switchCameraLens() async {
    await cameraFeedService.switchCamera();
  }

  void _connectSignLanguageFeed() {
    final controller = signLanguageController;
    if (controller != null) {
      controller.onPredictionAccepted = _handleLivePrediction;
    }
  }

  void _handleLivePrediction(BisindoPrediction prediction) {
    final label = prediction.cleanLabel.trim();
    if (label.isEmpty) return;

    switch (activeCameraFeature.value) {
      case CafeCameraActiveFeature.liveOrder:
        addSignWordToLiveOrder(label);
        break;

      case CafeCameraActiveFeature.cupNameSpelling:
        _handleSpellingGesture(label);
        break;

      case CafeCameraActiveFeature.waitingChallenge:
        _handleChallengeGesture(label);
        break;

      case CafeCameraActiveFeature.none:
        break;
    }
  }

  void _handleSpellingGesture(String label) {
    final upper = label.toUpperCase();
    if (upper.length == 1 &&
        upper.codeUnitAt(0) >= 65 &&
        upper.codeUnitAt(0) <= 90) {
      detectedSpellingLetter.value = upper;
      if (_lastDetectedCandidate == upper) {
        _letterStreakCount++;
        letterHoldProgress.value = (_letterStreakCount / 2).clamp(0.0, 1.0);
        if (_letterStreakCount >= 2) {
          addSpellingLetter(upper);
          _letterStreakCount = 0;
          letterHoldProgress.value = 0.0;
          try {
            HapticFeedback.lightImpact();
          } catch (_) {}
        }
      } else {
        _lastDetectedCandidate = upper;
        _letterStreakCount = 1;
        letterHoldProgress.value = 0.5;
      }
    }
  }

  void _handleChallengeGesture(String label) {
    final target = activeChallengeSign.value.toUpperCase();
    final current = label.toUpperCase();

    bool isMatch = current == target;
    if (!isMatch) {
      final targetWords = target.split(' ');
      for (final tw in targetWords) {
        if (tw.length >= 3 && (current.contains(tw) || tw.contains(current))) {
          isMatch = true;
          break;
        }
      }
    }

    if (isMatch) {
      final nextProgress = (challengeProgress.value + 0.34).clamp(0.0, 1.0);
      updateChallengeProgress(nextProgress);
    }
  }

  // ── 1. TRANSCRIPT & AUTO-PARSING & SPEECH (FITUR 1 & 3 & 6) ───────────────

  /// Ingests live sign word into sentence accumulator with anti-jitter debouncing
  void addSignWordToLiveOrder(String word) {
    final cleaned = word.trim().toUpperCase();
    if (cleaned.isEmpty) return;

    final now = DateTime.now();
    // Anti-jitter: ignore identical repeated word if under 1100ms
    if (cleaned == _lastLiveSignWord &&
        now.difference(_lastLiveSignTime).inMilliseconds < 1100) {
      return;
    }

    _lastLiveSignTime = now;
    _lastLiveSignWord = cleaned;
    liveOrderWords.add(cleaned);
    final sentence = liveOrderWords.join(' ');
    liveTranscript.value = sentence;

    // Auto-advance stage from idle to ordering
    if (currentStage.value == CafeOrderStage.idle) {
      currentStage.value = CafeOrderStage.ordering;
    }

    // Trigger realtime sign video on cashier screen
    _triggerSignVideo(sentence);

    // Parse structured slot dynamically from accumulated sentence
    final parsed = _orderSlotParserService.parseTranscript(sentence);
    activeParsedSlot.value = parsed;

    // Auto-switch dairy allergy if detected
    if (parsed.dietaryAlerts.isNotEmpty) {
      _checkAndAutoSwitchDairyAllergy(parsed.dietaryAlerts);
    }

    // Barista Sommelier Recommendation
    final recommendation = _coffeeRecommenderService.recommendCoffee(sentence);
    activeRecommendation.value = recommendation;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Deletes the last word from the sign sentence accumulator
  void deleteLastSignWord() {
    if (liveOrderWords.isNotEmpty) {
      liveOrderWords.removeLast();
      final sentence = liveOrderWords.join(' ');
      liveTranscript.value = sentence;
      if (sentence.isEmpty) {
        activeParsedSlot.value = null;
        _lastLiveSignWord = '';
        textToSignController?.searchSign('');
      } else {
        final parsed = _orderSlotParserService.parseTranscript(sentence);
        activeParsedSlot.value = parsed;
        activeRecommendation.value = _coffeeRecommenderService.recommendCoffee(
          sentence,
        );
        _triggerSignVideo(sentence);
      }
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  /// Clears the entire sign sentence accumulator
  void clearLiveOrderSentence() {
    liveOrderWords.clear();
    liveTranscript.value = '';
    activeParsedSlot.value = null;
    _lastLiveSignWord = '';
    textToSignController?.searchSign('');
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Ingests live transcript from Camera Sign Recognition, Mic STT, or text.
  void onTranscriptReceived(String transcript, {bool triggerSign = true}) {
    final trimmed = transcript.trim();
    liveTranscript.value = trimmed;
    if (trimmed.isEmpty) {
      liveOrderWords.clear();
      activeParsedSlot.value = null;
      textToSignController?.searchSign('');
      return;
    }

    // Synchronize sentence accumulator with typed / spoken text
    liveOrderWords.assignAll(
      trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty),
    );

    // V2: Auto-advance dari idle ke ordering saat ada input pertama
    if (currentStage.value == CafeOrderStage.idle) {
      currentStage.value = CafeOrderStage.ordering;
    }

    // Speech-to-Sign: Trigger realtime sign language video for deaf cashier
    if (triggerSign) {
      _triggerSignVideo(trimmed);
    }

    // Feature 1 & 6: Parse structured slot & dietary alerts
    final parsed = _orderSlotParserService.parseTranscript(trimmed);
    activeParsedSlot.value = parsed;

    // V2: Auto-switch susu sapi ke Oat Milk jika alergi dairy terdeteksi
    if (parsed.dietaryAlerts.isNotEmpty) {
      _checkAndAutoSwitchDairyAllergy(parsed.dietaryAlerts);
    }

    // Feature 3: Evaluate Barista Sommelier Recommendation
    final recommendation = _coffeeRecommenderService.recommendCoffee(trimmed);
    activeRecommendation.value = recommendation;
  }

  /// Submits an order edited/spoken by hearing customer on "Pesan & AI" page.
  /// Synchronizes the transcript, triggers real-time sign video for the deaf cashier,
  /// and automatically commits the parsed coffee slot to the order ticket.
  void submitCustomerVoiceOrder(String editedText) {
    final trimmed = editedText.trim();
    if (trimmed.isEmpty) return;
    onTranscriptReceived(trimmed, triggerSign: true);
    final slot = activeParsedSlot.value;
    if (slot != null && slot.drinkId.isNotEmpty) {
      confirmParsedSlotToTicket();
    }
  }

  /// Toggles live microphone input via SpeechService.
  Future<void> toggleListening() async {
    if (isListening.value) {
      isListening.value = false;
      await _speechService.stopListening();
    } else {
      isListening.value = true;
      try {
        await _speechService.startListening(
          languageCode: 'id_ID',
          onResult: (text, isFinal) {
            liveTranscript.value = text;
            onTranscriptReceived(text);
            if (isFinal) {
              isListening.value = false;
            }
          },
        );
      } catch (e) {
        isListening.value = false;
      }
    }
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
    final updatedList = List<ParsedCafeOrderSlot>.from(
      currentTicket.value.items,
    )..add(slot);
    currentTicket.value = currentTicket.value.copyWith(
      items: updatedList,
      status: OrderStatus.draft,
    );
  }

  void removeItemFromTicket(int index) {
    if (index >= 0 && index < currentTicket.value.items.length) {
      final updatedList = List<ParsedCafeOrderSlot>.from(
        currentTicket.value.items,
      )..removeAt(index);
      currentTicket.value = currentTicket.value.copyWith(items: updatedList);
    }
  }

  void clearTicket() {
    final nextQueue = _incrementQueue(currentTicket.value.queueNumber);
    currentTicket.value = CafeOrderTicket(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      queueNumber: nextQueue,
      customerName: '',
      customerNotes: '',
      items: const [],
      status: OrderStatus.draft,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 0,
      createdAt: DateTime.now(),
    );
    activeParsedSlot.value = null;
    clearLiveOrderSentence();
    _cancelSpellingTimers();
    customerCupNameBuffer.value = '';
    isSpellingCustomerName.value = false;
    spellingRemainingMs.value = 0;
    detectedSpellingLetter.value = '';
    letterHoldProgress.value = 0.0;
    _letterStreakCount = 0;
    _lastDetectedCandidate = '';
    isDeafCallActive.value = false;
    isChallengeCompleted.value = false;
    challengeProgress.value = 0.0;
    isOrderCompleted.value = false;
    isQrisProcessing.value = false;
    activeCustomerQuickReplies.clear();
    lastCustomerReply.value = '';
    textToSignController?.searchSign('');
    lastCustomerActionFeedback.value = '';
    activeRecommendation.value = null;
    isMiniCameraModalOpen.value = false;
    showTrophyDialog.value = false;
    closeCamera();
    unawaited(_localDataSource.clearActiveTicket());
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

  // ── 2. FINGERSELLING CUP NAME BUFFER (FITUR 2) ───────────────────────────

  void startCustomerNameSpelling() {
    isSpellingCustomerName.value = true;
    customerCupNameBuffer.value = '';
    spellingRemainingMs.value = 0;
    _cancelSpellingTimers();
    if (activeCameraFeature.value != CafeCameraActiveFeature.cupNameSpelling) {
      openCameraFor(CafeCameraActiveFeature.cupNameSpelling);
    }
  }

  void addSpellingLetter(String letter) {
    if (!isSpellingCustomerName.value) {
      isSpellingCustomerName.value = true;
    }
    customerCupNameBuffer.value += letter.toUpperCase();
  }

  void deleteSpellingLetter() {
    if (customerCupNameBuffer.value.isNotEmpty) {
      customerCupNameBuffer.value = customerCupNameBuffer.value.substring(
        0,
        customerCupNameBuffer.value.length - 1,
      );
    }
  }

  void addSpellingSpace() {
    if (customerCupNameBuffer.value.isNotEmpty &&
        !customerCupNameBuffer.value.endsWith(' ')) {
      customerCupNameBuffer.value += ' ';
    }
  }

  void clearSpellingBuffer() {
    customerCupNameBuffer.value = '';
  }

  void _cancelSpellingTimers() {
    _spellingInactivityTimer?.cancel();
    _spellingInactivityTimer = null;
    _countdownTicker?.cancel();
    _countdownTicker = null;
  }

  Future<void> finishCustomerNameSpelling() async {
    _cancelSpellingTimers();
    final name = customerCupNameBuffer.value.trim();
    if (name.isNotEmpty) {
      currentTicket.value = currentTicket.value.copyWith(customerName: name);
      // Serial FIFO TTS: "Atas nama [Name]"
      await _ttsService.speak('Atas nama $name', languageCode: 'id-ID');
    }
    customerCupNameBuffer.value = '';
    isSpellingCustomerName.value = false;
    spellingRemainingMs.value = 0;
    detectedSpellingLetter.value = '';
    letterHoldProgress.value = 0.0;
    _letterStreakCount = 0;
    _lastDetectedCandidate = '';
    if (activeCameraFeature.value == CafeCameraActiveFeature.cupNameSpelling) {
      await closeCamera();
    }
  }

  // ── 3. AI BARISTA SOMMELIER (FITUR 3) ──────────────────────────────────────

  void filterSommelierByTag(String tag) {
    selectedSommelierTag.value = tag;
    switch (tag) {
      case 'Aman Lambung':
      case 'Rendah Asam':
        onTranscriptReceived('saya maag lambung asam lambung');
        break;
      case 'Karamel Dingin':
        onTranscriptReceived('pesan es karamel latte manis dingin');
        break;
      case 'Double Shot Aren':
        onTranscriptReceived('pesan kopi susu aren double shot ngantuk');
        break;
      case 'Matcha Sehat':
        onTranscriptReceived('pesan uji matcha latte tanpa kopi hijau');
        break;
      case 'Americano Diet':
        onTranscriptReceived('pesan americano hitam tanpa gula tanpa susu');
        break;
      default:
        activeRecommendation.value = _coffeeRecommenderService.recommendCoffee(
          'kopi susu oat',
        );
        break;
    }
  }

  void addRecommendedItemToTicket(CoffeeMenuItem item) {
    final slot = ParsedCafeOrderSlot(
      drinkId: item.id,
      drinkLabelKey: item.id,
      drinkNameId: item.nameId,
      drinkNameEn: item.nameEn,
      temperature: item.defaultTemperature,
      cupSize: OrderCupSize.medium,
      milkType: item.defaultMilk,
      sweetnessLevel: item.defaultSweetness,
      basePrice: item.basePrice,
      quantity: 1,
      dietaryAlerts: const [],
    );
    addItemToTicket(slot);
    _ttsService.speak(
      '${item.nameId} berhasil ditambahkan ke nota.',
      languageCode: 'id-ID',
    );
  }

  // ── 4. DUAL-MODE QUEUE PAGER (FITUR 4) ─────────────────────────────────────

  Future<void> callHearingCustomer() async {
    final ticket = currentTicket.value;
    final event = await _queuePagerService.callHearingCustomer(
      queueNumber: ticket.queueNumber,
      customerName: ticket.customerName,
      ttsServiceOverride: _ttsService,
    );
    lastQueueCallEvent.value = event;
    if (ticket.items.isNotEmpty && ticket.grandTotal > 0) {
      currentTicket.value = currentTicket.value.copyWith(
        status: OrderStatus.readyForPickup,
      );
    }
  }

  Future<void> callDeafCustomer() async {
    final ticket = currentTicket.value;
    final event = await _queuePagerService.callDeafCustomer(
      queueNumber: ticket.queueNumber,
      customerName: ticket.customerName,
    );
    lastQueueCallEvent.value = event;
    isDeafCallActive.value = true;
    if (ticket.items.isNotEmpty && ticket.grandTotal > 0) {
      currentTicket.value = currentTicket.value.copyWith(
        status: OrderStatus.readyForPickup,
      );
    }

    try {
      await HapticFeedback.vibrate();
    } catch (_) {}

    // Trigger Sign Video for "PESANAN SIAP DIAMBIL"
    _triggerSignVideo(event.signVideoKeyword);
  }

  void dismissDeafCall() {
    isDeafCallActive.value = false;
  }

  // ── 5. 1-TAP CASHIER QUICK DECK (FITUR 5) ──────────────────────────────────

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

    // Setup interactive replies on Customer Side
    switch (index) {
      case 0:
        activeCustomerQuickReplies.assignAll([
          'Dine-In (Minum Sini)',
          'Takeaway (Bawa Pulang)',
        ]);
        break;
      case 1:
        activeCustomerQuickReplies.assignAll([
          'Small (Kecil)',
          'Medium (Sedang)',
          'Large (Besar)',
        ]);
        break;
      case 2:
        activeCustomerQuickReplies.assignAll([
          'Normal Ice & Sugar',
          'Less Sugar (50%)',
          'No Sugar (0%)',
        ]);
        break;
      case 3:
        activeCustomerQuickReplies.clear();
        startCustomerNameSpelling();
        break;
      case 4:
        activeCustomerQuickReplies.assignAll(['Buka QRIS Sekarang']);
        setPaymentMethod(OrderPaymentMethod.qris);
        break;
      case 5:
        activeCustomerQuickReplies.assignAll(['Terima Kasih Barista!']);
        currentTicket.value = currentTicket.value.copyWith(
          status: OrderStatus.preparing,
        );
        break;
      default:
        activeCustomerQuickReplies.clear();
        break;
    }
  }

  void onCustomerSelectReply(String reply) {
    lastCustomerReply.value = reply;
    lastCustomerActionFeedback.value = 'Pilihan "$reply" terkirim ke Barista ✓';
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    // Synchronize active parsed slot if present
    if (activeParsedSlot.value != null) {
      if (reply.contains('Small') ||
          reply.contains('Medium') ||
          reply.contains('Large')) {
        final size = reply.contains('Small')
            ? OrderCupSize.small
            : (reply.contains('Large')
                  ? OrderCupSize.large
                  : OrderCupSize.medium);
        activeParsedSlot.value = activeParsedSlot.value!.copyWith(
          cupSize: size,
        );
      } else if (reply.contains('Sugar')) {
        final sweetness = reply.contains('No Sugar')
            ? OrderSweetnessLevel.noSugar0
            : (reply.contains('Less Sugar')
                  ? OrderSweetnessLevel.lessSweet50
                  : OrderSweetnessLevel.normal100);
        activeParsedSlot.value = activeParsedSlot.value!.copyWith(
          sweetnessLevel: sweetness,
        );
      }
    }

    if (reply.contains('Dine-In') || reply.contains('Takeaway')) {
      currentTicket.value = currentTicket.value.copyWith(customerNotes: reply);
      _ttsService.speak('Pilihan dicatat: $reply', languageCode: 'id-ID');
    } else if (reply.contains('Small') ||
        reply.contains('Medium') ||
        reply.contains('Large')) {
      final size = reply.contains('Small')
          ? OrderCupSize.small
          : (reply.contains('Large')
                ? OrderCupSize.large
                : OrderCupSize.medium);
      if (currentTicket.value.items.isNotEmpty) {
        final lastIdx = currentTicket.value.items.length - 1;
        final updatedItems = List<ParsedCafeOrderSlot>.from(
          currentTicket.value.items,
        );
        updatedItems[lastIdx] = updatedItems[lastIdx].copyWith(cupSize: size);
        currentTicket.value = currentTicket.value.copyWith(items: updatedItems);
      }
      _ttsService.speak('Ukuran $reply dicatat.', languageCode: 'id-ID');
    } else if (reply.contains('Sugar')) {
      final sweetness = reply.contains('No Sugar')
          ? OrderSweetnessLevel.noSugar0
          : (reply.contains('Less Sugar')
                ? OrderSweetnessLevel.lessSweet50
                : OrderSweetnessLevel.normal100);
      if (currentTicket.value.items.isNotEmpty) {
        final lastIdx = currentTicket.value.items.length - 1;
        final updatedItems = List<ParsedCafeOrderSlot>.from(
          currentTicket.value.items,
        );
        updatedItems[lastIdx] = updatedItems[lastIdx].copyWith(
          sweetnessLevel: sweetness,
        );
        currentTicket.value = currentTicket.value.copyWith(items: updatedItems);
      }
      _ttsService.speak('Takaran gula dicatat.', languageCode: 'id-ID');
    }
  }

  void _triggerSignVideo(String keyword, {int? sessionId}) {
    final signController = textToSignController;
    if (signController != null) {
      if (sessionId == null || sessionId == _playSessionId) {
        signController.selectedLanguage.value =
            activeSignModel == SignLanguageModel.sibi ? 'sibi' : 'bisindo';
        signController.searchSign(keyword, force: true);
      }
    }
  }

  // ── 6. DIETARY & ALLERGY GUARDRAILS (FITUR 6) ──────────────────────────────

  void substituteMilkInTicket(int itemIndex, OrderMilkType newMilk) {
    if (itemIndex >= 0 && itemIndex < currentTicket.value.items.length) {
      final item = currentTicket.value.items[itemIndex];
      final updatedAlerts = item.dietaryAlerts
          .where(
            (a) =>
                a.type != DietaryAlertType.lactoseIntolerant &&
                a.type != DietaryAlertType.dairyAllergy,
          )
          .toList();
      final updatedSlot = item.copyWith(
        milkType: newMilk,
        dietaryAlerts: updatedAlerts,
      );
      final list = List<ParsedCafeOrderSlot>.from(currentTicket.value.items);
      list[itemIndex] = updatedSlot;
      currentTicket.value = currentTicket.value.copyWith(items: list);
      _ttsService.speak(
        'Pilihan susu diganti ke ${newMilk.labelId}.',
        languageCode: 'id-ID',
      );
    }
  }

  // ── 7. BILL & CHANGE SYNC (FITUR 7) ────────────────────────────────────────

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

  void setExactCash() {
    setAmountPaid(currentTicket.value.grandTotal);
  }

  Future<void> processQrisPayment() async {
    isQrisProcessing.value = true;
    await Future.delayed(const Duration(milliseconds: 1200));
    isQrisProcessing.value = false;
    isOrderCompleted.value = true;
    final total = currentTicket.value.grandTotal;
    final completedTicket = currentTicket.value.copyWith(
      amountPaid: total,
      status: OrderStatus.preparing,
    );
    currentTicket.value = completedTicket;
    currentStage.value = CafeOrderStage.pickup;

    // Insert into active orders queue for barista/kitchen preparation
    _addOrUpdateQueueOrder(completedTicket);

    // Persist completed order to Supabase (offloads long-term data from local storage)
    final supabaseService = _supabaseCafePosService;
    if (supabaseService != null) {
      unawaited(supabaseService.saveOrder(completedTicket));
    }

    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    await _ttsService.speak(
      'Pembayaran QRIS sejumlah $total rupiah berhasil diverifikasi. Pesanan masuk antrean.',
      languageCode: 'id-ID',
    );
  }

  Future<void> completeCashPayment() async {
    final ticket = currentTicket.value;
    if (ticket.amountPaid < ticket.grandTotal) return;
    isOrderCompleted.value = true;
    final completedTicket = ticket.copyWith(status: OrderStatus.preparing);
    currentTicket.value = completedTicket;
    currentStage.value = CafeOrderStage.pickup;

    // Insert into active orders queue
    _addOrUpdateQueueOrder(completedTicket);

    // Persist completed order to Supabase
    final supabaseService = _supabaseCafePosService;
    if (supabaseService != null) {
      unawaited(supabaseService.saveOrder(completedTicket));
    }

    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    await _ttsService.speak(
      'Pembayaran tunai diterima, kembalian ${ticket.changeAmount} rupiah. Pesanan masuk antrean.',
      languageCode: 'id-ID',
    );
  }

  /// Adds or updates an order in the active orders queue
  void _addOrUpdateQueueOrder(CafeOrderTicket ticket) {
    final idx = activeOrdersQueue.indexWhere(
      (t) => t.orderId == ticket.orderId,
    );
    if (idx >= 0) {
      activeOrdersQueue[idx] = ticket;
    } else {
      activeOrdersQueue.insert(0, ticket);
    }
    _localDataSource.saveActiveQueue(activeOrdersQueue.toList());
  }

  /// Starts a fresh order for the next customer while maintaining previous orders in queue
  Future<void> startNextCustomerOrder() async {
    resetFlip();
    isCashierView.value = true;
    isOrderCompleted.value = false;
    isQrisProcessing.value = false;
    final nextQueue = _incrementQueue(currentTicket.value.queueNumber);
    final nextId = 'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}';
    currentTicket.value = CafeOrderTicket(
      orderId: nextId,
      queueNumber: nextQueue,
      customerName: '',
      customerNotes: '',
      items: const [],
      status: OrderStatus.draft,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 0,
      createdAt: DateTime.now(),
    );
    activeParsedSlot.value = null;
    clearLiveOrderSentence();
    _cancelSpellingTimers();
    isSpellingCustomerName.value = false;
    customerCupNameBuffer.value = '';
    spellingRemainingMs.value = 0;
    detectedSpellingLetter.value = '';
    letterHoldProgress.value = 0.0;
    _letterStreakCount = 0;
    _lastDetectedCandidate = '';
    activeCustomerQuickReplies.clear();
    lastCustomerReply.value = '';
    lastCustomerActionFeedback.value = '';
    activeRecommendation.value = null;
    isDeafCallActive.value = false;
    isChallengeCompleted.value = false;
    challengeProgress.value = 0.0;
    isMiniCameraModalOpen.value = false;
    showTrophyDialog.value = false;
    currentStage.value = CafeOrderStage.ordering;
    dairyAllergyAutoSwitched.value = false;
    dairyAllergyBannerMessage.value = '';
    await closeCamera();
    await _localDataSource.clearActiveTicket();
    await persistCurrentTicket();
  }

  /// Updates status of an order in the active queue
  void updateQueueOrderStatus(String orderId, OrderStatus newStatus) {
    final idx = activeOrdersQueue.indexWhere((t) => t.orderId == orderId);
    if (idx >= 0) {
      final updated = activeOrdersQueue[idx].copyWith(status: newStatus);
      activeOrdersQueue[idx] = updated;
      _localDataSource.saveActiveQueue(activeOrdersQueue.toList());
      _supabaseCafePosService?.saveOrder(updated);
    }
  }

  /// Marks a queued order as ready for customer pickup
  Future<void> markOrderReadyForPickup(CafeOrderTicket ticket) async {
    updateQueueOrderStatus(ticket.orderId, OrderStatus.readyForPickup);
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
    final customer = ticket.customerName.isEmpty
        ? 'Pelanggan'
        : ticket.customerName;
    await _ttsService.speak(
      'Pesanan nomor ${ticket.queueNumber} atas nama $customer sudah siap diambil.',
      languageCode: 'id-ID',
    );
  }

  /// Marks an order as handed over / completed
  Future<void> completeOrderPickup(String orderId) async {
    final idx = activeOrdersQueue.indexWhere((t) => t.orderId == orderId);
    if (idx >= 0) {
      final ticket = activeOrdersQueue[idx];
      updateQueueOrderStatus(orderId, OrderStatus.completed);
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
      await _ttsService.speak(
        'Pesanan ${ticket.queueNumber} telah diserahkan. Terima kasih!',
        languageCode: 'id-ID',
      );
    }
  }

  /// Removes an order from the active queue
  Future<void> removeOrderFromQueue(String orderId) async {
    activeOrdersQueue.removeWhere((t) => t.orderId == orderId);
    await _localDataSource.saveActiveQueue(activeOrdersQueue.toList());
  }

  /// Calls a customer from the queue via Voice TTS or Deaf Pager
  Future<void> callQueueCustomer(
    CafeOrderTicket ticket, {
    required bool isDeaf,
  }) async {
    if (isDeaf) {
      final event = await _queuePagerService.callDeafCustomer(
        queueNumber: ticket.queueNumber,
        customerName: ticket.customerName,
      );
      lastQueueCallEvent.value = event;
      isDeafCallActive.value = true;
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
      _triggerSignVideo(event.signVideoKeyword);
    } else {
      final event = await _queuePagerService.callHearingCustomer(
        queueNumber: ticket.queueNumber,
        customerName: ticket.customerName,
        ttsServiceOverride: _ttsService,
      );
      lastQueueCallEvent.value = event;
    }
  }

  /// Resets state for a new order and cleans up local active ticket storage to save local space
  Future<void> resetToNewOrder() async {
    await startNextCustomerOrder();
  }

  /// Realtime stream of active cloud orders (barista/kitchen display)
  Stream<List<CafeOrderTicket>>? streamCloudActiveOrders() =>
      _supabaseCafePosService?.streamActiveOrders();

  /// Fetches recent orders directly from Supabase without consuming local storage using Dart 3 switch expression.
  Future<List<CafeOrderTicket>> fetchCloudOrders({int limit = 50}) async {
    if (_supabaseCafePosService == null) return [];
    final res = await _supabaseCafePosService.fetchRecentOrders(limit: limit);
    return switch (res) {
      SupabaseSuccess(:final data) => data,
      SupabaseFailure() => [],
    };
  }

  Future<void> translateBillToSignAndSpeech() async {
    final total = currentTicket.value.grandTotal;
    final text = 'Total pembayaran $total rupiah.';
    await _ttsService.speak(text, languageCode: 'id-ID');
    _triggerSignVideo('BAYAR $total');
  }

  // ── 8. WAITING SIGN CHALLENGE (FITUR 8) ────────────────────────────────────

  void startWaitingChallenge({String signWord = 'TERIMA KASIH'}) {
    activeChallengeSign.value = signWord;
    challengeProgress.value = 0.0;
    isChallengeCompleted.value = false;
    showTrophyDialog.value = false;
  }

  void cycleNextChallengeWord() {
    final vocab = currentChallengeVocabulary;
    challengeWordIndex.value = (challengeWordIndex.value + 1) % vocab.length;
    activeChallengeSign.value = vocab[challengeWordIndex.value];
    challengeProgress.value = 0.0;
    isChallengeCompleted.value = false;
    showTrophyDialog.value = false;
  }

  void toggleMiniCameraModal(bool isOpen) {
    isMiniCameraModalOpen.value = isOpen;
  }

  void dismissTrophyDialog() {
    showTrophyDialog.value = false;
  }

  void dismissCustomerReply() {
    lastCustomerReply.value = '';
  }

  Future<void> updateChallengeProgress(double progress) async {
    challengeProgress.value = progress.clamp(0.0, 1.0);
    if (challengeProgress.value >= 1.0 && !isChallengeCompleted.value) {
      isChallengeCompleted.value = true;
      showTrophyDialog.value = true;
      try {
        final newStamps = await _localDataSource.addLoyaltyStamp();
        loyaltyStampsCount.value = newStamps;
        final supabaseService = _supabaseCafePosService;
        if (supabaseService != null) {
          unawaited(supabaseService.syncLoyaltyStamps('guest_user', newStamps));
        }
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
