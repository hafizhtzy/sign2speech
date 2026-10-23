import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/widgets/responsive_layout.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../domain/models/parsed_cafe_order_slot.dart';
import '../widgets/coffee_composition_circle.dart';

class CoffeeDetailScreen extends StatefulWidget {
  final CoffeeMenuItem? menuItem;

  const CoffeeDetailScreen({super.key, this.menuItem});

  @override
  State<CoffeeDetailScreen> createState() => _CoffeeDetailScreenState();
}

class _CoffeeDetailScreenState extends State<CoffeeDetailScreen> {
  late final CoffeeMenuItem item;

  late OrderTemperature _temperature;
  late OrderCupSize _cupSize;
  late OrderMilkType _milkType;
  late OrderSweetnessLevel _sweetness;
  bool _extraShot = false;
  final int _quantity = 1;

  BisindoTtsService get _ttsService => Get.isRegistered<BisindoTtsService>()
      ? Get.find<BisindoTtsService>()
      : BisindoTtsService();

  @override
  void initState() {
    super.initState();
    item = widget.menuItem ??
        (Get.arguments is CoffeeMenuItem
            ? Get.arguments as CoffeeMenuItem
            : CoffeeMenuItem.standardCatalog.first);

    _temperature = item.defaultTemperature;
    _cupSize = OrderCupSize.medium;
    _milkType = item.defaultMilk;
    _sweetness = item.defaultSweetness;
  }

  ParsedCafeOrderSlot get _currentSlot {
    return ParsedCafeOrderSlot(
      drinkId: item.id,
      drinkLabelKey: item.id,
      drinkNameId: item.nameId,
      drinkNameEn: item.nameEn,
      temperature: _temperature,
      cupSize: _cupSize,
      milkType: _milkType,
      sweetnessLevel: _sweetness,
      extraShot: _extraShot,
      quantity: _quantity,
      basePrice: item.basePrice,
    );
  }

  String get _orderSentencePreview {
    final tempStr = _temperature == OrderTemperature.hot ? 'Panas' : 'Dingin';
    final sizeStr = _cupSize == OrderCupSize.small
        ? 'Small 8oz'
        : _cupSize == OrderCupSize.medium
            ? 'Medium 12oz'
            : 'Large 16oz';
    final milkStr = _milkType == OrderMilkType.none
        ? 'Tanpa Susu'
        : _milkType == OrderMilkType.soyMilk
            ? 'Soy Milk'
            : _milkType == OrderMilkType.freshDairy
                ? 'Fresh Dairy'
                : 'Oat Milk';
    final sweetStr = _sweetness == OrderSweetnessLevel.noSugar0
        ? 'Tanpa Gula 0%'
        : _sweetness == OrderSweetnessLevel.normal100
            ? 'Gula Normal'
            : _sweetness == OrderSweetnessLevel.aren
                ? 'Gula Aren'
                : _sweetness == OrderSweetnessLevel.caramel
                    ? 'Karamel'
                    : 'Gula 50%';

    final shotStr = _extraShot ? ', Extra Shot Espresso' : '';
    return '$_quantity cup ${item.nameId} $tempStr, ukuran $sizeStr, $milkStr, $sweetStr$shotStr.';
  }

  void _speakPreview() {
    _ttsService.speak(_orderSentencePreview, languageCode: 'id-ID');
  }

