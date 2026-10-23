import 'order_enums.dart';

/// Clean domain model for persisting customized drink options in local storage.
class CoffeeCustomizationDraft {
  final String drinkId;
  final OrderTemperature temperature;
  final OrderCupSize cupSize;
  final OrderMilkType milkType;
  final OrderSweetnessLevel sweetness;
  final bool extraShot;
  final int quantity;
  final DateTime updatedAt;

  const CoffeeCustomizationDraft({
    required this.drinkId,
    required this.temperature,
    required this.cupSize,
    required this.milkType,
    required this.sweetness,
    this.extraShot = false,
    this.quantity = 1,
    required this.updatedAt,
  });

  CoffeeCustomizationDraft copyWith({
    String? drinkId,
    OrderTemperature? temperature,
    OrderCupSize? cupSize,
    OrderMilkType? milkType,
    OrderSweetnessLevel? sweetness,
    bool? extraShot,
    int? quantity,
    DateTime? updatedAt,
  }) {
    return CoffeeCustomizationDraft(
      drinkId: drinkId ?? this.drinkId,
      temperature: temperature ?? this.temperature,
      cupSize: cupSize ?? this.cupSize,
      milkType: milkType ?? this.milkType,
      sweetness: sweetness ?? this.sweetness,
      extraShot: extraShot ?? this.extraShot,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drinkId': drinkId,
      'temperature': temperature.name,
      'cupSize': cupSize.name,
      'milkType': milkType.name,
      'sweetness': sweetness.name,
      'extraShot': extraShot,
      'quantity': quantity,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CoffeeCustomizationDraft.fromMap(Map<String, dynamic> map) {
    return CoffeeCustomizationDraft(
      drinkId: map['drinkId'] as String? ?? '',
      temperature: OrderTemperature.values.firstWhere(
        (e) => e.name == map['temperature'],
        orElse: () => OrderTemperature.iced,
      ),
      cupSize: OrderCupSize.values.firstWhere(
        (e) => e.name == map['cupSize'],
        orElse: () => OrderCupSize.medium,
      ),
      milkType: OrderMilkType.values.firstWhere(
        (e) => e.name == map['milkType'],
        orElse: () => OrderMilkType.oatMilk,
      ),
      sweetness: OrderSweetnessLevel.values.firstWhere(
        (e) => e.name == map['sweetness'],
        orElse: () => OrderSweetnessLevel.lessSweet50,
      ),
      extraShot: map['extraShot'] as bool? ?? false,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
