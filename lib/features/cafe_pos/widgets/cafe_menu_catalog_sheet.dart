import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../screens/coffee_detail_screen.dart';

enum _CatalogCategory { all, milkCoffee, blackCoffee, gentleStomach, nonCoffee }

/// Modern, editorial cafe menu catalog modal bottom sheet.
/// Provides real-time search, category filtering, temperature badges,
/// recipe tags, direct quick-add, and customization routing.
class CafeMenuCatalogSheet extends StatefulWidget {
  final List<CoffeeMenuItem>? catalog;
  final void Function(CoffeeMenuItem item) onSelectItem;

  const CafeMenuCatalogSheet({
    super.key,
    this.catalog,
    required this.onSelectItem,
  });

  static Future<void> show({
    required BuildContext context,
    List<CoffeeMenuItem>? catalog,
    required void Function(CoffeeMenuItem item) onSelectItem,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CafeMenuCatalogSheet(
        catalog: catalog,
        onSelectItem: onSelectItem,
      ),
    );
  }

  @override
  State<CafeMenuCatalogSheet> createState() => _CafeMenuCatalogSheetState();
}

class _CafeMenuCatalogSheetState extends State<CafeMenuCatalogSheet> {
  final TextEditingController _searchController = TextEditingController();
  _CatalogCategory _selectedCategory = _CatalogCategory.all;
  String _searchQuery = '';
  Worker? _catalogWorker;

  @override
  void initState() {
    super.initState();
    // Refresh cloud menus in background and listen to reactive updates
    if (Get.isRegistered<CafeCashierController>()) {
      final ctrl = Get.find<CafeCashierController>();
      _catalogWorker = ever<List<CoffeeMenuItem>>(ctrl.menuCatalog, (_) {
        if (mounted) setState(() {});
      });
      ctrl.refreshCloudMenus();
    }
  }

  @override
  void dispose() {
    _catalogWorker?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CoffeeMenuItem> get _effectiveCatalog {
    if (widget.catalog != null) return widget.catalog!;
    if (Get.isRegistered<CafeCashierController>()) {
      final ctrl = Get.find<CafeCashierController>();
      if (ctrl.menuCatalog.isNotEmpty) {
        return ctrl.menuCatalog;
      }
    }
    return CoffeeMenuItem.standardCatalog;
  }

  List<CoffeeMenuItem> get _filteredItems {
    return _effectiveCatalog.where((item) {
      // Category filter
      final matchesCategory = switch (_selectedCategory) {
        _CatalogCategory.all => true,
        _CatalogCategory.milkCoffee =>
          item.defaultMilk != OrderMilkType.none && item.id != 'matcha_latte',
        _CatalogCategory.blackCoffee =>
          item.id == 'americano' || item.tags.contains('hitam'),
        _CatalogCategory.gentleStomach =>
          item.id == 'low_acid_latte' ||
              item.tags.contains('lambung') ||
              item.tags.contains('maag'),
        _CatalogCategory.nonCoffee =>
          item.id == 'matcha_latte' || item.tags.contains('tanpa kopi'),
      };

      if (!matchesCategory) return false;

      // Search query filter
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final inName = item.nameId.toLowerCase().contains(q) ||
          item.nameEn.toLowerCase().contains(q);
      final inDesc = item.descriptionId.toLowerCase().contains(q) ||
          item.descriptionEn.toLowerCase().contains(q);
      final inTags = item.tags.any((t) => t.toLowerCase().contains(q));
      final inComp = item.composition.any(
        (c) =>
            c.label.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q),
      );

      return inName || inDesc || inTags || inComp;
    }).toList();
  }

