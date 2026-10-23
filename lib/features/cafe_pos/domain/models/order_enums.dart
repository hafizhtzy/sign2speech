/// Enums defining standard Cafe POS attributes.
enum OrderTemperature { hot, iced }

enum OrderCupSize {
  small, // 8oz / 250ml
  medium, // 12oz / 350ml
  large, // 16oz / 500ml
}

enum OrderMilkType {
  oatMilk,
  freshDairy,
  soyMilk,
  none,
}

enum OrderSweetnessLevel {
  normal100,
  lessSweet50,
  noSugar0,
  aren,
  caramel,
  vanilla,
}

enum OrderStatus {
  draft,
  confirmed,
  preparing,
  readyForPickup,
  completed,
  cancelled,
}

enum OrderPaymentMethod {
  qris,
  cash,
}
