import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/firebase/firestore_result.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/firestore_cafe_pos_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_order_ticket.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';

void main() {
  group('FirestoreCafePosService & Cafe POS Order Cloud Sync Tests', () {
    test('FirestoreResult pattern matching handles cafe order success and failure', () {
      const FirestoreResult<String> orderResult = FirestoreSuccess('ORD-20261024-001');
      const FirestoreResult<String> failResult = FirestoreFailure('Quota exceeded');

      final orderStatus = switch (orderResult) {
        FirestoreSuccess(:final data) => 'Order persisted: $data',
        FirestoreFailure(:final errorMessage) => 'Failed: $errorMessage',
      };

      final failStatus = switch (failResult) {
        FirestoreSuccess(:final data) => 'Order persisted: $data',
        FirestoreFailure(:final errorMessage) => 'Failed: $errorMessage',
      };

      expect(orderStatus, 'Order persisted: ORD-20261024-001');
      expect(failStatus, 'Failed: Quota exceeded');
    });

    test('Defensive lazy initialization safely returns FirestoreFailure when uninitialized in test harness', () async {
      final service = FirestoreCafePosService();
      final testTicket = CafeOrderTicket(
        orderId: 'ORD-TEST-99',
        queueNumber: 'A-108',
        customerName: 'Ahmad',
        items: [
          const ParsedCafeOrderSlot(
            drinkId: 'kopi_susu_oat',
            drinkLabelKey: 'cafe_drink_oat_latte',
            drinkNameId: 'Kopi Susu Oat',
            drinkNameEn: 'Oat Milk Latte',
            milkType: OrderMilkType.oatMilk,
            cupSize: OrderCupSize.medium,
            sweetnessLevel: OrderSweetnessLevel.lessSweet50,
            basePrice: 28000,
          ),
        ],
        status: OrderStatus.completed,
        paymentMethod: OrderPaymentMethod.qris,
        amountPaid: 34000,
        createdAt: DateTime.now(),
      );

      final saveResult = await service.saveOrder(testTicket);
      expect(saveResult, isA<FirestoreFailure<String>>());
      switch (saveResult) {
        case FirestoreSuccess():
          fail('Should fail defensively without Firebase app');
        case FirestoreFailure(:final errorMessage):
          expect(errorMessage.contains('not initialized'), isTrue);
      }

      final fetchResult = await service.fetchRecentOrders();
      expect(fetchResult, isA<FirestoreFailure<List<CafeOrderTicket>>>());

      final updateResult = await service.updateOrderStatus('ORD-TEST-99', OrderStatus.completed);
      expect(updateResult, isA<FirestoreFailure<void>>());

      final loyaltyResult = await service.syncLoyaltyStamps('cust_01', 5);
      expect(loyaltyResult, isA<FirestoreFailure<void>>());

      // Stream should emit empty list gracefully
      final stream = service.streamActiveOrders();
      expect(await stream.first, isEmpty);
    });

    test('CafeOrderTicket correctly computes totals and serializes to Firestore map', () {
      final ticket = CafeOrderTicket(
        orderId: 'ORD-777',
        queueNumber: 'B-042',
        customerName: 'Siti',
        customerNotes: 'Less ice please',
        items: [
          const ParsedCafeOrderSlot(
            drinkId: 'americano',
            drinkLabelKey: 'cafe_drink_americano',
            drinkNameId: 'Americano',
            drinkNameEn: 'Americano',
            cupSize: OrderCupSize.medium,
            milkType: OrderMilkType.none,
            basePrice: 20000,
          ),
          const ParsedCafeOrderSlot(
            drinkId: 'latte',
            drinkLabelKey: 'cafe_drink_latte',
            drinkNameId: 'Cafe Latte',
            drinkNameEn: 'Cafe Latte',
            milkType: OrderMilkType.oatMilk,
            cupSize: OrderCupSize.medium,
            basePrice: 30000,
          ),
        ],
        status: OrderStatus.confirmed,
        paymentMethod: OrderPaymentMethod.cash,
        amountPaid: 70000,
        createdAt: DateTime(2026, 10, 24, 15, 0, 0),
      );

      expect(ticket.subtotal, 56000); // 20000 + (30000 + 6000 oat modifier)
      expect(ticket.taxAmount, 5600); // 10% tax
      expect(ticket.grandTotal, 61600);
      expect(ticket.changeAmount, 8400); // 70000 - 61600

      final map = ticket.toMap();
      expect(map['orderId'], 'ORD-777');
      expect(map['queueNumber'], 'B-042');
      expect(map['customerName'], 'Siti');
      expect(map['status'], 'confirmed');
      expect(map['paymentMethod'], 'cash');
      expect(map['amountPaid'], 70000);
      expect((map['items'] as List).length, 2);

      final reconstituted = CafeOrderTicket.fromMap(map);
      expect(reconstituted.orderId, ticket.orderId);
      expect(reconstituted.queueNumber, ticket.queueNumber);
      expect(reconstituted.subtotal, ticket.subtotal);
      expect(reconstituted.grandTotal, ticket.grandTotal);
    });
  });
}
