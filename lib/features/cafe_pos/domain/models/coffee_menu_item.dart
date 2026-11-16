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
  final String? imageUrl;
  final String? storagePath;
  final String? signVideoUrl;
  final String category;
  final bool isAvailable;
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
    this.imageUrl,
    this.storagePath,
    this.signVideoUrl,
    this.category = 'coffee',
    this.isAvailable = true,
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

  bool get hasNetworkImage =>
      imageUrl != null &&
      imageUrl!.trim().isNotEmpty &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  List<String> get compositionPoints => composition.map((c) => c.label).toList();

  CoffeeMenuItem copyWith({
    String? id,
    String? nameId,
    String? nameEn,
    String? descriptionId,
    String? descriptionEn,
    int? basePrice,
    String? imagePath,
    String? imageUrl,
    String? storagePath,
    String? signVideoUrl,
    String? category,
    bool? isAvailable,
    List<String>? tags,
    OrderTemperature? defaultTemperature,
    OrderMilkType? defaultMilk,
    OrderSweetnessLevel? defaultSweetness,
    List<CoffeeCompositionPoint>? composition,
  }) {
    return CoffeeMenuItem(
      id: id ?? this.id,
      nameId: nameId ?? this.nameId,
      nameEn: nameEn ?? this.nameEn,
      descriptionId: descriptionId ?? this.descriptionId,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      basePrice: basePrice ?? this.basePrice,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      storagePath: storagePath ?? this.storagePath,
      signVideoUrl: signVideoUrl ?? this.signVideoUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      defaultTemperature: defaultTemperature ?? this.defaultTemperature,
      defaultMilk: defaultMilk ?? this.defaultMilk,
      defaultSweetness: defaultSweetness ?? this.defaultSweetness,
      composition: composition ?? this.composition,
    );
  }

  /// Serializes to PostgreSQL `cafe_menus` snake_case column format.
  Map<String, dynamic> toPostgresMap() {
    return <String, dynamic>{
      'id': id,
      'name': nameId,
      'category': category,
      'price': basePrice,
      'description': descriptionId,
      'image_url': imageUrl,
      'image_path': storagePath ?? (hasNetworkImage ? null : imagePath),
      'sign_video_url': signVideoUrl,
      'is_available': isAvailable,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Creates a [CoffeeMenuItem] from a PostgreSQL `cafe_menus` row, merging with
  /// [standardCatalog] metadata if the ID matches a built-in menu item.
  factory CoffeeMenuItem.fromMap(Map<String, dynamic> map) {
    final rawId = (map['id'] ?? '').toString();
    final standardMatch = standardCatalog.cast<CoffeeMenuItem?>().firstWhere(
          (item) => item?.id == rawId,
          orElse: () => null,
        );

    final rawName =
        (map['name'] ?? map['nameId'] ?? standardMatch?.nameId ?? rawId)
            .toString();
    final rawDesc = (map['description'] ??
            map['descriptionId'] ??
            standardMatch?.descriptionId ??
            '')
        .toString();
    final rawPrice =
        ((map['price'] ?? map['basePrice'] ?? standardMatch?.basePrice ?? 0)
                as num)
            .toInt();
    final rawCategory =
        (map['category'] ?? standardMatch?.category ?? 'coffee').toString();
    final rawImageUrl = (map['image_url'] ?? map['imageUrl'])?.toString();
    final rawImagePath = (map['image_path'] ?? map['imagePath'])?.toString();
    final rawSignVideoUrl =
        (map['sign_video_url'] ?? map['signVideoUrl'])?.toString();
    final rawAvailable =
        (map['is_available'] ?? map['isAvailable'] ?? true) == true;

    return CoffeeMenuItem(
      id: rawId,
      nameId: rawName,
      nameEn: (map['nameEn'] ?? standardMatch?.nameEn ?? rawName).toString(),
      descriptionId: rawDesc,
      descriptionEn:
          (map['descriptionEn'] ?? standardMatch?.descriptionEn ?? rawDesc)
              .toString(),
      basePrice: rawPrice,
      imagePath: standardMatch?.imagePath ??
          'assets/komponen_img/Gambar ChatGPT 13 Okt 2026, 19.01.58-1.png',
      imageUrl:
          (rawImageUrl != null && rawImageUrl.isNotEmpty) ? rawImageUrl : null,
      storagePath: (rawImagePath != null &&
              rawImagePath.isNotEmpty &&
              !rawImagePath.startsWith('assets/'))
          ? rawImagePath
          : null,
      signVideoUrl: (rawSignVideoUrl != null && rawSignVideoUrl.isNotEmpty)
          ? rawSignVideoUrl
          : null,
      category: rawCategory,
      isAvailable: rawAvailable,
      tags: standardMatch?.tags ?? const [],
      defaultTemperature:
          standardMatch?.defaultTemperature ?? OrderTemperature.hot,
      defaultMilk: standardMatch?.defaultMilk ?? OrderMilkType.oatMilk,
      defaultSweetness:
          standardMatch?.defaultSweetness ?? OrderSweetnessLevel.normal100,
      composition: standardMatch?.composition ??
          const [
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
    );
  }

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
    CoffeeMenuItem(
      id: 'pisang_goreng',
      nameId: 'Pisang Goreng Crispy',
      nameEn: 'Crispy Fried Banana',
      descriptionId:
          'Pisang kepok pilihan berbalut tepung renyah keemasan, manis gurih alami.',
      descriptionEn:
          'Golden crispy fried banana fritters with natural sweet and savory crunch.',
      basePrice: 20000,
      tags: ['makanan', 'snack', 'manis', 'renyah', 'pisang', 'goreng'],
      defaultTemperature: OrderTemperature.hot,
      defaultMilk: OrderMilkType.none,
      defaultSweetness: OrderSweetnessLevel.normal100,
      composition: [
        CoffeeCompositionPoint(
          label: 'Pisang Kepok',
          percentage: '75%',
          description: 'Pisang kepok manis ranum',
        ),
        CoffeeCompositionPoint(
          label: 'Crispy Batter',
          percentage: '25%',
          description: 'Adonan tepung crispy keemasan',
        ),
      ],
    ),
  ];
}
