import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';
import 'package:speech2sign/core/widgets/responsive_layout.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../data/datasources/cafe_pos_local_data_source.dart';
import '../domain/models/coffee_customization_draft.dart';
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
  bool _isFavorite = false;

  BisindoTtsService get _ttsService => Get.isRegistered<BisindoTtsService>()
      ? Get.find<BisindoTtsService>()
      : BisindoTtsService();

  CafePosLocalDataSource get _localDataSource =>
      Get.isRegistered<CafePosLocalDataSource>()
          ? Get.find<CafePosLocalDataSource>()
          : CafePosLocalDataSource();

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

    _loadSavedDraft();
  }

  Future<void> _loadSavedDraft() async {
    final draft = await _localDataSource.loadCustomizationDraft(item.id);
    if (draft != null && mounted) {
      setState(() {
        _temperature = draft.temperature;
        _cupSize = draft.cupSize;
        _milkType = draft.milkType;
        _sweetness = draft.sweetness;
        _extraShot = draft.extraShot;
      });
    }
  }

  void _saveCurrentDraft() {
    final draft = CoffeeCustomizationDraft(
      drinkId: item.id,
      temperature: _temperature,
      cupSize: _cupSize,
      milkType: _milkType,
      sweetness: _sweetness,
      extraShot: _extraShot,
      quantity: _quantity,
      updatedAt: DateTime.now(),
    );
    _localDataSource.saveCustomizationDraft(draft);
  }

  Future<void> _resetToDefaultRecipe() async {
    HapticFeedback.lightImpact();
    setState(() {
      _temperature = item.defaultTemperature;
      _cupSize = OrderCupSize.medium;
      _milkType = item.defaultMilk;
      _sweetness = item.defaultSweetness;
      _extraShot = false;
    });
    await _localDataSource.clearCustomizationDraft(item.id);
    try {
      AppSnackbar.show(
        title: 'Resep Direset',
        message: 'Pengaturan kopi dikembalikan ke standar ${item.nameId}',
        variant: SnackbarVariant.info,
      );
    } catch (_) {}
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
    final sizeStr = _cupSize.labelId;
    final milkStr = _milkType.labelId;
    final sweetStr = _sweetness.labelId;
    final shotStr = _extraShot ? ', Extra Shot Espresso' : '';
    return '$_quantity cup ${item.nameId} $tempStr, ukuran $sizeStr, $milkStr, $sweetStr$shotStr.';
  }

  void _speakPreview() {
    HapticFeedback.lightImpact();
    _ttsService.speak(_orderSentencePreview, languageCode: 'id-ID');
  }

  Future<void> _sendToCashier() async {
    HapticFeedback.mediumImpact();
    final slot = _currentSlot;
    final controller = Get.isRegistered<CafeCashierController>()
        ? Get.find<CafeCashierController>()
        : Get.put(
            CafeCashierController(
              localDataSource: _localDataSource,
            ),
          );

    final canPop = Navigator.of(context).canPop();
    controller.addItemToTicket(slot);
    await _localDataSource.clearCustomizationDraft(item.id);

    try {
      AppSnackbar.show(
        title: 'Pesanan Ditambahkan',
        message: '${slot.quantity}x ${item.nameId} masuk ke antrean kasir',
        variant: SnackbarVariant.success,
      );
    } catch (_) {}

    if (canPop) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.cafeCashierCounter);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            children: [
              // 1. Pinned Curved Header (Never scrolls away)
              _buildCurvedHeader(),

              // 2. Scrollable Recipe Customization Section
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Circular Coffee Image & 3 Curved Composition Points
                      CoffeeCompositionCircle(item: item),

                      const SizedBox(height: 18),

                      // Tasting / Dietary tags
                      if (item.tags.isNotEmpty) ...[
                        Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: item.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paleMist,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Description Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          item.descriptionId,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Temperature Selector
                      _buildTemperatureSelector(),

                      const SizedBox(height: 22),

                      // Cup Size Selector (Small, Medium, Large)
                      _buildCupSizeSelector(),

                      const SizedBox(height: 22),

                      // Customization Options: Milk Type & Sweetness & Extra Shot
                      _buildCustomizationPanel(),

                      const SizedBox(height: 20),

                      // Order Sentence TTS/Sign Preview Bar
                      _buildSentencePreviewBar(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 3. Dark Bottom Checkout Bar with ">>>>" and "Kirim ke Kasir"
              _buildDarkBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.cameraDark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
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
          Expanded(
            child: Text(
              AppStrings.cafeCoffeeDetailTitle.tr,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _resetToDefaultRecipe,
                icon: const Icon(Icons.restart_alt_rounded),
                color: AppColors.surface.withValues(alpha: 0.8),
                tooltip: 'Reset Standar',
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                  HapticFeedback.selectionClick();
                },
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite ? AppColors.amber : AppColors.surface,
                ),
                tooltip: 'Favorit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTempButton(
            title: 'ICED (DINGIN)',
            icon: Icons.ac_unit_rounded,
            isSelected: _temperature == OrderTemperature.iced,
            activeColor: AppColors.primary,
            activeIconColor: const Color(0xFF60A5FA),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _temperature = OrderTemperature.iced);
              _saveCurrentDraft();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTempButton(
            title: 'HOT (HANGAT)',
            icon: Icons.local_fire_department_rounded,
            isSelected: _temperature == OrderTemperature.hot,
            activeColor: AppColors.primary,
            activeIconColor: AppColors.amber,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _temperature = OrderTemperature.hot);
              _saveCurrentDraft();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTempButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeIconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: Material(
        color: isSelected ? activeColor : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? activeColor : AppColors.border,
                width: 1.4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? activeIconColor : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? AppColors.surface : AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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
    return Column(
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
                iconSize: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSizeCard(
                title: 'Medium',
                sub: '12oz / 350ml',
                size: OrderCupSize.medium,
                iconSize: 26,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSizeCard(
                title: 'Large',
                sub: '16oz / 500ml',
                size: OrderCupSize.large,
                iconSize: 30,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeCard({
    required String title,
    required String sub,
    required OrderCupSize size,
    required double iconSize,
  }) {
    final isSelected = _cupSize == size;
    return Material(
      color: isSelected ? AppColors.secondary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _cupSize = size);
          _saveCurrentDraft();
        },

        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_cafe_rounded,
                size: iconSize,
                color: isSelected ? AppColors.surface : AppColors.secondary,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  sub,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? AppColors.paleMist : AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Milk Type Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Jenis Susu (Milk Type)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 135),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OrderMilkType>(
                    value: _milkType,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.secondary),
                    items: OrderMilkType.values.map((milk) {
                      return DropdownMenuItem(
                        value: milk,
                        child: Text(
                          milk.labelId,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _milkType = val);
                        _saveCurrentDraft();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border, height: 1),
          ),

          // 2. Sweetness Level Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tingkat Manis (Sweetness)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 135),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OrderSweetnessLevel>(
                    value: _sweetness,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.secondary),
                    items: OrderSweetnessLevel.values.map((sweet) {
                      return DropdownMenuItem(
                        value: sweet,
                        child: Text(
                          sweet.labelId,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _sweetness = val);
                        _saveCurrentDraft();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border, height: 1),
          ),

          // 3. Extra Shot Switch Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extra Espresso Shot (+${formatRupiah(5000)})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rasa kopi lebih pekat dan tinggi kafein',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _extraShot,
                activeThumbColor: AppColors.secondary,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _extraShot = val);
                  _saveCurrentDraft();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentencePreviewBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
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
                const SizedBox(height: 3),
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
            icon: const Icon(Icons.volume_up_rounded),
            color: AppColors.secondary,
            tooltip: 'Dengarkan Suara',
          ),
        ],
      ),
    );
  }

  Widget _buildDarkBottomBar() {
    final total = _currentSlot.totalPrice;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cameraDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(total),
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
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _sendToCashier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
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
                              color: AppColors.surface.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
