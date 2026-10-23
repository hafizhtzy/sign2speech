import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/bindings/cafe_pos_binding.dart';
import 'package:speech2sign/features/cafe_pos/screens/cafe_cashier_counter_screen.dart';

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

    expect(find.text('Live Kamera & Suara Pesanan'), findsOneWidget);
    expect(find.text('Meja Kasir & Barista AI'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsWidgets);
  });
}