  void _sendToCashier() {
    final slot = _currentSlot;
    if (Get.isRegistered<CafeCashierController>()) {
      Get.find<CafeCashierController>().addItemToTicket(slot);
    }
    // Navigate or go to cashier counter
    Get.toNamed(AppRoutes.cafeCashierCounter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dark Curved Header with Back & Title
                      _buildCurvedHeader(),

                      const SizedBox(height: 16),

                      // Circular Coffee Image & 3 Curved Composition Points
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CoffeeCompositionCircle(item: item),
                      ),

                      const SizedBox(height: 18),

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          item.descriptionId,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Temperature Selector
                      _buildTemperatureSelector(),

                      const SizedBox(height: 20),

                      // Cup Size Selector (Small, Medium, Large)
                      _buildCupSizeSelector(),

                      const SizedBox(height: 20),

                      // Customization Options: Milk Type & Sweetness & Extra Shot
                      _buildCustomizationPanel(),

                      const SizedBox(height: 18),

                      // Order Sentence TTS/Sign Preview Bar
                      _buildSentencePreviewBar(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Dark Bottom Checkout Bar with ">>>>" and "Kirim ke Kasir"
              _buildDarkBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.cameraDark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.surface,
            tooltip: 'Kembali',
          ),
          Text(
            AppStrings.cafeCoffeeDetailTitle.tr,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
            color: AppColors.surface,
            tooltip: 'Favorit',
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildTempButton(
              title: 'ICED (DINGIN)',
              icon: Icons.ac_unit_rounded,
              isSelected: _temperature == OrderTemperature.iced,
              onTap: () => setState(() => _temperature = OrderTemperature.iced),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTempButton(
              title: 'HOT (HANGAT)',
              icon: Icons.local_fire_department_rounded,
              isSelected: _temperature == OrderTemperature.hot,
              onTap: () => setState(() => _temperature = OrderTemperature.hot),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.surface : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCupSizeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UKURAN GELAS (CUP SIZE)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSizeCard(
                  title: 'Small',
                  sub: '8oz / 250ml',
                  size: OrderCupSize.small,
                  heightFactor: 0.8,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSizeCard(
                  title: 'Medium',
                  sub: '12oz / 350ml',
                  size: OrderCupSize.medium,
                  heightFactor: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSizeCard(
                  title: 'Large',
                  sub: '16oz / 500ml',
                  size: OrderCupSize.large,
                  heightFactor: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeCard({
    required String title,
    required String sub,
    required OrderCupSize size,
    required double heightFactor,
  }) {
    final isSelected = _cupSize == size;
    return Material(
      color: isSelected ? AppColors.secondary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _cupSize = size),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.local_cafe_rounded,
                size: 24 * heightFactor,
                color: isSelected ? AppColors.surface : AppColors.secondary,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.paleMist : AppColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Milk Type Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jenis Susu (Milk Type)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<OrderMilkType>(
                  value: _milkType,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surface,
                  items: OrderMilkType.values.map((milk) {
                    return DropdownMenuItem(
                      value: milk,
                      child: Text(
                        milk.name.toUpperCase(),
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _milkType = val);
                  },
                ),
              ],
            ),
            Divider(color: AppColors.border),

            // Sweetness Level Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tingkat Manis (Sweetness)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<OrderSweetnessLevel>(
                  value: _sweetness,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surface,
                  items: OrderSweetnessLevel.values.map((sweet) {
                    return DropdownMenuItem(
                      value: sweet,
                      child: Text(
                        sweet.name.toUpperCase(),
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _sweetness = val);
                  },
                ),
              ],
            ),
            Divider(color: AppColors.border),

            // Extra Shot Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extra Espresso Shot (+Rp 5.000)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rasa kopi lebih pekat dan tinggi kafein',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _extraShot,
                  activeThumbColor: AppColors.secondary,
                  onChanged: (val) => setState(() => _extraShot = val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentencePreviewBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.record_voice_over,
                size: 20,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRATINJAU KALIMAT PESANAN (TTS & ISYARAT)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _orderSentencePreview,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _speakPreview,
              icon: const Icon(Icons.volume_up),
              color: AppColors.secondary,
              tooltip: 'Dengarkan Suara',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkBottomBar() {
    final total = _currentSlot.totalPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
      decoration: BoxDecoration(
        color: AppColors.cameraDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // Price and Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Harga',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.paleMist,
                ),
              ),
              Text(
                'Rp $total',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Send to Cashier with ">>>>" indicator
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _sendToCashier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.cafeSendToCashier.tr,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '>>>>',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
