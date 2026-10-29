import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/controllers/cafe_cashier_controller.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';

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

  group('Cafe Cashier 180° Flip & Device Mode Sync Tests', () {
    test('isFlipped defaults to false and toggleFlip flips state', () {
      final controller = Get.put(CafeCashierController());

      expect(controller.isFlipped.value, isFalse);

      controller.toggleFlip();
      expect(controller.isFlipped.value, isTrue);

      controller.toggleFlip();
      expect(controller.isFlipped.value, isFalse);
    });

    test('resetFlip always sets isFlipped to false', () {
      final controller = Get.put(CafeCashierController());

      controller.toggleFlip();
      expect(controller.isFlipped.value, isTrue);

      controller.resetFlip();
      expect(controller.isFlipped.value, isFalse);
    });

    test('switching to dualTabletLocked automatically resets flip', () async {
      final controller = Get.put(CafeCashierController());

      controller.toggleFlip();
      expect(controller.isFlipped.value, isTrue);

      await controller.setDeviceMode(CounterDeviceMode.dualTabletLocked);
      expect(controller.deviceMode.value, equals(CounterDeviceMode.dualTabletLocked));
      expect(controller.isFlipped.value, isFalse);
    });

    test('createRoomSession generates room code and sets dual tablet mode', () async {
      final controller = Get.put(CafeCashierController());

      final roomCode = await controller.createRoomSession();
      expect(roomCode, startsWith('KAFE-'));
      expect(controller.counterId.value, equals(roomCode));
      expect(controller.deviceMode.value, equals(CounterDeviceMode.dualTabletLocked));
    });

    test('createRoomSession with custom code sets that exact code', () async {
      final controller = Get.put(CafeCashierController());

      final roomCode = await controller.createRoomSession('BARISTA-09');
      expect(roomCode, equals('BARISTA-09'));
      expect(controller.counterId.value, equals('BARISTA-09'));
      expect(controller.deviceMode.value, equals(CounterDeviceMode.dualTabletLocked));
    });

    test('joinRoomSession joins specified room code and activates dual tablet stream', () async {
      final controller = Get.put(CafeCashierController());

      await controller.joinRoomSession(' meja-03 ');
      expect(controller.counterId.value, equals('MEJA-03'));
      expect(controller.deviceMode.value, equals(CounterDeviceMode.dualTabletLocked));
      expect(controller.isCashierView.value, isFalse);
    });

    test('Tablet 1 (Kasir): Verifying staff PIN automatically switches to cashier view and generates room session in dual tablet mode', () async {
      final controller = Get.put(CafeCashierController());
      await controller.setDeviceMode(CounterDeviceMode.dualTabletLocked);

      // Tanpa PIN -> otomatis sisi pembeli
      expect(controller.isCashierView.value, isFalse);

      // Kasir memasukkan PIN '0000' (default)
      final ok = controller.verifyStaffPin('0000');
      expect(ok, isTrue);
      expect(controller.staffPinAuthenticated.value, isTrue);

      // Otomatis di sisi kasir & generate room
      expect(controller.isCashierView.value, isTrue);
      expect(controller.counterId.value, startsWith('KAFE-'));
    });

    test('Tablet 2 (Pembeli): Without staff PIN automatically stays in customer view and connects to cashier room', () async {
      final controller = Get.put(CafeCashierController());

      // Tablet 2 dalam mode dual tablet tanpa PIN
      await controller.setDeviceMode(CounterDeviceMode.dualTabletLocked);
      expect(controller.staffPinAuthenticated.value, isFalse);
      expect(controller.isCashierView.value, isFalse); // Sisi pembeli

      // Tablet 2 memasukkan kode ruangan meja kasir dan menghubungkannya
      await controller.joinRoomSession('KAFE-4819');
      expect(controller.counterId.value, equals('KAFE-4819'));
      expect(controller.isCashierView.value, isFalse); // Tetap di sisi pembeli
    });
  });
}
