import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/cafe_pos_local_data_source.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_order_ticket.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_customization_draft.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CafePosLocalDataSource Tests', () {
    test('loadActiveTicket returns null when storage is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = CafePosLocalDataSource(prefs: prefs);

      final ticket = await dataSource.loadActiveTicket();
      expect(ticket, isNull);
    });

    test('saveActiveTicket persists and loadActiveTicket restores full ticket', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = CafePosLocalDataSource(prefs: prefs);

      const slot = ParsedCafeOrderSlot(
        drinkId: 'coffee_latte',
        drinkLabelKey: 'coffee_latte',
        drinkNameId: 'Cafe Latte',
        drinkNameEn: 'Cafe Latte',
        temperature: OrderTemperature.hot,
        cupSize: OrderCupSize.large,
        milkType: OrderMilkType.soyMilk,
        sweetnessLevel: OrderSweetnessLevel.lessSweet50,
        extraShot: true,
        quantity: 2,
        basePrice: 28000,
      );

      final ticketToSave = CafeOrderTicket(
        orderId: 'ORD-999',
        queueNumber: 'A-999',
        customerName: 'Budi',
        customerNotes: 'Kurangi es',
        items: const [slot],
        status: OrderStatus.draft,
        paymentMethod: OrderPaymentMethod.cash,
        amountPaid: 80000,
        createdAt: DateTime(2026, 10, 23, 20, 30),
      );

      await dataSource.saveActiveTicket(ticketToSave);

      final restored = await dataSource.loadActiveTicket();
      expect(restored, isNotNull);
      expect(restored!.orderId, equals('ORD-999'));
      expect(restored.queueNumber, equals('A-999'));
      expect(restored.customerName, equals('Budi'));
      expect(restored.items.length, equals(1));

      final restoredSlot = restored.items.first;
      expect(restoredSlot.drinkId, equals('coffee_latte'));
      expect(restoredSlot.temperature, equals(OrderTemperature.hot));
      expect(restoredSlot.cupSize, equals(OrderCupSize.large));
      expect(restoredSlot.milkType, equals(OrderMilkType.soyMilk));
      expect(restoredSlot.extraShot, isTrue);
      expect(restoredSlot.quantity, equals(2));
    });

    test('clearActiveTicket removes active ticket from storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = CafePosLocalDataSource(prefs: prefs);

      final ticket = CafeOrderTicket(
        orderId: 'ORD-123',
        queueNumber: 'A-123',
        items: const [],
        createdAt: DateTime.now(),
      );

      await dataSource.saveActiveTicket(ticket);
      expect(await dataSource.loadActiveTicket(), isNotNull);

      await dataSource.clearActiveTicket();
      expect(await dataSource.loadActiveTicket(), isNull);
    });

    test('saveCustomizationDraft and loadCustomizationDraft work per drinkId', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = CafePosLocalDataSource(prefs: prefs);

      final draftLatte = CoffeeCustomizationDraft(
        drinkId: 'coffee_latte',
        temperature: OrderTemperature.hot,
        cupSize: OrderCupSize.large,
        milkType: OrderMilkType.oatMilk,
        sweetness: OrderSweetnessLevel.noSugar0,
        extraShot: true,
        quantity: 1,
        updatedAt: DateTime.now(),
      );

      await dataSource.saveCustomizationDraft(draftLatte);

      final loadedLatte = await dataSource.loadCustomizationDraft('coffee_latte');
      expect(loadedLatte, isNotNull);
      expect(loadedLatte!.drinkId, equals('coffee_latte'));
      expect(loadedLatte.temperature, equals(OrderTemperature.hot));
      expect(loadedLatte.cupSize, equals(OrderCupSize.large));
      expect(loadedLatte.milkType, equals(OrderMilkType.oatMilk));
      expect(loadedLatte.sweetness, equals(OrderSweetnessLevel.noSugar0));
      expect(loadedLatte.extraShot, isTrue);

      final loadedMocha = await dataSource.loadCustomizationDraft('coffee_mocha');
      expect(loadedMocha, isNull);

      await dataSource.clearCustomizationDraft('coffee_latte');
      expect(await dataSource.loadCustomizationDraft('coffee_latte'), isNull);
    });

    test('loadActiveTicket handles corrupted json gracefully by returning null', () async {
      SharedPreferences.setMockInitialValues({
        'cafe_pos_active_ticket_v1': 'invalid-json-content',
      });
      final prefs = await SharedPreferences.getInstance();
      final dataSource = CafePosLocalDataSource(prefs: prefs);

      final ticket = await dataSource.loadActiveTicket();
      expect(ticket, isNull);
    });
  });
}
