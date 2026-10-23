import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/coffee_recommender_service.dart';

void main() {
  late CoffeeRecommenderService service;

  setUp(() {
    service = const CoffeeRecommenderService();
  });

  group('CoffeeRecommenderService - recommendCoffee', () {
    test('recommends low-acid oat latte when stomach/acid tokens are present', () {
      final result = service.recommendCoffee('saya sedang sakit maag asam lambung');
      expect(result.item.id, 'low_acid_latte');
      expect(result.reasonId, contains('ramah lambung'));
      expect(result.defaultOrderSlot.drinkId, 'low_acid_latte');
    });

    test('recommends Palm Sugar Coffee for sleepy / focus tokens', () {
      final result = service.recommendCoffee('lagi ngantuk butuh kopi kuat buat kerja');
      expect(result.item.id, 'kopi_susu_aren');
      expect(result.defaultOrderSlot.extraShot, isTrue);
      expect(result.matchedTokens, contains('fokus'));
    });

    test('recommends Iced Caramel Latte for cold / sweet / caramel tokens', () {
      final result = service.recommendCoffee('pengen yang dingin segar manis karamel');
      expect(result.item.id, 'iced_caramel_latte');
      expect(result.matchedTokens, contains('dingin'));
    });

    test('recommends Matcha Latte for non-coffee / matcha tokens', () {
      final result = service.recommendCoffee('tidak mau kopi mau teh hijau matcha');
      expect(result.item.id, 'matcha_latte');
      expect(result.matchedTokens, contains('matcha'));
    });

    test('recommends Americano for black / bold / no milk tokens', () {
      final result = service.recommendCoffee('kopi hitam pekat tanpa susu');
      expect(result.item.id, 'americano');
    });

    test('defaults to Oat Cappuccino when generic coffee requested', () {
      final result = service.recommendCoffee('mau kopi hangat yang enak');
      expect(result.item.id, 'cappuccino');
    });
  });
}
