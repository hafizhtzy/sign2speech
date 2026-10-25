import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_order_ticket.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';
import 'package:speech2sign/features/cafe_pos/screens/cafe_order_queue_screen.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppTranslations.ensureLoaded();
    mockTts = MockTtsService();
    controller = CafeCashierController(
      ttsService: mockTts,
    );
    Get.put<CafeCashierController>(controller);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('id', 'ID'),
      fallbackLocale: const Locale('id', 'ID'),
      home: CafeOrderQueueScreen(controller: controller),
    );
  }

  testWidgets('displays empty state when activeOrdersQueue is empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cafeOrderQueueEmpty.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeStartNextOrder.tr), findsWidgets);
  });

  testWidgets('renders order cards in queue and allows marking ready & completed', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Add dummy orders to queue
    final order1 = CafeOrderTicket(
      orderId: 'ORD-101',
      queueNumber: 'A-101',
      customerName: 'Budi',
      items: const [
        ParsedCafeOrderSlot(
          drinkId: 'kopi_susu_aren',
          drinkLabelKey: 'kopi_susu_aren',
          drinkNameId: 'Kopi Susu Aren',
          drinkNameEn: 'Palm Sugar Coffee Milk',
          quantity: 2,
          basePrice: 20000,
        ),
      ],
      status: OrderStatus.preparing,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 40000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    );

    final order2 = CafeOrderTicket(
      orderId: 'ORD-102',
      queueNumber: 'A-102',
      customerName: 'Siti',
      items: const [
        ParsedCafeOrderSlot(
          drinkId: 'iced_caramel_latte',
          drinkLabelKey: 'iced_caramel_latte',
          drinkNameId: 'Es Karamel Latte',
          drinkNameEn: 'Iced Caramel Latte',
          quantity: 1,
          basePrice: 28000,
        ),
      ],
      status: OrderStatus.readyForPickup,
      paymentMethod: OrderPaymentMethod.cash,
      amountPaid: 30000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    );

    controller.activeOrdersQueue.assignAll([order1, order2]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify order numbers are displayed
    expect(find.text('A-101'), findsOneWidget);
    expect(find.text('A-102'), findsOneWidget);
    expect(find.text('Atas Nama: Budi'), findsOneWidget);
    expect(find.text('Atas Nama: Siti'), findsOneWidget);
    expect(find.text('Kopi Susu Aren'), findsOneWidget);
    expect(find.text('Es Karamel Latte'), findsOneWidget);

    // Verify action buttons exist
    expect(find.text(AppStrings.cafeMarkReady.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeMarkCompleted.tr), findsOneWidget);

    // Tap "Tandai Siap" on order1
    await tester.tap(find.text(AppStrings.cafeMarkReady.tr));
    await tester.pumpAndSettle();

    expect(controller.activeOrdersQueue.first.status, equals(OrderStatus.readyForPickup));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Selesai / Serahkan" on order2 (last button)
    await tester.tap(find.text(AppStrings.cafeMarkCompleted.tr).last);
    await tester.pumpAndSettle();

    expect(controller.activeOrdersQueue.last.status, equals(OrderStatus.completed));
  });

  testWidgets('filters orders by status tab correctly', (tester) async {
    final orderPreparing = CafeOrderTicket(
      orderId: 'ORD-201',
      queueNumber: 'A-201',
      customerName: 'Andi',
      items: const [],
      status: OrderStatus.preparing,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 20000,
      createdAt: DateTime.now(),
    );

    final orderReady = CafeOrderTicket(
      orderId: 'ORD-202',
      queueNumber: 'A-202',
      customerName: 'Dewi',
      items: const [],
      status: OrderStatus.readyForPickup,
      paymentMethod: OrderPaymentMethod.qris,
      amountPaid: 25000,
      createdAt: DateTime.now(),
    );

    controller.activeOrdersQueue.assignAll([orderPreparing, orderReady]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Both visible under "Semua"
    expect(find.text('A-201'), findsOneWidget);
    expect(find.text('A-202'), findsOneWidget);

    // Tap "Sedang Dibuat" filter
    await tester.tap(find.widgetWithText(InkWell, AppStrings.cafeFilterPreparing.tr));
    await tester.pumpAndSettle();

    expect(find.text('A-201'), findsOneWidget);
    expect(find.text('A-202'), findsNothing);

    // Tap "Siap Diambil" filter
    await tester.tap(find.widgetWithText(InkWell, AppStrings.cafeFilterReady.tr));
    await tester.pumpAndSettle();

    expect(find.text('A-201'), findsNothing);
    expect(find.text('A-202'), findsOneWidget);
  });
}
