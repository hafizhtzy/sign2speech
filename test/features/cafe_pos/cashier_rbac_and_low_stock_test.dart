import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/auth/controllers/auth_controller.dart';
import 'package:speech2sign/core/auth/models/app_user_role.dart';
import 'package:speech2sign/core/auth/models/user_profile.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/cafe_pos/screens/coffee_detail_screen.dart';
import 'package:speech2sign/features/cafe_pos/widgets/coffee_composition_circle.dart';
import 'package:speech2sign/features/cafe_pos/widgets/report_low_stock_dialog.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    AppTranslations.ensureLoaded();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Cashier RBAC Restrictions & Low Stock Report Dialog', () {
    testWidgets('CoffeeDetailScreen hides photo edit callback for CASHIER and CUSTOMER, allows for ADMIN', (tester) async {
      final cashierProfile = UserProfile(
        id: 'cash-1',
        email: 'cashier@cafe.id',
        fullName: 'Kasir Kafe',
        role: AppUserRole.cashier,
        status: AccountStatus.active,
        createdAt: DateTime.utc(2026, 11, 18),
        updatedAt: DateTime.utc(2026, 11, 18),
      );
      final authCtrl = Get.put(
        AuthController(initialProfileForTest: cashierProfile),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: CoffeeDetailScreen(
            menuItem: CoffeeMenuItem.standardCatalog.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      var circle = tester.widget<CoffeeCompositionCircle>(
        find.byType(CoffeeCompositionCircle),
      );
      expect(circle.onEditPhoto, isNull);

      // Promote to ADMIN and verify photo editing is unlocked
      authCtrl.applyProfileUpdate(
        cashierProfile.copyWith(role: AppUserRole.admin),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: CoffeeDetailScreen(
            key: const ValueKey('admin_view'),
            menuItem: CoffeeMenuItem.standardCatalog.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      circle = tester.widget<CoffeeCompositionCircle>(
        find.byType(CoffeeCompositionCircle),
      );
      expect(circle.onEditPhoto, isNotNull);
    });

    testWidgets('ReportLowStockDialog renders read-only stock notice and product selector', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: ReportLowStockDialog(
              catalog: CoffeeMenuItem.standardCatalog,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.cashierStockReadOnlyNotice.tr),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('low_stock_product_dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('low_stock_note_field')), findsOneWidget);
      expect(
        find.byKey(const Key('submit_low_stock_report_btn')),
        findsOneWidget,
      );
    });
  });
}
