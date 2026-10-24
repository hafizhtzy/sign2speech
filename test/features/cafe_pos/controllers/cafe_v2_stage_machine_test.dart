import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_counter_session.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';

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

  group('Master Prompt V2 - 3-Step State Machine & Stage Transitions', () {
    test('starts at idle stage and transitions correctly through 3 stages', () {
      final controller = Get.put(CafeCashierController());

      // 1. Initial stage is idle
      expect(controller.currentStage.value, equals(CafeOrderStage.idle));

      // 2. Start order -> ordering
      controller.goToStage(CafeOrderStage.ordering);
      expect(controller.currentStage.value, equals(CafeOrderStage.ordering));

      // 3. Move to naming stage
      controller.goToStage(CafeOrderStage.naming);
      expect(controller.currentStage.value, equals(CafeOrderStage.naming));

      // 4. Move to pickup stage
      controller.goToStage(CafeOrderStage.pickup);
      expect(controller.currentStage.value, equals(CafeOrderStage.pickup));

      // 5. Reset to idle
      controller.goToStage(CafeOrderStage.idle);
      expect(controller.currentStage.value, equals(CafeOrderStage.idle));
    });
  });

  group('Master Prompt V2 - PIN Protection & Tablet Mode Switching', () {
    test('requires correct PIN to authenticate staff mode', () {
      final controller = Get.put(CafeCashierController());

      expect(controller.staffPinAuthenticated.value, isFalse);

      // Wrong PIN fails
      final wrongResult = controller.verifyStaffPin('9999');
      expect(wrongResult, isFalse);
      expect(controller.staffPinAuthenticated.value, isFalse);

      // Correct default PIN ('0000') succeeds
      final correctResult = controller.verifyStaffPin('0000');
      expect(correctResult, isTrue);
      expect(controller.staffPinAuthenticated.value, isTrue);
    });

    test('switches between single tablet and paired dual tablet mode', () {
      final controller = Get.put(CafeCashierController());

      expect(controller.deviceMode.value, equals(CounterDeviceMode.singleTabletSwitch));

      controller.setDeviceMode(CounterDeviceMode.dualTabletLocked);
      expect(controller.deviceMode.value, equals(CounterDeviceMode.dualTabletLocked));

      controller.setDeviceMode(CounterDeviceMode.singleTabletSwitch);
      expect(controller.deviceMode.value, equals(CounterDeviceMode.singleTabletSwitch));
    });
  });

  group('Master Prompt V2 - Dairy Allergy Auto-Switch to Oat Milk', () {
    test('auto-switches freshDairy to oatMilk when dairy allergy is detected', () {
      final controller = Get.put(CafeCashierController());

      // Add item with fresh dairy
      const item = ParsedCafeOrderSlot(
        drinkId: 'latte',
        drinkLabelKey: 'cafe_drink_latte',
        drinkNameId: 'Caffe Latte',
        drinkNameEn: 'Caffe Latte',
        cupSize: OrderCupSize.medium,
        temperature: OrderTemperature.hot,
        milkType: OrderMilkType.freshDairy,
        basePrice: 28000,
      );
      controller.addItemToTicket(item);

      expect(controller.currentTicket.value.items.first.milkType, equals(OrderMilkType.freshDairy));
      expect(controller.dairyAllergyAutoSwitched.value, isFalse);

      // Simulate transcript with dairy allergy
      controller.onTranscriptReceived('saya alergi susu sapi jangan pakai susu biasa ya');

      // Check auto-switch
      expect(controller.currentTicket.value.items.first.milkType, equals(OrderMilkType.oatMilk));
      expect(controller.dairyAllergyAutoSwitched.value, isTrue);
      expect(controller.dairyAllergyBannerMessage.value, contains('Susu Oat'));
    });
  });

  group('Master Prompt V2 - Firestore Counter Session Data Model', () {
    test('serializes and deserializes CafeCounterSession correctly', () {
      final now = DateTime.now();
      final session = CafeCounterSession(
        counterId: 'KAFE-01',
        stage: CafeOrderStage.naming,
        deviceMode: CounterDeviceMode.dualTabletLocked,
        cashierTabletId: 'cashier-01',
        customerTabletId: 'customer-01',
        updatedAt: now,
      );

      final map = session.toMap();
      expect(map['counterId'], equals('KAFE-01'));
      expect(map['stage'], equals('naming'));
      expect(map['deviceMode'], equals('dualTabletLocked'));
      expect(map['cashierTabletId'], equals('cashier-01'));
      expect(map['customerTabletId'], equals('customer-01'));

      final restored = CafeCounterSession.fromMap(map);
      expect(restored.counterId, equals('KAFE-01'));
      expect(restored.stage, equals(CafeOrderStage.naming));
      expect(restored.deviceMode, equals(CounterDeviceMode.dualTabletLocked));
      expect(restored.cashierTabletId, equals('cashier-01'));
      expect(restored.customerTabletId, equals('customer-01'));
    });
  });
}
