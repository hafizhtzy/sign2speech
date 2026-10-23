import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/dietary_alert_tag.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/order_slot_parser_service.dart';

void main() {
  late OrderSlotParserService service;

  setUp(() {
    service = OrderSlotParserService();
  });

  group('OrderSlotParserService - parseTranscript', () {
    test('parses iced caramel latte with modifiers correctly', () {
      const transcript =
          'mau pesan es karamel latte ukuran large less sweet extra shot';
      final slot = service.parseTranscript(transcript);

      expect(slot.drinkId, 'iced_caramel_latte');
      expect(slot.temperature, OrderTemperature.iced);
      expect(slot.cupSize, OrderCupSize.large);
      expect(slot.sweetnessLevel, OrderSweetnessLevel.lessSweet50);
      expect(slot.extraShot, isTrue);
      expect(slot.quantity, 1);
      // base 35000 + large 6000 + oat milk 6000 + extra shot 5000 = 52000
      expect(slot.totalPrice, 52000);
    });

    test('parses hot cappuccino with small cup and no sugar', () {
      const transcript =
          'kopi cappuccino panas ukuran kecil tanpa gula oat milk';
      final slot = service.parseTranscript(transcript);

      expect(slot.drinkId, 'cappuccino');
      expect(slot.temperature, OrderTemperature.hot);
      expect(slot.cupSize, OrderCupSize.small);
      expect(slot.sweetnessLevel, OrderSweetnessLevel.noSugar0);
      expect(slot.milkType, OrderMilkType.oatMilk);
      expect(slot.extraShot, isFalse);
      // base 32000 - small 4000 + oat milk 6000 = 34000
      expect(slot.totalPrice, 34000);
    });

    test('parses Palm Sugar Coffee with quantity 2', () {
      const transcript = 'pesan 2 kopi susu aren dingin sedang';
      final slot = service.parseTranscript(transcript);

      expect(slot.drinkId, 'kopi_susu_aren');
      expect(slot.temperature, OrderTemperature.iced);
      expect(slot.cupSize, OrderCupSize.medium);
      expect(slot.quantity, 2);
      expect(slot.unitPrice, 28000);
      expect(slot.totalPrice, 56000);
    });

    test('parses Americano with black no milk', () {
      const transcript = 'mau kopi hitam americano panas';
      final slot = service.parseTranscript(transcript);

      expect(slot.drinkId, 'americano');
      expect(slot.temperature, OrderTemperature.hot);
      expect(slot.milkType, OrderMilkType.none);
    });
  });

  group('OrderSlotParserService - Dietary & Safety Alerts', () {
    test('detects lactose intolerance warning', () {
      const transcript = 'saya intoleransi laktosa jangan pakai susu sapi';
      final alerts = service.detectDietaryAlerts(transcript);

      expect(
        alerts.any((a) => a.type == DietaryAlertType.lactoseIntolerant),
        isTrue,
      );
    });

    test('detects diabetes / sugar warning', () {
      const transcript = 'ada diabetes gula darah';
      final alerts = service.detectDietaryAlerts(transcript);

      expect(
        alerts.any((a) => a.type == DietaryAlertType.diabetesSugarAlert),
        isTrue,
      );
    });

    test('detects stomach maag / acid warning', () {
      const transcript = 'lagi sakit maag asam lambung kambuh';
      final alerts = service.detectDietaryAlerts(transcript);

      expect(
        alerts.any((a) => a.type == DietaryAlertType.acidRefluxMaag),
        isTrue,
      );
    });

    test('detects peanut / nut allergy critical alert', () {
      const transcript = 'saya ada alergi kacang parah';
      final alerts = service.detectDietaryAlerts(transcript);

      expect(alerts.any((a) => a.type == DietaryAlertType.nutAllergy), isTrue);
      expect(
        alerts.firstWhere((a) => a.type == DietaryAlertType.nutAllergy).severity,
        DietaryAlertSeverity.critical,
      );
    });
  });
}