  void _resetSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = _CatalogCategory.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final sheetHeight = mediaQuery.size.height * 0.90;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.local_cafe_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.cafeCatalogTitle.tr,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.cafeCatalogSubtitle.tr,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.muted,
                        tooltip: AppStrings.cancel.tr,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.bgSurface,
                          minimumSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Modern Search Input Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.cafeCatalogSearchHint.tr,
                        hintStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: AppColors.muted,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // Category Pills Selector
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCategoryPill(
                        _CatalogCategory.all,
                        AppStrings.cafeCategoryAll.tr,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.milkCoffee,
                        AppStrings.cafeCategoryMilkCoffee.tr,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.blackCoffee,
                        AppStrings.cafeCategoryBlackCoffee.tr,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.gentleStomach,
                        AppStrings.cafeCategoryGentleStomach.tr,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.nonCoffee,
                        AppStrings.cafeCategoryNonCoffee.tr,
                      ),
                    ],
                  ),
                ),

                // Item Count Info Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.cafeItemsAvailable.trParams({
                          'count': _filteredItems.length.toString(),
                        }),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_searchQuery.isNotEmpty ||
                          _selectedCategory != _CatalogCategory.all)
                        GestureDetector(
                          onTap: _resetSearch,
                          child: Text(
                            AppStrings.cafeResetSearch.tr,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 8, indent: 20, endIndent: 20),

                // Menu Items Grid or Empty State (reactive to cloud sync via worker)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final items = _filteredItems;
                      return items.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                36 + bottomPadding,
                              ),
                              // Adaptif: 2 kolom di HP, 3 kolom di tablet/sheet lebar.
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 230,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: 272,
                              ),
                              itemCount: items.length,
                              itemBuilder: (ctx, index) {
                                return _buildMenuGridCard(items[index]);
                              },
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pill kategori gaya minimal: tanpa ikon & border.
  /// Aktif = caramel solid + teks putih, non-aktif = latte foam + teks ink.
  Widget _buildCategoryPill(_CatalogCategory category, String label) {
    final isSelected = _selectedCategory == category;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? AppColors.surface : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kartu menu grid bergaya editorial: foto besar membulat, badge suhu
  /// di pojok foto, nama, subjudul komposisi, harga, dan tombol "+" persegi.
  /// Tap kartu = buka kustomisasi; tap "+" = tambah langsung ke nota.
  Widget _buildMenuGridCard(CoffeeMenuItem item) {
    final subtitle = item.composition.isNotEmpty
        ? item.composition.first.label
        : (item.tags.isNotEmpty ? item.tags.first : item.category);

    return Semantics(
      button: true,
      label: '${item.nameId}, ${formatRupiah(item.basePrice)}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            Get.to(() => CoffeeDetailScreen(menuItem: item));
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto menu + badge suhu
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildMenuImage(item),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildRatingBadge(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nama menu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      item.nameId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subjudul (komposisi utama)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Harga + tombol tambah
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatRupiah(item.basePrice),
                              maxLines: 1,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildQuickAddButton(item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tombol "+" persegi caramel. Visual 40 dp, area sentuh 48 dp.
  Widget _buildQuickAddButton(CoffeeMenuItem item) {
    return Tooltip(
      message: AppStrings.cafeQuickAdd.tr,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onSelectItem(item);
              Navigator.of(context).pop();
            },
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.surface,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Badge rating bintang (★ 4.8) di pojok kanan atas foto persis referensi desain kartu modern.
  Widget _buildRatingBadge(CoffeeMenuItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cameraDark.withValues(alpha: 0.55),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 13,
            color: AppColors.amber,
          ),
          const SizedBox(width: 3),
          Text(
            '4.8',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Foto menu dari Supabase Storage (`menu-photos`) bila tersedia,
  /// fallback ke placeholder ilustratif bertema latte.
  Widget _buildMenuImage(CoffeeMenuItem item) {
    final placeholder = _buildImagePlaceholder(item);
    if (!item.hasNetworkImage) return placeholder;
    return CachedNetworkImage(
      imageUrl: item.imageUrl!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => Container(color: AppColors.paleMist),
      errorWidget: (_, _, _) => placeholder,
    );
  }

  Widget _buildImagePlaceholder(CoffeeMenuItem item) {
    final isIced = item.defaultTemperature == OrderTemperature.iced;
    final isFood = item.category == 'snack';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.paleMist,
            AppColors.secondary.withValues(alpha: 0.28),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isFood
              ? Icons.bakery_dining_rounded
              : (isIced ? Icons.local_drink_rounded : Icons.coffee_rounded),
          size: 52,
          color: AppColors.secondary.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.coffee_maker_outlined,
                size: 36,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.cafeMenuNotFound.tr,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.cafeMenuNotFoundDesc.tr,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetSearch,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(AppStrings.cafeResetSearch.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
