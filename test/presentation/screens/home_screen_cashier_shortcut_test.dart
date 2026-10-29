import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/history/controllers/history_controller.dart';
import 'package:speech2sign/features/history/services/history_store.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/presentation/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    AppTranslations.ensureLoaded();
    Get.put(SettingsController());
    Get.put(HistoryController(historyStore: HistoryStore()));
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('HomeScreen does not display removed quick chips and navigates to cafeCashierCounter',
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
            page: () => const HomeScreen(),
          ),
          GetPage(
            name: AppRoutes.cafeCashierCounter,
            page: () => const Scaffold(body: Text('Meja Kasir Target')),
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

    // Verify quick chips section was removed
    expect(find.text(AppStrings.homeCashierShortcuts.tr), findsNothing);
    expect(find.text('☕ Pesan Kopi'), findsNothing);
    expect(find.text('🧊 Less Ice'), findsNothing);

    // Verify Cashier Assistant Card exists and can be tapped
    expect(find.text(AppStrings.cashierAssistantTitle.tr), findsOneWidget);
    await tester.tap(find.text(AppStrings.cashierAssistantTitle.tr));
    await tester.pumpAndSettle();

    expect(find.text('Meja Kasir Target'), findsOneWidget);
    expect(navigatedRoute, equals(AppRoutes.cafeCashierCounter));
  });
}
