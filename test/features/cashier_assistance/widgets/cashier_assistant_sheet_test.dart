import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cashier_assistance/widgets/cashier_assistant_sheet.dart';

Widget _buildTestApp() {
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('id', 'ID'),
    home: const Scaffold(
      body: Center(
        child: CashierAssistantSheet(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  group('CashierAssistantSheet Widget & Layout Tests', () {
    testWidgets('renders all tabs in short landscape (914x412) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verify Tab 1 (Presets) is rendered
      expect(find.byType(CashierAssistantSheet), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch to Tab 2 (Price Pad)
      final pricePadTab = find.byType(Tab).at(1);
      await tester.tap(pricePadTab, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Tab 3 (Customer Facing Display)
      final customerTab = find.byType(Tab).at(2);
      await tester.tap(customerTab, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify flip button toggles rotation state without overflow
      final flipButton = find.text('Balik 180°');
      if (flipButton.evaluate().isNotEmpty) {
        await tester.tap(flipButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('renders properly in portrait (412x915) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(CashierAssistantSheet), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch to Customer Display in portrait
      final customerTab = find.byType(Tab).at(2);
      await tester.tap(customerTab, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
