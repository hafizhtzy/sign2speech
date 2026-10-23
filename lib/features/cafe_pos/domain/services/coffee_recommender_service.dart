import '../models/coffee_menu_item.dart';
import '../models/coffee_recommendation_result.dart';
import '../models/order_enums.dart';
import '../models/parsed_cafe_order_slot.dart';

class CoffeeRecommenderService {
  final List<CoffeeMenuItem> catalog;

  const CoffeeRecommenderService({
    this.catalog = CoffeeMenuItem.standardCatalog,
  });

  /// Evaluates speech/sign tokens or transcript and recommends a tailored cafe drink.
  CoffeeRecommendationResult recommendCoffee(String transcript) {
    final lower = transcript.toLowerCase();

    // Category 1: Sensitive stomach, maag, low acid
    if (lower.contains('maag') ||
        lower.contains('asam') ||
        lower.contains('lambung') ||
        lower.contains('perut') ||
        lower.contains('sakit')) {
      final item = catalog.firstWhere(
        (i) => i.id == 'low_acid_latte',
        orElse: () => catalog.first,
      );
      return CoffeeRecommendationResult(
        item: item,
        reasonId:
            'Sangat ramah lambung dengan ekstraksi dingin minim asam dan susu oat murni.',
        reasonEn:
            'Very gentle on sensitive stomachs with slow-dripped low acid and pure oat milk.',
        matchedTokens: ['maag', 'lambung', 'rendah asam'],
        defaultOrderSlot: ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          temperature: OrderTemperature.hot,
          cupSize: OrderCupSize.medium,
          milkType: OrderMilkType.oatMilk,
          sweetnessLevel: OrderSweetnessLevel.noSugar0,
          basePrice: item.basePrice,
        ),
      );
    }

    // Category 2: Tired, sleepy, focus, work, strong, aren
    if (lower.contains('ngantuk') ||
        lower.contains('kuat') ||
        lower.contains('kerja') ||
        lower.contains('fokus') ||
        lower.contains('aren') ||
        lower.contains('lelah')) {
      final item = catalog.firstWhere(
        (i) => i.id == 'kopi_susu_aren',
        orElse: () => catalog.first,
      );
      return CoffeeRecommendationResult(
        item: item,
        reasonId:
            'Ekstra kafein ganda dengan kelezatan gula aren organik untuk memulihkan energi dan fokus kerja.',
        reasonEn:
            'Double shot espresso caffeine boost with organic palm sugar to revive energy and focus.',
        matchedTokens: ['fokus', 'aren', 'double shot'],
        defaultOrderSlot: ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          temperature: OrderTemperature.iced,
          cupSize: OrderCupSize.medium,
          milkType: OrderMilkType.freshDairy,
          sweetnessLevel: OrderSweetnessLevel.aren,
          extraShot: true,
          basePrice: item.basePrice,
        ),
      );
    }

    // Category 3: Cold, sweet, refreshing, caramel
    if (lower.contains('dingin') ||
        lower.contains('segar') ||
        lower.contains('manis') ||
        lower.contains('karamel') ||
        lower.contains('caramel') ||
        lower.contains('es')) {
      final item = catalog.firstWhere(
        (i) => i.id == 'iced_caramel_latte',
        orElse: () => catalog.first,
      );
      return CoffeeRecommendationResult(
        item: item,
        reasonId:
            'Sensasi dingin menyegarkan berpadu gurihnya saus karamel artisanal dan oat milk.',
        reasonEn:
            'Crisp, refreshing iced beverage paired with rich artisan caramel sauce and oat milk.',
        matchedTokens: ['dingin', 'segar', 'karamel'],
        defaultOrderSlot: ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          temperature: OrderTemperature.iced,
          cupSize: OrderCupSize.medium,
          milkType: OrderMilkType.oatMilk,
          sweetnessLevel: OrderSweetnessLevel.caramel,
          basePrice: item.basePrice,
        ),
      );
    }

    // Category 4: Matcha / Non-Coffee
    if (lower.contains('matcha') ||
        lower.contains('tanpa kopi') ||
        lower.contains('hijau') ||
        lower.contains('teh')) {
      final item = catalog.firstWhere(
        (i) => i.id == 'matcha_latte',
        orElse: () => catalog.first,
      );
      return CoffeeRecommendationResult(
        item: item,
        reasonId:
            'Matcha Uji Jepang kaya antioksidan tanpa kafein kopi, menenangkan pikiran.',
        reasonEn:
            'Antioxidant-rich Japanese Uji matcha without coffee caffeine, soothing and relaxing.',
        matchedTokens: ['matcha', 'tanpa kopi', 'oat milk'],
        defaultOrderSlot: ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          temperature: OrderTemperature.hot,
          cupSize: OrderCupSize.medium,
          milkType: OrderMilkType.oatMilk,
          sweetnessLevel: OrderSweetnessLevel.lessSweet50,
          basePrice: item.basePrice,
        ),
      );
    }

    // Category 5: Black, bitter, low calorie, americano
    if (lower.contains('hitam') ||
        lower.contains('pahit') ||
        lower.contains('diet') ||
        lower.contains('kalori') ||
        lower.contains('americano')) {
      final item = catalog.firstWhere(
        (i) => i.id == 'americano',
        orElse: () => catalog.first,
      );
      return CoffeeRecommendationResult(
        item: item,
        reasonId:
            'Rasa kopi murni tanpa gula atau susu dengan crema emas tebal dan kalori sangat rendah.',
        reasonEn:
            'Pure black coffee without sugar or milk, rich golden crema and ultra-low calories.',
        matchedTokens: ['hitam', 'pahit', 'tanpa gula'],
        defaultOrderSlot: ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          temperature: OrderTemperature.iced,
          cupSize: OrderCupSize.medium,
          milkType: OrderMilkType.none,
          sweetnessLevel: OrderSweetnessLevel.noSugar0,
          basePrice: item.basePrice,
        ),
      );
    }

    // Default Fallback: Oat Cappuccino
    final defaultItem = catalog.firstWhere(
      (i) => i.id == 'cappuccino',
      orElse: () => catalog.first,
    );
    return CoffeeRecommendationResult(
      item: defaultItem,
      reasonId:
          'Pilihan paling favorit: kelembutan microfoam berpadu harmonis dengan espresso gurih hangat.',
      reasonEn:
          'All-time cafe favorite: silky microfoam harmonizing with warm, velvety espresso.',
      matchedTokens: ['lembut', 'creamy', 'favorit'],
      defaultOrderSlot: ParsedCafeOrderSlot(
        drinkId: defaultItem.id,
        drinkLabelKey: defaultItem.id,
        drinkNameId: defaultItem.nameId,
        drinkNameEn: defaultItem.nameEn,
        temperature: OrderTemperature.hot,
        cupSize: OrderCupSize.medium,
        milkType: OrderMilkType.oatMilk,
        sweetnessLevel: OrderSweetnessLevel.lessSweet50,
        basePrice: defaultItem.basePrice,
      ),
    );
  }
}
