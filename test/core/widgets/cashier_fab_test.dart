import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/widgets/cashier_fab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    AppTranslations.ensureLoaded();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CashierFab navigates directly to cafeCashierCounter when tapped',
      (tester) async {
    String? navigatedRoute;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('id', 'ID'),
        initialRoute: AppRoutes.mainShell,
        getPages: [
          GetPage(
            name: AppRoutes.mainShell,
            page: () => const Scaffold(
              floatingActionButton: CashierFab(extended: true),
            ),
          ),
          GetPage(
            name: AppRoutes.cafeCashierCounter,
            page: () => const Scaffold(body: Text('Cafe Cashier Counter Page')),
          ),
        ],
        routingCallback: (routing) {
          if (routing != null) {
            navigatedRoute = routing.current;
          }
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CashierFab), findsOneWidget);
    expect(find.text(AppStrings.cashierAssistantTitle.tr), findsOneWidget);

    // Tap FAB
    await tester.tap(find.byType(CashierFab));
    await tester.pumpAndSettle();

    // Verify it navigated directly to cashier counter screen
    expect(find.text('Cafe Cashier Counter Page'), findsOneWidget);
    expect(navigatedRoute, equals(AppRoutes.cafeCashierCounter));
  });

  testWidgets('CashierFab compact mode also navigates directly to cafeCashierCounter',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('id', 'ID'),
        initialRoute: AppRoutes.mainShell,
        getPages: [
          GetPage(
            name: AppRoutes.mainShell,
            page: () => const Scaffold(
              floatingActionButton: CashierFab(extended: false),
            ),
          ),
          GetPage(
            name: AppRoutes.cafeCashierCounter,
            page: () => const Scaffold(body: Text('Target Cashier Page')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Target Cashier Page'), findsOneWidget);
  });
}
