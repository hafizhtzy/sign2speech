import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/auth/controllers/auth_controller.dart';
import 'package:speech2sign/core/auth/models/app_user_role.dart';
import 'package:speech2sign/core/auth/models/user_profile.dart';
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

  testWidgets('CashierFab shows Cashier label/icon for CASHIER and navigates to cafeCashierCounter',
      (tester) async {
    String? navigatedRoute;
    Get.put(
      AuthController(
        initialProfileForTest: UserProfile(
          id: 'cashier-1',
          email: 'kasir@sign2speech.id',
          fullName: 'Kasir Utama',
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
    expect(find.byIcon(Icons.point_of_sale_rounded), findsOneWidget);

    await tester.tap(find.byType(CashierFab));
    await tester.pumpAndSettle();

    expect(find.text('Cafe Cashier Counter Page'), findsOneWidget);
    expect(navigatedRoute, equals(AppRoutes.cafeCashierCounter));
  });

  testWidgets('CashierFab shows Order label/icon when unauthenticated and routes to login',
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
            page: () => const Scaffold(
              floatingActionButton: CashierFab(extended: true),
            ),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('Target Login Page')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.customerOrderCardTitle.tr), findsOneWidget);
    expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);

    await tester.tap(find.byType(CashierFab));
    await tester.pumpAndSettle();

    expect(find.text('Target Login Page'), findsOneWidget);
  });
}
