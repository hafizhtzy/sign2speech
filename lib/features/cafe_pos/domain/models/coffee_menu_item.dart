import 'order_enums.dart';

class CoffeeCompositionPoint {
  final String label;
  final String percentage;
  final String description;

  const CoffeeCompositionPoint({
    required this.label,
    required this.percentage,
    required this.description,
  });
}

class CoffeeMenuItem {
  final String id;
  final String nameId;
  final String nameEn;
  final String descriptionId;
  final String descriptionEn;
  final int basePrice;
  final String imagePath;
  final List<String> tags;
  final OrderTemperature defaultTemperature;
  final OrderMilkType defaultMilk;
  final OrderSweetnessLevel defaultSweetness;
  final List<CoffeeCompositionPoint> composition;

  const CoffeeMenuItem({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.basePrice,
    this.imagePath = 'assets/komponen_img/Gambar ChatGPT 13 Okt 2026, 19.01.58-1.png',
    this.tags = const [],
    this.defaultTemperature = OrderTemperature.hot,
    this.defaultMilk = OrderMilkType.oatMilk,
    this.defaultSweetness = OrderSweetnessLevel.normal100,
    this.composition = const [
      CoffeeCompositionPoint(
        label: 'Oat Milk',
        percentage: '60%',
        description: 'Susu oat creamy barista grade',
      ),
      CoffeeCompositionPoint(
        label: 'Microfoam',
        percentage: '20%',
        description: 'Busa sutra lembut',
      ),
      CoffeeCompositionPoint(
        label: 'Espresso',
        percentage: '20%',
        description: 'Double shot arabika lokal',
      ),
    ],
  });

  List<String> get compositionPoints => composition.map((c) => c.label).toList();

