import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/cafe_pos_local_data_source.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_customization_draft.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/screens/coffee_detail_screen.dart';

Widget _buildTestApp(Widget child) {
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('id', 'ID'),
    fallbackLocale: const Locale('id', 'ID'),
    getPages: [
      GetPage(name: AppRoutes.coffeeDetail, page: () => child),
      GetPage(
        name: AppRoutes.cafeCashierCounter,
        page: () => const Scaffold(body: Text('Cashier Counter Mock')),
      ),
    ],
    home: child,
  );
}


void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('CoffeeDetailScreen Widget & Layout Tests', () {
    testWidgets('renders all sections and localized dropdowns without layout overflow',
        (tester) async {
      // Set compact screen size (e.g. 375x700) to stress test layout & scrolling
      tester.view.physicalSize = const Size(375, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = CoffeeMenuItem.standardCatalog.first; // Low-Acid Oat Latte, basePrice 32000

      await tester.pumpWidget(
        _buildTestApp(CoffeeDetailScreen(menuItem: item)),
      );
      await tester.pumpAndSettle();

      // Pinned curved header
      expect(find.text('Detail Racikan Kopi'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Temperature selector buttons
      expect(find.text('ICED (DINGIN)'), findsOneWidget);
      expect(find.text('HOT (HANGAT)'), findsOneWidget);

      // Cup size selector
      expect(find.text('UKURAN GELAS (CUP SIZE)'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);

      // Customization dropdowns - must NOT display raw enum uppercase like NOSUGAR0
      expect(find.text('NOSUGAR0'), findsNothing);
      expect(find.text('NORMAL100'), findsNothing);
      expect(find.text('LESSSWEET50'), findsNothing);

      // Check initial price: Medium (+0) + Oat Milk (+6000) on 32000 = 38000
      expect(find.text(formatRupiah(38000)), findsOneWidget);

      // Toggle Extra Shot (+5000)
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Price should now be 38000 + 5000 = 43000
      expect(find.text(formatRupiah(43000)), findsOneWidget);

      // Toggle Large cup size (+6000)
      final largeFinder = find.text('Large');
      await tester.ensureVisible(largeFinder);
      await tester.pumpAndSettle();
      await tester.tap(largeFinder);
      await tester.pumpAndSettle();

      // Price should now be 32000 (base) + 6000 (oat) + 5000 (extra shot) + 6000 (large) = 49000
      expect(find.text(formatRupiah(49000)), findsOneWidget);

      // Verify bottom bar button
      expect(find.text('Kirim ke Meja Kasir'), findsOneWidget);
      expect(find.text('>>>>'), findsOneWidget);
    });

    testWidgets('adapts smoothly to tablet / large screen constraints', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final item = CoffeeMenuItem.standardCatalog[1]; // Aren Cinnamon Cold Brew

      await tester.pumpWidget(
        _buildTestApp(CoffeeDetailScreen(menuItem: item)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Racikan Kopi'), findsOneWidget);
      expect(find.text(item.nameId), findsWidgets);
    });

    testWidgets('restores customized options from local storage draft', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = CafePosLocalDataSource(prefs: prefs);
      Get.put<CafePosLocalDataSource>(localDataSource);

      final item = CoffeeMenuItem.standardCatalog.first; // low_acid_oat_latte

      // Pre-save a customized draft for this item
      final draft = CoffeeCustomizationDraft(
        drinkId: item.id,
        temperature: OrderTemperature.hot,
        cupSize: OrderCupSize.large,
        milkType: OrderMilkType.soyMilk,
        sweetness: OrderSweetnessLevel.noSugar0,
        extraShot: true,
        quantity: 1,
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveCustomizationDraft(draft);

      await tester.pumpWidget(
        _buildTestApp(CoffeeDetailScreen(menuItem: item)),
      );
      await tester.pumpAndSettle();

      // Price computation: 32000 base + 6000 (large) + 5000 (soy) + 5000 (extra shot) = 48000
      expect(find.text(formatRupiah(48000)), findsOneWidget);

      // Verify restored draft text appears in the sentence preview bar
      expect(find.textContaining('Panas'), findsWidgets);
      expect(find.textContaining('Extra Shot Espresso'), findsWidgets);
    });

    testWidgets('reset button in header resets customization back to standard recipe',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = CafePosLocalDataSource(prefs: prefs);
      Get.put<CafePosLocalDataSource>(localDataSource);

      final item = CoffeeMenuItem.standardCatalog.first;

      await tester.pumpWidget(
        _buildTestApp(CoffeeDetailScreen(menuItem: item)),
      );
      await tester.pumpAndSettle();

      // Toggle Extra Shot
      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(find.text(formatRupiah(43000)), findsOneWidget);

      // Tap Reset button in header
      final resetBtnFinder = find.byIcon(Icons.restart_alt_rounded);
      expect(resetBtnFinder, findsOneWidget);
      await tester.tap(resetBtnFinder);
      await tester.pumpAndSettle();

      // Price should reset back to 38000
      expect(find.text(formatRupiah(38000)), findsOneWidget);

      // Draft in storage should be cleared
      final draft = await localDataSource.loadCustomizationDraft(item.id);
      expect(draft, isNull);
    });

    testWidgets('send to cashier adds item to ticket and clears draft', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final localDataSource = CafePosLocalDataSource(prefs: prefs);
      Get.put<CafePosLocalDataSource>(localDataSource);

      final cashierController = CafeCashierController(localDataSource: localDataSource);
      Get.put<CafeCashierController>(cashierController);

      final item = CoffeeMenuItem.standardCatalog.first;

      await tester.pumpWidget(
        _buildTestApp(CoffeeDetailScreen(menuItem: item)),
      );
      await tester.pumpAndSettle();

      // Tap Send to Cashier
      final sendBtn = find.text('Kirim ke Meja Kasir');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Verify item was added to cashier ticket
      expect(cashierController.currentTicket.value.items.length, equals(1));
      expect(cashierController.currentTicket.value.items.first.drinkId, equals(item.id));

      // Verify draft in storage is cleared
      final draft = await localDataSource.loadCustomizationDraft(item.id);
      expect(draft, isNull);
    });
  });
}

