import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/auth/controllers/auth_controller.dart';
import 'package:speech2sign/core/auth/middlewares/role_guard_middleware.dart';
import 'package:speech2sign/core/auth/models/app_user_role.dart';
import 'package:speech2sign/core/auth/models/user_profile.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/widgets/cashier_fab.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/customer/controllers/customer_order_controller.dart';
import 'package:speech2sign/features/customer/domain/models/qris_payment_record.dart';
import 'package:speech2sign/features/customer/screens/customer_checkout_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    AppTranslations.ensureLoaded();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Mandatory Stock Opname & Available Stock Enforcement', () {
    test('rejects uninitialized legacy product until Admin performs Stock Opname', () {
      const uninitializedItem = CoffeeMenuItem(
        id: 'kopi_lama',
        nameId: 'Kopi Lama Belum Opname',
        nameEn: 'Legacy Coffee',
        descriptionId: 'Stok belum diinisialisasi',
        descriptionEn: 'Uninitialized stock',
        basePrice: 25000,
        isStockInitialized: false,
        stockOnHand: 0,
        stockReserved: 0,
      );

      expect(uninitializedItem.availableStock, 0);
      expect(uninitializedItem.canBeOrderedWithControlledStock, isFalse);

      final ctrl = CustomerOrderController(
        initialCatalogForTest: const [uninitializedItem],
      );
      expect(ctrl.addToCart(uninitializedItem), isFalse);
      expect(ctrl.errorMessage.value, contains('belum diopname'));
      expect(ctrl.cartItems, isEmpty);
    });

    test('calculates availableStock = stockOnHand - stockReserved and prevents overselling', () {
      const initializedItem = CoffeeMenuItem(
        id: 'oat_latte',
        nameId: 'Oat Latte',
        nameEn: 'Oat Latte',
        descriptionId: 'Kopi susu oat',
        descriptionEn: 'Oat milk latte',
        basePrice: 30000,
        isStockInitialized: true,
        stockOnHand: 5,
        stockReserved: 3, // availableStock = 2
      );

      expect(initializedItem.availableStock, 2);
      expect(initializedItem.canBeOrderedWithControlledStock, isTrue);

      final ctrl = CustomerOrderController(
        initialCatalogForTest: const [initializedItem],
      );

      expect(ctrl.addToCart(initializedItem, quantity: 2), isTrue);
      expect(ctrl.cartTotalUnits, 2);

      // Attempting to add a 3rd unit when availableStock == 2 must be rejected
      expect(ctrl.addToCart(initializedItem, quantity: 1), isFalse);
      expect(ctrl.cartTotalUnits, 2);
    });
  });

  group('Midtrans Core API QRIS Record & Actions Parsing', () {
    test('resolves QR code URL from Midtrans actions array without assuming qr_string exists', () {
      final record = QrisPaymentRecord.fromPostgresMap({
        'id': 'pay-001',
        'order_id': 'ORD-1001',
        'provider': 'midtrans',
        'is_simulation': false,
        'gross_amount': 33000,
        'status': 'pending',
        'qr_string': null,
        'qr_code_url': null,
        'qris_actions': [
          {
            'name': 'generate-qr-code-v2',
            'method': 'GET',
            'url': 'https://api.sandbox.midtrans.com/v2/qris/qr-code-v2',
          },
        ],
      });

      expect(record.hasQrString, isFalse);
      expect(record.isSimulation, isFalse);
      expect(
        record.resolvedQrImageUrl,
        'https://api.sandbox.midtrans.com/v2/qris/qr-code-v2',
      );
    });
  });

  group('CustomerCheckoutScreen Widget Verification', () {
    testWidgets('disables order button for uninitialized stock item and enables for stock-initialized item', (tester) async {
      const uninitItem = CoffeeMenuItem(
        id: 'item_uninit',
        nameId: 'Americano Belum Opname',
        nameEn: 'Americano Uninit',
        descriptionId: 'Belum opname',
        descriptionEn: 'Uninit',
        basePrice: 20000,
        isStockInitialized: false,
      );
      const readyItem = CoffeeMenuItem(
        id: 'item_ready',
        nameId: 'Matcha Siap Pesan',
        nameEn: 'Matcha Ready',
        descriptionId: 'Stok siap',
        descriptionEn: 'Ready',
        basePrice: 28000,
        isStockInitialized: true,
        stockOnHand: 10,
        stockReserved: 2,
      );

      Get.put(
        CustomerOrderController(
          initialCatalogForTest: const [uninitItem, readyItem],
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const CustomerCheckoutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final uninitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('add_to_cart_item_uninit')),
      );
      final readyBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('add_to_cart_item_ready')),
      );

      expect(uninitBtn.onPressed, isNull);
      expect(readyBtn.onPressed, isNotNull);

      // Verify Table Seat mode & Quick Table Chips
      expect(find.byKey(const Key('customer_table_number_input')), findsOneWidget);
      expect(find.byKey(const Key('quick_table_chip_Meja 03')), findsOneWidget);

      await tester.tap(find.byKey(const Key('quick_table_chip_Meja 03')));
      await tester.pumpAndSettle();
      expect(
        Get.find<CustomerOrderController>().selectedTableNumber.value,
        'Meja 03',
      );

      // Switch to Counter Tablet Pairing Mode
      await tester.tap(find.byKey(const Key('mode_counter_tablet_pairing_tab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer_pairing_code_input')), findsOneWidget);
      expect(find.byKey(const Key('customer_pair_cashier_btn')), findsOneWidget);
    });

    test('RoleGuardMiddleware redirects unpaired CUSTOMER to customerCheckout and allows paired CUSTOMER counter tablet', () {
      Get.put(
        AuthController(
          initialProfileForTest: UserProfile(
            id: 'cust-1',
            email: 'pelanggan@sign2speech.id',
            fullName: 'Pelanggan Kafe',
            role: AppUserRole.customer,
            status: AccountStatus.active,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      final cafeCtrl = Get.put(CafeCashierController());

      final guard = RoleGuardMiddleware(
        allowedRoles: const [AppUserRole.cashier],
        allowPairedCustomerCounterTablet: true,
      );

      // Unpaired customer -> redirected to customerCheckout ('Order' screen)
      expect(cafeCtrl.isPairedCustomerSession.value, isFalse);
      final redirectUnpaired = guard.redirect(AppRoutes.cafeCashierCounter);
      expect(redirectUnpaired?.name, AppRoutes.customerCheckout);

      // Paired customer tablet -> allowed to open Sisi Pembeli on cafeCashierCounter
      cafeCtrl.isPairedCustomerSession.value = true;
      final redirectPaired = guard.redirect(AppRoutes.cafeCashierCounter);
      expect(redirectPaired, isNull);
    });

    testWidgets('CashierFab shows Order icon for CUSTOMER and opens CustomerCheckoutScreen on tap', (tester) async {
      Get.put(
        AuthController(
          initialProfileForTest: UserProfile(
            id: 'cust-2',
            email: 'customer2@sign2speech.id',
            fullName: 'Pelanggan Meja',
            role: AppUserRole.customer,
            status: AccountStatus.active,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      Get.put(CustomerOrderController(initialCatalogForTest: const []));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const Scaffold(
            floatingActionButton: CashierFab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(CustomerCheckoutScreen), findsOneWidget);
    });
  });
}
