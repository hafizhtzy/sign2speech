import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_menu_catalog_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester,
    Size size, {
    void Function(CoffeeMenuItem)? onSelect,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('id', 'ID'),
        home: Scaffold(
          body: CafeMenuCatalogSheet(onSelectItem: onSelect ?? (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders grid cards without overflow on compact phone (360x800)',
      (tester) async {
    await pumpSheet(tester, const Size(360, 800));
    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Oat Cappuccino'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
  });

  testWidgets('renders grid without overflow on tablet width (900x1200)',
      (tester) async {
    await pumpSheet(tester, const Size(900, 1200));
    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('quick add "+" button calls onSelectItem', (tester) async {
    CoffeeMenuItem? selected;
    await pumpSheet(
      tester,
      const Size(360, 800),
      onSelect: (item) => selected = item,
    );
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(selected, isNotNull);
  });
}
