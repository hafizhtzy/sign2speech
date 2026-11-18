import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_cashier_control_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    AppTranslations.ensureLoaded();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CafeCashierControlSheet renders 1-tablet and 2-tablet mode options',
      (tester) async {
    final controller = Get.put(CafeCashierController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('id', 'ID'),
        home: Scaffold(
          body: CafeCashierControlSheet(controller: controller),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title & Device Mode Section
    expect(find.text(AppStrings.cafeDeviceModeTitle.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeMode1Tablet.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeMode2Tablet.tr), findsOneWidget);

    // Initial state is 1-tablet: check presence of flip button
    expect(find.text('Putar 180°'), findsOneWidget);

    // Tap Putar 180° button inside control sheet
    await tester.ensureVisible(find.text('Putar 180°'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Putar 180°'));
    await tester.pump();
    expect(controller.isFlipped.value, isTrue);

    // Tap 2-Tablet mode
    await tester.ensureVisible(find.text(AppStrings.cafeMode2Tablet.tr));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cafeMode2Tablet.tr));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.deviceMode.value, equals(CounterDeviceMode.dualTabletLocked));
    expect(controller.isFlipped.value, isFalse); // auto reset flip

    // Skenario 1: Tablet 2 (Pembeli) - Belum login PIN Staf
    // Menampilkan UI Layar Hadap Pelanggan dengan tombol Hubungkan Ruang
    expect(find.text(AppStrings.cafeDualCustomerTitle.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeJoinRoom.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeCreateRoom.tr), findsNothing);

    // Skenario 2: Tablet 1 (Kasir) - Staf memasukkan PIN
    controller.verifyStaffPin('0000');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Menampilkan UI Tablet Kasir (Host Ruangan) dengan kode ruangan & tombol Buat Ruang
    expect(find.text(AppStrings.cafeDualStaffHostTitle.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeRoomCodeLabel.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeCreateRoom.tr), findsOneWidget);
    expect(find.text(AppStrings.cafeJoinRoom.tr), findsNothing);
  });
}
