/// Enums defining standard Cafe POS attributes.
enum OrderTemperature { hot, iced }

enum OrderCupSize {
  small, // 8oz / 250ml
  medium, // 12oz / 350ml
  large, // 16oz / 500ml
}

extension OrderCupSizeExtension on OrderCupSize {
  String get labelId {
    switch (this) {
      case OrderCupSize.small:
        return 'Small';
      case OrderCupSize.medium:
        return 'Medium';
      case OrderCupSize.large:
        return 'Large';
    }
  }

  String get volumeText {
    switch (this) {
      case OrderCupSize.small:
        return '8oz / 250ml';
      case OrderCupSize.medium:
        return '12oz / 350ml';
      case OrderCupSize.large:
        return '16oz / 500ml';
    }
  }
}

enum OrderMilkType {
  oatMilk,
  freshDairy,
  soyMilk,
  none,
}

extension OrderMilkTypeExtension on OrderMilkType {
  String get labelId {
    switch (this) {
      case OrderMilkType.oatMilk:
        return 'Susu Oat';
      case OrderMilkType.freshDairy:
        return 'Susu Sapi';
      case OrderMilkType.soyMilk:
        return 'Susu Kedelai';
      case OrderMilkType.none:
        return 'Tanpa Susu';
    }
  }

  String get labelEn {
    switch (this) {
      case OrderMilkType.oatMilk:
        return 'Oat Milk';
      case OrderMilkType.freshDairy:
        return 'Dairy Milk';
      case OrderMilkType.soyMilk:
        return 'Soy Milk';
      case OrderMilkType.none:
        return 'No Milk';
    }
  }
}

enum OrderSweetnessLevel {
  normal100,
  lessSweet50,
  noSugar0,
  aren,
  caramel,
  vanilla,
}

extension OrderSweetnessLevelExtension on OrderSweetnessLevel {
  String get labelId {
    switch (this) {
      case OrderSweetnessLevel.normal100:
        return 'Normal (100%)';
      case OrderSweetnessLevel.lessSweet50:
        return 'Sedikit (50%)';
      case OrderSweetnessLevel.noSugar0:
        return 'Tanpa Gula (0%)';
      case OrderSweetnessLevel.aren:
        return 'Gula Aren';
      case OrderSweetnessLevel.caramel:
        return 'Karamel';
      case OrderSweetnessLevel.vanilla:
        return 'Vanila';
    }
  }

  String get labelEn {
    switch (this) {
      case OrderSweetnessLevel.normal100:
        return 'Normal (100%)';
      case OrderSweetnessLevel.lessSweet50:
        return 'Less (50%)';
      case OrderSweetnessLevel.noSugar0:
        return 'No Sugar (0%)';
      case OrderSweetnessLevel.aren:
        return 'Palm Sugar';
      case OrderSweetnessLevel.caramel:
        return 'Caramel';
      case OrderSweetnessLevel.vanilla:
        return 'Vanilla';
    }
  }
}

extension OrderTemperatureExtension on OrderTemperature {
  String get labelId {
    switch (this) {
      case OrderTemperature.hot:
        return 'HOT (HANGAT)';
      case OrderTemperature.iced:
        return 'ICED (DINGIN)';
    }
  }

  String get labelEn {
    switch (this) {
      case OrderTemperature.hot:
        return 'HOT';
      case OrderTemperature.iced:
        return 'ICED';
    }
  }
}

enum OrderStatus {
  draft,
  confirmed,
  preparing,
  readyForPickup,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get labelId {
    switch (this) {
      case OrderStatus.draft:
        return 'Draft';
      case OrderStatus.confirmed:
        return 'Terkonfirmasi';
      case OrderStatus.preparing:
        return 'Sedang Diseduh';
      case OrderStatus.readyForPickup:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

enum OrderPaymentMethod {
  qris,
  cash,
}

