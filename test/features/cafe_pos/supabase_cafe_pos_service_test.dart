import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/supabase/supabase_result.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/cafe_menu_storage_service.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/supabase_cafe_pos_service.dart';
import 'package:speech2sign/features/cafe_pos/data/datasources/supabase_counter_session_service.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_counter_session.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_order_ticket.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';

void main() {
  group('SupabaseCafePosService & Cafe POS Order Cloud Sync Tests', () {
    test('SupabaseResult pattern matching handles cafe order success and failure', () {
      const SupabaseResult<String> orderResult = SupabaseSuccess('ORD-20261024-001');
      const SupabaseResult<String> failResult = SupabaseFailure('Quota exceeded');

      final orderStatus = switch (orderResult) {
        SupabaseSuccess(:final data) => 'Order persisted: $data',
        SupabaseFailure(:final errorMessage) => 'Failed: $errorMessage',
      };

      final failStatus = switch (failResult) {
        SupabaseSuccess(:final data) => 'Order persisted: $data',
        SupabaseFailure(:final errorMessage) => 'Failed: $errorMessage',
      };

      expect(orderStatus, 'Order persisted: ORD-20261024-001');
      expect(failStatus, 'Failed: Quota exceeded');
    });

    test('Defensive lazy initialization safely returns SupabaseFailure when uninitialized in test harness', () async {
      final service = SupabaseCafePosService();
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
      expect(saveResult, isA<SupabaseFailure<String>>());
      switch (saveResult) {
        case SupabaseSuccess():
          fail('Should fail defensively without Supabase client');
        case SupabaseFailure(:final errorMessage):
          expect(errorMessage.contains('not initialized'), isTrue);
      }

      final fetchResult = await service.fetchRecentOrders();
      expect(fetchResult, isA<SupabaseFailure<List<CafeOrderTicket>>>());

      final updateResult = await service.updateOrderStatus('ORD-TEST-99', OrderStatus.completed);
      expect(updateResult, isA<SupabaseFailure<void>>());

      final loyaltyResult = await service.syncLoyaltyStamps('cust_01', 5);
      expect(loyaltyResult, isA<SupabaseFailure<void>>());

      // Stream should emit empty list gracefully
      final stream = service.streamActiveOrders();
      expect(await stream.first, isEmpty);
    });

    test('CafeOrderTicket correctly computes totals and serializes to Supabase map', () {
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

    test('CafeMenuStorageService defensive lazy initialization & CoffeeMenuItem PostgreSQL mapping', () async {
      final menuService = CafeMenuStorageService();

      final fetchRes = await menuService.fetchMenus();
      expect(fetchRes, isA<SupabaseFailure<List<CoffeeMenuItem>>>());

      final uploadRes = await menuService.uploadMenuPhoto(
        menuId: 'cappuccino',
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        oldStoragePath: 'menus/old_cappuccino.jpg',
      );
      expect(uploadRes, isA<SupabaseFailure<MenuPhotoUploadResult>>());

      final deleteRes = await menuService.deleteMenu(
        menuId: 'cappuccino',
        storagePath: 'menus/cappuccino.jpg',
      );
      expect(deleteRes, isA<SupabaseFailure<void>>());

      final streamItems = await menuService.streamMenus().first;
      expect(streamItems.length, CoffeeMenuItem.standardCatalog.length);

      // Verify CoffeeMenuItem snake_case PostgreSQL serialization & deserialization
      final menu = CoffeeMenuItem.standardCatalog.first.copyWith(
        imageUrl: 'https://demo.supabase.co/storage/v1/object/public/menu-photos/menus/cappuccino.jpg',
        storagePath: 'menus/cappuccino.jpg',
        category: 'coffee',
        isAvailable: true,
      );
      final pgMap = menu.toPostgresMap();
      expect(pgMap['id'], 'cappuccino');
      expect(pgMap['image_url'], contains('menu-photos/menus/cappuccino.jpg'));
      expect(pgMap['image_path'], 'menus/cappuccino.jpg');

      final parsed = CoffeeMenuItem.fromMap(pgMap);
      expect(parsed.id, 'cappuccino');
      expect(parsed.hasNetworkImage, isTrue);
      expect(parsed.storagePath, 'menus/cappuccino.jpg');
    });

    test('SupabaseCounterSessionService defensive lazy init & PostgreSQL snake_case mapping', () async {
      final counterService = SupabaseCounterSessionService();

      final syncRes = await counterService.syncStage(
        'KAFE-01',
        CafeOrderStage.ordering,
        currentOrderId: 'ORD-108',
      );
      expect(syncRes, isA<SupabaseFailure<void>>());

      final pgSession = CafeCounterSession.fromMap({
        'counter_id': 'KAFE-01',
        'stage': 'naming',
        'device_mode': 'dualTablet',
        'current_order_id': 'ORD-202',
        'cashier_tablet_id': 'TAB-CASHIER-1',
        'customer_tablet_id': 'TAB-CUST-1',
        'updated_at': '2026-11-15T12:00:00Z',
      });
      expect(pgSession.counterId, 'KAFE-01');
      expect(pgSession.stage, CafeOrderStage.naming);
      expect(pgSession.deviceMode, CounterDeviceMode.dualTabletLocked);
      expect(pgSession.currentOrderId, 'ORD-202');
      expect(pgSession.isDualTablet, isTrue);
    });
  });
}
