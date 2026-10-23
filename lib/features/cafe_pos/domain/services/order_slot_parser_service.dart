import '../models/dietary_alert_tag.dart';
import '../models/order_enums.dart';
import '../models/parsed_cafe_order_slot.dart';

class OrderSlotParserService {
  /// Parses transcript text (either from sign recognition or speech recognition)
  /// into a structured [ParsedCafeOrderSlot].
  ParsedCafeOrderSlot parseTranscript(String text) {
    final lower = text.toLowerCase().trim();

    // 1. Detect Drink Type
    String drinkId = 'cappuccino';
    String drinkLabelKey = 'cappuccino';
    String drinkNameId = 'Oat Cappuccino';
    String drinkNameEn = 'Oat Cappuccino';
    int basePrice = 32000;

    if (lower.contains('caramel') || lower.contains('karamel')) {
      drinkId = 'iced_caramel_latte';
      drinkLabelKey = 'iced_caramel_latte';
      drinkNameId = 'Iced Oat Caramel Latte';
      drinkNameEn = 'Iced Oat Caramel Latte';
      basePrice = 35000;
    } else if (lower.contains('aren') ||
        lower.contains('kopi susu') ||
        lower.contains('palm sugar')) {
      drinkId = 'kopi_susu_aren';
      drinkLabelKey = 'kopi_susu_aren';
      drinkNameId = 'Double Shot Kopi Susu Aren';
      drinkNameEn = 'Double Shot Palm Sugar Coffee';
      basePrice = 28000;
    } else if (lower.contains('maag') ||
        lower.contains('asam') ||
        lower.contains('low acid') ||
        lower.contains('lambung')) {
      drinkId = 'low_acid_latte';
      drinkLabelKey = 'low_acid_latte';
      drinkNameId = 'Low-Acid Oat Latte';
      drinkNameEn = 'Low-Acid Oat Latte';
      basePrice = 34000;
    } else if (lower.contains('matcha')) {
      drinkId = 'matcha_latte';
      drinkLabelKey = 'matcha_latte';
      drinkNameId = 'Uji Matcha Oat Latte';
      drinkNameEn = 'Uji Matcha Oat Latte';
      basePrice = 34000;
    } else if (lower.contains('americano') ||
        lower.contains('kopi hitam') ||
        lower.contains('black')) {
      drinkId = 'americano';
      drinkLabelKey = 'americano';
      drinkNameId = 'Caffè Americano';
      drinkNameEn = 'Caffè Americano';
      basePrice = 25000;
    } else if (lower.contains('cappuccino') || lower.contains('kapusino')) {
      drinkId = 'cappuccino';
      drinkLabelKey = 'cappuccino';
      drinkNameId = 'Oat Cappuccino';
      drinkNameEn = 'Oat Cappuccino';
      basePrice = 32000;
    } else if (lower.contains('latte') || lower.contains('kopi')) {
      drinkId = 'cappuccino';
      drinkLabelKey = 'cappuccino';
      drinkNameId = 'Signature Cafe Latte';
      drinkNameEn = 'Signature Cafe Latte';
      basePrice = 30000;
    }

    // 2. Temperature Detection
    OrderTemperature temperature = OrderTemperature.iced;
    final hasHot = lower.contains('panas') ||
        lower.contains('hangat') ||
        RegExp(r'\bhot\b').hasMatch(lower);
    final hasIced = lower.contains('dingin') ||
        lower.contains('iced') ||
        RegExp(r'\b(es|ice)\b').hasMatch(lower);

    if (hasIced) {
      temperature = OrderTemperature.iced;
    } else if (hasHot) {
      temperature = OrderTemperature.hot;
    }

    // 3. Cup Size Detection
    OrderCupSize cupSize = OrderCupSize.medium;
    if (lower.contains('kecil') ||
        lower.contains('small') ||
        lower.contains('8oz') ||
        lower.contains('250ml')) {
      cupSize = OrderCupSize.small;
    } else if (lower.contains('besar') ||
        lower.contains('large') ||
        lower.contains('16oz') ||
        lower.contains('500ml')) {
      cupSize = OrderCupSize.large;
    } else if (lower.contains('sedang') ||
        lower.contains('medium') ||
        lower.contains('12oz') ||
        lower.contains('350ml')) {
      cupSize = OrderCupSize.medium;
    }

    // 4. Milk Type Detection
    OrderMilkType milkType = (drinkId == 'kopi_susu_aren')
        ? OrderMilkType.freshDairy
        : OrderMilkType.oatMilk;
    if (lower.contains('tanpa susu') ||
        lower.contains('no milk') ||
        lower.contains('hitam') ||
        drinkId == 'americano') {
      milkType = OrderMilkType.none;
    } else if (lower.contains('kedelai') || lower.contains('soy')) {
      milkType = OrderMilkType.soyMilk;
    } else if (lower.contains('susu sapi') ||
        lower.contains('fresh milk') ||
        lower.contains('dairy')) {
      milkType = OrderMilkType.freshDairy;
    } else if (lower.contains('oat') || lower.contains('gandum')) {
      milkType = OrderMilkType.oatMilk;
    }

    // 5. Sweetness Level Detection
    OrderSweetnessLevel sweetness = OrderSweetnessLevel.lessSweet50;
    if (lower.contains('tanpa gula') ||
        lower.contains('no sugar') ||
        lower.contains('0%') ||
        lower.contains('pahit')) {
      sweetness = OrderSweetnessLevel.noSugar0;
    } else if (lower.contains('kurang gula') ||
        lower.contains('kurang manis') ||
        lower.contains('setengah gula') ||
        lower.contains('less sweet') ||
        lower.contains('less sugar') ||
        lower.contains('50%')) {
      sweetness = OrderSweetnessLevel.lessSweet50;
    } else if (lower.contains('aren') || lower.contains('gula aren')) {
      sweetness = OrderSweetnessLevel.aren;
    } else if (lower.contains('karamel') || lower.contains('caramel')) {
      sweetness = OrderSweetnessLevel.caramel;
    } else if (lower.contains('vanila') || lower.contains('vanilla')) {
      sweetness = OrderSweetnessLevel.vanilla;
    } else if (lower.contains('normal') || lower.contains('100%')) {
      sweetness = OrderSweetnessLevel.normal100;
    }

    // 6. Extra Shot Detection
    bool extraShot = false;
    if (lower.contains('extra shot') ||
        lower.contains('tambah espresso') ||
        lower.contains('tambah shot') ||
        lower.contains('double shot') ||
        lower.contains('dua shot')) {
      extraShot = true;
    }

    // 7. Quantity Detection
    int quantity = 1;
    if (lower.contains('dua cup') ||
        lower.contains('2 cup') ||
        lower.contains('dua gelas') ||
        lower.contains('pesan 2') ||
        lower.contains('pesan dua')) {
      quantity = 2;
    } else if (lower.contains('tiga cup') ||
        lower.contains('3 cup') ||
        lower.contains('tiga gelas') ||
        lower.contains('pesan 3') ||
        lower.contains('pesan tiga')) {
      quantity = 3;
    }

    // 8. Food Safety & Dietary Alert Detection
    final alerts = detectDietaryAlerts(lower);

    return ParsedCafeOrderSlot(
      drinkId: drinkId,
      drinkLabelKey: drinkLabelKey,
      drinkNameId: drinkNameId,
      drinkNameEn: drinkNameEn,
      temperature: temperature,
      cupSize: cupSize,
      milkType: milkType,
      sweetnessLevel: sweetness,
      extraShot: extraShot,
      quantity: quantity,
      basePrice: basePrice,
      dietaryAlerts: alerts,
    );
  }

