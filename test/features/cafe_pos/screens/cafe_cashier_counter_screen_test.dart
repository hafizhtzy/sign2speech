import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/bindings/cafe_pos_binding.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/screens/cafe_cashier_counter_screen.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_cashier_sign_video_card.dart';
import 'package:speech2sign/features/cafe_pos/widgets/customer_voice_order_card.dart';

void main() {
  testWidgets('Test CafeCashierCounterScreen pump', (tester) async {
    Get.testMode = true;
    CafePosBinding().dependencies();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('id', 'ID'),
        home: const CafeCashierCounterScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Meja Kasir & Barista AI'), findsWidgets);
    expect(find.text('Mulai Terima Pesanan'), findsOneWidget);

    // Tap Mulai Terima Pesanan to enter ordering stage
    await tester.tap(find.text('Mulai Terima Pesanan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Cashier side displays CafeCashierSignVideoCard (Real-time Video Isyarat)
    expect(find.byType(CafeCashierSignVideoCard), findsOneWidget);
    // Cashier side displays docked stage advance button in bottomNavigationBar
    expect(find.byKey(const Key('cafe_stage_advance_button')), findsOneWidget);

    // Switch to Sisi Pembeli (Customer View)
    final cashierController = Get.find<CafeCashierController>();
    cashierController.toggleDualView();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Customer side displays CustomerVoiceOrderCard and Menu Catalog banner
    expect(find.byType(CustomerVoiceOrderCard), findsOneWidget);
    expect(find.text('Katalog Menu Lengkap'), findsOneWidget);
    expect(find.text('Buka Menu'), findsOneWidget);
  });
}

