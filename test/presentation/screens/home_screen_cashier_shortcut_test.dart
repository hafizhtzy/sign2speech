import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/auth/controllers/auth_controller.dart';
import 'package:speech2sign/core/auth/models/app_user_role.dart';
import 'package:speech2sign/core/auth/models/user_profile.dart';
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

  testWidgets('HomeScreen displays Cashier card for CASHIER role and navigates to cafeCashierCounter',
      (tester) async {
    String? navigatedRoute;
    Get.put(
      AuthController(
        initialProfileForTest: UserProfile(
          id: 'cashier-1',
          email: 'kasir@sign2speech.id',
          fullName: 'Kasir Kafe',
          role: AppUserRole.cashier,
          status: AccountStatus.active,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ),
    );

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

    expect(find.text(AppStrings.homeCashierShortcuts.tr), findsNothing);
    expect(find.text(AppStrings.cashierAssistantTitle.tr), findsOneWidget);
    await tester.tap(find.text(AppStrings.cashierAssistantTitle.tr));
    await tester.pumpAndSettle();

    expect(find.text('Meja Kasir Target'), findsOneWidget);
    expect(navigatedRoute, equals(AppRoutes.cafeCashierCounter));
  });

  testWidgets('HomeScreen displays Order card when unauthenticated (guest) and navigates to login',
      (tester) async {
    Get.put(AuthController());

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
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('Login Target')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.customerOrderCardTitle.tr), findsOneWidget);
    expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_order_or_cashier_card')));
    await tester.pumpAndSettle();

    expect(find.text('Login Target'), findsOneWidget);
  });
}
