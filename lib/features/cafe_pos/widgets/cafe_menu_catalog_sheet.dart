import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../screens/coffee_detail_screen.dart';

enum _CatalogCategory { all, milkCoffee, blackCoffee, gentleStomach, nonCoffee }

/// Modern, editorial cafe menu catalog modal bottom sheet.
/// Provides real-time search, category filtering, temperature badges,
/// recipe tags, direct quick-add, and customization routing.
class CafeMenuCatalogSheet extends StatefulWidget {
  final List<CoffeeMenuItem> catalog;
  final void Function(CoffeeMenuItem item) onSelectItem;

  const CafeMenuCatalogSheet({
    super.key,
    this.catalog = CoffeeMenuItem.standardCatalog,
    required this.onSelectItem,
  });

  static Future<void> show({
    required BuildContext context,
    List<CoffeeMenuItem> catalog = CoffeeMenuItem.standardCatalog,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CoffeeMenuItem> get _filteredItems {
    return widget.catalog.where((item) {
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
    final isCompact = mediaQuery.size.width < 600;

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
                color: Colors.black.withValues(alpha: 0.20),
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
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCategoryPill(
                        _CatalogCategory.all,
                        AppStrings.cafeCategoryAll.tr,
                        Icons.dashboard_customize_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.milkCoffee,
                        AppStrings.cafeCategoryMilkCoffee.tr,
                        Icons.coffee_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.blackCoffee,
                        AppStrings.cafeCategoryBlackCoffee.tr,
                        Icons.local_fire_department_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.gentleStomach,
                        AppStrings.cafeCategoryGentleStomach.tr,
                        Icons.spa_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryPill(
                        _CatalogCategory.nonCoffee,
                        AppStrings.cafeCategoryNonCoffee.tr,
                        Icons.eco_rounded,
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

                // Menu Items List or Empty State
                Expanded(
                  child: _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            6,
                            20,
                            36 + bottomPadding,
                          ),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final item = _filteredItems[index];
                            return _buildModernMenuCard(
                              item: item,
                              isCompact: isCompact,
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

  Widget _buildCategoryPill(
    _CatalogCategory category,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.surface : AppColors.secondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.surface : AppColors.ink,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuCard({
    required CoffeeMenuItem item,
    required bool isCompact,
  }) {
    final isIced = item.defaultTemperature == OrderTemperature.iced;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Container with Temperature Pill
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.paleMist,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(
                        isIced
                            ? Icons.icecream_rounded
                            : Icons.coffee_rounded,
                        color: isIced ? AppColors.secondary : AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isIced
                            ? const Color(0xFF2B5B84)
                            : const Color(0xFFB34A26),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isIced ? 'ICED' : 'HOT',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 8.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title, Description, & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nameId,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.descriptionId,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price tag
                    Text(
                      formatRupiah(item.basePrice),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Recipe Composition / Tags row
          if (item.composition.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.composition.take(3).map((comp) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paleMist,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    '${comp.label} ${comp.percentage}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 10),

          // Action Buttons: Kustomisasi & + Tambah
          Row(
            children: [
              // Customize Button (Routes to CoffeeDetailScreen)
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.to(() => CoffeeDetailScreen(menuItem: item));
                    },
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    label: Text(
                      AppStrings.cafeCustomize.tr,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.secondary, width: 1.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Direct Quick-Add Button
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onSelectItem(item);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 15,
                    ),
                    label: Text(
                      AppStrings.cafeQuickAdd.tr,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