  static const List<CoffeeMenuItem> standardCatalog = [
    CoffeeMenuItem(
      id: 'cappuccino',
      nameId: 'Oat Cappuccino',
      nameEn: 'Oat Cappuccino',
      descriptionId:
          'Kombinasi espresso seimbang dengan microfoam susu oat yang tebal dan lembut.',
      descriptionEn:
          'Balanced espresso paired with thick, velvety steamed oat microfoam.',
      basePrice: 32000,
      tags: ['creamy', 'lembut', 'hangat', 'tidak pahit', 'foam'],
      defaultTemperature: OrderTemperature.hot,
      defaultMilk: OrderMilkType.oatMilk,
      defaultSweetness: OrderSweetnessLevel.lessSweet50,
      composition: [
        CoffeeCompositionPoint(
          label: 'Microfoam',
          percentage: '35%',
          description: 'Busa susu oat tebal lembut',
        ),
        CoffeeCompositionPoint(
          label: 'Steamed Oat',
          percentage: '35%',
          description: 'Susu oat hangat gurih',
        ),
        CoffeeCompositionPoint(
          label: 'Espresso',
          percentage: '30%',
          description: 'Single origin espresso shot',
        ),
      ],
    ),
    CoffeeMenuItem(
      id: 'iced_caramel_latte',
      nameId: 'Iced Oat Caramel Latte',
      nameEn: 'Iced Oat Caramel Latte',
      descriptionId:
          'Sensasi dingin menyegarkan dengan saus karamel artisanal dan susu oat gurih.',
      descriptionEn:
          'Chilled refreshing espresso with artisan caramel drizzle and oat milk.',
      basePrice: 35000,
      tags: ['dingin', 'segar', 'manis', 'karamel', 'es'],
      defaultTemperature: OrderTemperature.iced,
      defaultMilk: OrderMilkType.oatMilk,
      defaultSweetness: OrderSweetnessLevel.caramel,
      composition: [
        CoffeeCompositionPoint(
          label: 'Oat Milk & Ice',
          percentage: '60%',
          description: 'Oat milk dingin dengan es batu kristal',
        ),
        CoffeeCompositionPoint(
          label: 'Caramel Sauce',
          percentage: '15%',
          description: 'Saus karamel legit wangi',
        ),
        CoffeeCompositionPoint(
          label: 'Espresso',
          percentage: '25%',
          description: 'Double shot espresso',
        ),
      ],
    ),
    CoffeeMenuItem(
      id: 'kopi_susu_aren',
      nameId: 'Double Shot Kopi Susu Aren',
      nameEn: 'Double Shot Palm Sugar Coffee',
      descriptionId:
          'Kopi susu otentik Indonesia dengan gula aren murni organik dan double shot espresso.',
      descriptionEn:
          'Authentic Indonesian palm sugar latte with double shot intense espresso.',
      basePrice: 28000,
      tags: ['ngantuk', 'kuat', 'kerja', 'fokus', 'aren', 'energi'],
      defaultTemperature: OrderTemperature.iced,
      defaultMilk: OrderMilkType.freshDairy,
      defaultSweetness: OrderSweetnessLevel.aren,
      composition: [
        CoffeeCompositionPoint(
          label: 'Fresh Dairy Milk',
          percentage: '50%',
          description: 'Susu pasteurisasi segar',
        ),
        CoffeeCompositionPoint(
          label: 'Gula Aren Organik',
          percentage: '15%',
          description: 'Gula aren cair harum',
        ),
        CoffeeCompositionPoint(
          label: 'Double Espresso',
          percentage: '35%',
          description: 'Ekstra kafein intens',
        ),
      ],
    ),
    CoffeeMenuItem(
      id: 'low_acid_latte',
      nameId: 'Low-Acid Oat Latte',
      nameEn: 'Low-Acid Oat Latte',
      descriptionId:
          'Dirancang khusus menggunakan biji cold-drip minim asam, aman di lambung maag.',
      descriptionEn:
          'Crafted with slow-dripped low acid coffee, gentle on sensitive stomachs.',
      basePrice: 34000,
      tags: ['sakit', 'perut', 'maag', 'asam', 'lambung', 'sehat'],
      defaultTemperature: OrderTemperature.hot,
      defaultMilk: OrderMilkType.oatMilk,
      defaultSweetness: OrderSweetnessLevel.noSugar0,
      composition: [
        CoffeeCompositionPoint(
          label: 'Steamed Oat Milk',
          percentage: '70%',
          description: 'Susu oat ramah lambung',
        ),
        CoffeeCompositionPoint(
          label: 'Low-Acid Shot',
          percentage: '20%',
          description: 'Ekstraksi rendah asam',
        ),
        CoffeeCompositionPoint(
          label: 'Silky Foam',
          percentage: '10%',
          description: 'Lapisan busa tipis',
        ),
      ],
    ),
    CoffeeMenuItem(
      id: 'matcha_latte',
      nameId: 'Uji Matcha Oat Latte',
      nameEn: 'Uji Matcha Oat Latte',
      descriptionId:
          'Matcha murni dari Kyoto dipadukan dengan kelembutan oat milk hangat tanpa kafein kopi.',
      descriptionEn:
          'Pure Kyoto Uji matcha combined with silky smooth oat milk, non-coffee delight.',
      basePrice: 34000,
      tags: ['matcha', 'sehat', 'tanpa kopi', 'hijau', 'tenang'],
      defaultTemperature: OrderTemperature.hot,
      defaultMilk: OrderMilkType.oatMilk,
      defaultSweetness: OrderSweetnessLevel.lessSweet50,
      composition: [
        CoffeeCompositionPoint(
          label: 'Oat Milk',
          percentage: '70%',
          description: 'Susu oat hangat gurih',
        ),
        CoffeeCompositionPoint(
          label: 'Kyoto Matcha',
          percentage: '20%',
          description: 'Bubuk matcha whisk asli',
        ),
        CoffeeCompositionPoint(
          label: 'Matcha Foam',
          percentage: '10%',
          description: 'Busa matcha lembut',
        ),
      ],
    ),
    CoffeeMenuItem(
      id: 'americano',
      nameId: 'Caffè Americano',
      nameEn: 'Caffè Americano',
      descriptionId:
          'Kopi hitam murni dengan crema tebal, citarasa floral dan clean aftertaste.',
      descriptionEn:
          'Pure long black espresso with rich golden crema and clean floral finish.',
      basePrice: 25000,
      tags: ['hitam', 'pahit', 'tanpa susu', 'kalori rendah', 'diet'],
      defaultTemperature: OrderTemperature.iced,
      defaultMilk: OrderMilkType.none,
      defaultSweetness: OrderSweetnessLevel.noSugar0,
      composition: [
        CoffeeCompositionPoint(
          label: 'Filtered Water / Ice',
          percentage: '70%',
          description: 'Air murni bersuhu stabil',
        ),
        CoffeeCompositionPoint(
          label: 'Espresso Crema',
          percentage: '30%',
          description: 'Double espresso crema',
        ),
      ],
    ),
  ];
}
