import 'coffee_menu_item.dart';
import 'parsed_cafe_order_slot.dart';

class CoffeeRecommendationResult {
  final CoffeeMenuItem item;
  final String reasonId;
  final String reasonEn;
  final List<String> matchedTokens;
  final ParsedCafeOrderSlot defaultOrderSlot;

  const CoffeeRecommendationResult({
    required this.item,
    required this.reasonId,
    required this.reasonEn,
    required this.matchedTokens,
    required this.defaultOrderSlot,
  });
}
