import 'dietary_alert_tag.dart';
import 'order_enums.dart';

class ParsedCafeOrderSlot {
  final String drinkId;
  final String drinkLabelKey;
  final String drinkNameId;
  final String drinkNameEn;
  final OrderTemperature temperature;
  final OrderCupSize cupSize;
  final OrderMilkType milkType;
  final OrderSweetnessLevel sweetnessLevel;
  final bool extraShot;
  final int quantity;
  final int basePrice;
  final List<DietaryAlertTag> dietaryAlerts;

  const ParsedCafeOrderSlot({
    required this.drinkId,
    required this.drinkLabelKey,
    required this.drinkNameId,
    required this.drinkNameEn,
    this.temperature = OrderTemperature.iced,
    this.cupSize = OrderCupSize.medium,
    this.milkType = OrderMilkType.oatMilk,
    this.sweetnessLevel = OrderSweetnessLevel.lessSweet50,
    this.extraShot = false,
    this.quantity = 1,
    this.basePrice = 28000,
    this.dietaryAlerts = const [],
  });

  /// Computes price for a single unit of this item considering modifiers.
  int get unitPrice {
    var price = basePrice;

    // Cup size modifier
    switch (cupSize) {
      case OrderCupSize.small:
        price -= 4000;
        break;
      case OrderCupSize.medium:
        break;
      case OrderCupSize.large:
        price += 6000;
        break;
    }

    // Milk modifier
    if (milkType == OrderMilkType.oatMilk) {
      price += 6000;
    } else if (milkType == OrderMilkType.soyMilk) {
      price += 5000;
    }

    // Extra shot modifier
    if (extraShot) {
      price += 5000;
    }

    return price > 0 ? price : 10000;
  }

  /// Total price multiplied by quantity.
  int get totalPrice => unitPrice * quantity;

  /// Human-readable spoken or displayed summary in Indonesian.
  String get summaryId {
    final tempStr = temperature == OrderTemperature.hot ? 'Panas' : 'Dingin (Es)';
    final sizeStr = cupSize == OrderCupSize.small
        ? 'Small (8oz)'
        : (cupSize == OrderCupSize.medium ? 'Medium (12oz)' : 'Large (16oz)');
    final milkStr = milkType == OrderMilkType.oatMilk
        ? 'Oat Milk'
        : (milkType == OrderMilkType.soyMilk
            ? 'Soy Milk'
            : (milkType == OrderMilkType.freshDairy ? 'Fresh Dairy' : 'Tanpa Susu'));
    final sweetStr = sweetnessLevel == OrderSweetnessLevel.noSugar0
        ? 'Tanpa Gula (0%)'
        : (sweetnessLevel == OrderSweetnessLevel.lessSweet50
            ? 'Less Sweet (50%)'
            : (sweetnessLevel == OrderSweetnessLevel.aren
                ? 'Gula Aren'
                : (sweetnessLevel == OrderSweetnessLevel.caramel
                    ? 'Karamel'
                    : (sweetnessLevel == OrderSweetnessLevel.vanilla
                        ? 'Vanila'
                        : 'Normal (100%)'))));
    final extraStr = extraShot ? ', Extra Shot' : '';

    return '$quantity $drinkNameId ($tempStr, $sizeStr, $milkStr, $sweetStr$extraStr)';
  }

  /// Human-readable spoken or displayed summary in English.
  String get summaryEn {
    final tempStr = temperature == OrderTemperature.hot ? 'Hot' : 'Iced';
    final sizeStr = cupSize == OrderCupSize.small
        ? 'Small (8oz)'
        : (cupSize == OrderCupSize.medium ? 'Medium (12oz)' : 'Large (16oz)');
    final milkStr = milkType == OrderMilkType.oatMilk
        ? 'Oat Milk'
        : (milkType == OrderMilkType.soyMilk
            ? 'Soy Milk'
            : (milkType == OrderMilkType.freshDairy ? 'Fresh Dairy' : 'No Milk'));
    final sweetStr = sweetnessLevel == OrderSweetnessLevel.noSugar0
        ? 'No Sugar (0%)'
        : (sweetnessLevel == OrderSweetnessLevel.lessSweet50
            ? 'Less Sweet (50%)'
            : (sweetnessLevel == OrderSweetnessLevel.aren
                ? 'Palm Sugar'
                : (sweetnessLevel == OrderSweetnessLevel.caramel
                    ? 'Caramel'
                    : (sweetnessLevel == OrderSweetnessLevel.vanilla
                        ? 'Vanilla'
                        : 'Normal (100%)'))));
    final extraStr = extraShot ? ', Extra Shot' : '';

    return '$quantity $drinkNameEn ($tempStr, $sizeStr, $milkStr, $sweetStr$extraStr)';
  }

  ParsedCafeOrderSlot copyWith({
    String? drinkId,
    String? drinkLabelKey,
    String? drinkNameId,
    String? drinkNameEn,
    OrderTemperature? temperature,
    OrderCupSize? cupSize,
    OrderMilkType? milkType,
    OrderSweetnessLevel? sweetnessLevel,
    bool? extraShot,
    int? quantity,
    int? basePrice,
    List<DietaryAlertTag>? dietaryAlerts,
  }) {
    return ParsedCafeOrderSlot(
      drinkId: drinkId ?? this.drinkId,
      drinkLabelKey: drinkLabelKey ?? this.drinkLabelKey,
      drinkNameId: drinkNameId ?? this.drinkNameId,
      drinkNameEn: drinkNameEn ?? this.drinkNameEn,
      temperature: temperature ?? this.temperature,
      cupSize: cupSize ?? this.cupSize,
      milkType: milkType ?? this.milkType,
      sweetnessLevel: sweetnessLevel ?? this.sweetnessLevel,
      extraShot: extraShot ?? this.extraShot,
      quantity: quantity ?? this.quantity,
      basePrice: basePrice ?? this.basePrice,
      dietaryAlerts: dietaryAlerts ?? this.dietaryAlerts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drinkId': drinkId,
      'drinkLabelKey': drinkLabelKey,
      'drinkNameId': drinkNameId,
      'drinkNameEn': drinkNameEn,
      'temperature': temperature.name,
      'cupSize': cupSize.name,
      'milkType': milkType.name,
      'sweetnessLevel': sweetnessLevel.name,
      'extraShot': extraShot,
      'quantity': quantity,
      'basePrice': basePrice,
      'dietaryAlerts': dietaryAlerts.map((e) => e.toMap()).toList(),
    };
  }

  factory ParsedCafeOrderSlot.fromMap(Map<String, dynamic> map) {
    return ParsedCafeOrderSlot(
      drinkId: map['drinkId'] as String? ?? '',
      drinkLabelKey: map['drinkLabelKey'] as String? ?? '',
      drinkNameId: map['drinkNameId'] as String? ?? '',
      drinkNameEn: map['drinkNameEn'] as String? ?? '',
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
      sweetnessLevel: OrderSweetnessLevel.values.firstWhere(
        (e) => e.name == map['sweetnessLevel'],
        orElse: () => OrderSweetnessLevel.lessSweet50,
      ),
      extraShot: map['extraShot'] as bool? ?? false,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      basePrice: (map['basePrice'] as num?)?.toInt() ?? 28000,
      dietaryAlerts: (map['dietaryAlerts'] as List<dynamic>?)
              ?.map((e) => DietaryAlertTag.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