  /// Detects food safety, lactose, sugar, and allergy alert keywords.
  List<DietaryAlertTag> detectDietaryAlerts(String normalizedText) {
    final alerts = <DietaryAlertTag>[];

    if (normalizedText.contains('laktosa') ||
        normalizedText.contains('lactose') ||
        normalizedText.contains('intoleransi')) {
      alerts.add(
        const DietaryAlertTag(
          type: DietaryAlertType.lactoseIntolerant,
          severity: DietaryAlertSeverity.warning,
          labelKey: 'alert_lactose',
          defaultMessageId:
              'Perhatian: Pelanggan intoleransi laktosa. Gunakan Oat/Soy Milk!',
          defaultMessageEn:
              'Caution: Lactose intolerant customer. Use Oat/Soy Milk!',
          detectedKeyword: 'laktosa',
        ),
      );
    }

    if (normalizedText.contains('diabetes') ||
        normalizedText.contains('gula darah') ||
        normalizedText.contains('diabet')) {
      alerts.add(
        const DietaryAlertTag(
          type: DietaryAlertType.diabetesSugarAlert,
          severity: DietaryAlertSeverity.warning,
          labelKey: 'alert_diabetes',
          defaultMessageId:
              'Perhatian: Pelanggan diabetes. Pastikan Tanpa Gula (0%)!',
          defaultMessageEn:
              'Caution: Diabetic customer. Ensure No Sugar (0%)!',
          detectedKeyword: 'diabetes',
        ),
      );
    }

    if (normalizedText.contains('kacang') || normalizedText.contains('peanut') || normalizedText.contains('nut')) {
      alerts.add(
        const DietaryAlertTag(
          type: DietaryAlertType.nutAllergy,
          severity: DietaryAlertSeverity.critical,
          labelKey: 'alert_nut',
          defaultMessageId:
              'Peringatan Kritis: Alergi kacang! Hindari sirup almond/hazelnut!',
          defaultMessageEn:
              'Critical Alert: Nut allergy! Strictly avoid almond/hazelnut syrups!',
          detectedKeyword: 'kacang',
        ),
      );
    }

    if (normalizedText.contains('alergi susu') ||
        normalizedText.contains('dairy allergy')) {
      alerts.add(
        const DietaryAlertTag(
          type: DietaryAlertType.dairyAllergy,
          severity: DietaryAlertSeverity.critical,
          labelKey: 'alert_dairy',
          defaultMessageId:
              'Peringatan Kritis: Alergi susu sapi! Wajib gunakan plant-based milk bersih!',
          defaultMessageEn:
              'Critical Alert: Cow milk allergy! Strictly use clean plant-based milk!',
          detectedKeyword: 'alergi susu',
        ),
      );
    }

    if (normalizedText.contains('maag') ||
        normalizedText.contains('asam lambung') ||
        normalizedText.contains('gerd') ||
        normalizedText.contains('perut sakit')) {
      alerts.add(
        const DietaryAlertTag(
          type: DietaryAlertType.acidRefluxMaag,
          severity: DietaryAlertSeverity.info,
          labelKey: 'alert_maag',
          defaultMessageId:
              'Info: Pelanggan sensitif asam/maag. Rekomendasikan Low-Acid!',
          defaultMessageEn:
              'Info: Acid sensitive customer. Recommend Low-Acid roast!',
          detectedKeyword: 'maag',
        ),
      );
    }

    return alerts;
  }
}
