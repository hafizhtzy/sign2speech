import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../cafe_pos/domain/models/coffee_menu_item.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../domain/models/product_category.dart';

/// Admin Product Management CRUD View (`Phase 4.1 - 4.3`).
class AdminProductsView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminProductsView({super.key, required this.controller});

  void _openProductDialog(BuildContext context, {CoffeeMenuItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.nameId ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final descCtrl = TextEditingController(text: existing?.descriptionId ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? '${existing.basePrice}' : '',
    );
    final costCtrl = TextEditingController(
      text: existing?.costPrice != null ? '${existing!.costPrice}' : '',
    );
    final minStockCtrl = TextEditingController(
      text: '${existing?.lowStockThreshold ?? 5}',
    );
    final opnameCtrl = TextEditingController();
    String selectedCategory = existing?.category ?? 'coffee';

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Tambah Produk Baru' : 'Edit Produk',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('admin_product_name_field'),
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Nama Produk *',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_product_sku_field'),
                  controller: skuCtrl,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'SKU / Kode Produk (Unik)',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedCategory,
                  dropdownColor: AppColors.bentoCardDark,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Kategori *',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'coffee',
                      child: Text('Kopi Signature'),
                    ),
                    DropdownMenuItem(
                      value: 'non_coffee',
                      child: Text('Non-Kopi & Matcha'),
                    ),
                    DropdownMenuItem(
                      value: 'snack',
                      child: Text('Camilan & Pastry'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) selectedCategory = v;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_product_price_field'),
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Harga Jual (Rp) *',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_product_cost_field'),
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Harga Modal / HPP (Rp, Opsional)',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minStockCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Ambang Minimum Stok',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (existing == null || !existing.isStockInitialized) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('admin_product_initial_opname_field'),
                    controller: opnameCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.bentoTextLight),
                    decoration: InputDecoration(
                      labelText:
                          'Stock Opname Awal (Kosongkan jika belum opname)',
                      labelStyle: TextStyle(
                        color: AppColors.bentoCardLight.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: AppColors.bentoBase,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor:
                              AppColors.bentoCardLight.withOpacity(0.8),
                          side: BorderSide(
                            color: AppColors.bentoCardLight.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppStrings.cancel.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('admin_save_product_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bentoHoney,
                          foregroundColor: AppColors.bentoTextDark,
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final price = int.tryParse(priceCtrl.text.trim());
                          final cost = costCtrl.text.trim().isEmpty
                              ? null
                              : int.tryParse(costCtrl.text.trim());
                          final minStock =
                              int.tryParse(minStockCtrl.text.trim()) ?? 5;
                          final initOpname = opnameCtrl.text.trim().isEmpty
                              ? null
                              : int.tryParse(opnameCtrl.text.trim());

                          if (name.isEmpty || price == null || price < 0) {
                            AppSnackbar.error(
                              title: 'Validasi Produk',
                              message:
                                  'Nama produk wajib diisi dan harga jual tidak boleh negatif.',
                            );
                            return;
                          }
                          if (cost != null && cost < 0) {
                            AppSnackbar.error(
                              title: 'Validasi HPP',
                              message: 'Harga modal tidak boleh negatif.',
                            );
                            return;
                          }

                          final id = existing?.id ??
                              name
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
                          final item = (existing ??
                                  CoffeeMenuItem(
                                    id: id,
                                    nameId: name,
                                    nameEn: name,
                                    descriptionId: descCtrl.text.trim(),
                                    descriptionEn: descCtrl.text.trim(),
                                    basePrice: price,
                                  ))
                              .copyWith(
                                nameId: name,
                                nameEn: name,
                                sku: skuCtrl.text.trim().isEmpty
                                    ? null
                                    : skuCtrl.text.trim(),
                                category: selectedCategory,
                                basePrice: price,
                                costPrice: cost,
                                clearCostPrice: cost == null,
                                lowStockThreshold: minStock.clamp(0, 99999),
                                descriptionId: descCtrl.text.trim(),
                                descriptionEn: descCtrl.text.trim(),
                              );

                          final ok = await controller.saveProduct(
                            item,
                            previousItem: existing,
                            initialStockOpname: initOpname,
                          );
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: Text(
                          AppStrings.save.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmArchiveToggle(BuildContext context, CoffeeMenuItem item) {
    final targetArchive = !item.isArchived;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          targetArchive ? 'Arsipkan Produk?' : 'Aktifkan Produk?',
          style: const TextStyle(
            color: AppColors.bentoTextLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          targetArchive
              ? 'Produk "${item.nameId}" akan disembunyikan dari katalog aktif namun data transaksi historis tetap aman.'
              : 'Produk "${item.nameId}" akan diaktifkan kembali pada katalog.',
          style: TextStyle(
            color: AppColors.bentoCardLight.withOpacity(0.85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel.tr,
              style: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetArchive
                  ? AppColors.bentoTerracotta
                  : AppColors.bentoMatcha,
              foregroundColor: targetArchive
                  ? AppColors.bentoTextLight
                  : AppColors.bentoTextDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.setProductArchived(item, targetArchive);
            },
            child: const Text(
              'Konfirmasi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.filteredProducts;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavProducts.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_product_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bentoHoney,
                  foregroundColor: AppColors.bentoTextDark,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _openProductDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Tambah Produk',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bentoCardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.bentoTextLight,
              ),
              onChanged: (v) => controller.productSearchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau SKU...',
                hintStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.bentoHoney,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final (key, label) in [
                  ('all', 'Semua Aktif'),
                  ('uninitialized', 'Belum Opname'),
                  ('low', 'Stok Menipis'),
                  ('out', 'Stok Habis'),
                  ('archived', 'Diarsipkan'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => controller.productStockFilter.value = key,
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: controller.productStockFilter.value == key
                              ? AppColors.bentoCardLight
                              : AppColors.bentoCardDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: AppTypography.labelMedium.copyWith(
                            color: controller.productStockFilter.value == key
                                ? AppColors.bentoTextDark
                                : AppColors.bentoCardLight.withOpacity(0.85),
                            fontWeight:
                                controller.productStockFilter.value == key
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...list.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bentoCardDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.nameId}${item.sku != null ? " (${item.sku})" : ""}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.bentoTextLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                formatRupiah(item.basePrice),
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.bentoHoney,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '• HPP: ${item.costPrice != null ? formatRupiah(item.costPrice!) : "Belum diisi"}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.bentoCardLight.withOpacity(0.65),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: !item.isStockInitialized
                                  ? AppColors.bentoTerracotta.withOpacity(0.2)
                                  : (item.isOutOfStock
                                      ? AppColors.bentoTerracotta.withOpacity(0.2)
                                      : (item.isLowStock
                                          ? AppColors.bentoHoney.withOpacity(0.2)
                                          : AppColors.bentoMatcha.withOpacity(0.2))),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              !item.isStockInitialized
                                  ? AppStrings.adminStockNotInitializedBadge.tr
                                  : 'Tersedia: ${item.availableStock} (Fisik: ${item.stockOnHand}, Reservasi: ${item.stockReserved})',
                              style: AppTypography.labelSmall.copyWith(
                                color: !item.isStockInitialized
                                    ? AppColors.bentoTerracotta
                                    : (item.isOutOfStock
                                        ? AppColors.bentoTerracotta
                                        : (item.isLowStock
                                            ? AppColors.bentoHoney
                                            : AppColors.bentoMatcha)),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openProductDialog(context, existing: item),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.bentoBase,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.bentoCardLight,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _confirmArchiveToggle(context, item),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.bentoBase,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isArchived
                              ? Icons.restore_rounded
                              : Icons.archive_outlined,
                          color: item.isArchived
                              ? AppColors.bentoMatcha
                              : AppColors.bentoCardLight.withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Admin Category Management CRUD View.
class AdminCategoriesView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminCategoriesView({super.key, required this.controller});

  void _openCategoryDialog(BuildContext context, {ProductCategory? existing}) {
    final slugCtrl = TextEditingController(text: existing?.slug ?? '');
    final nameCtrl = TextEditingController(text: existing?.nameId ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          existing == null ? 'Tambah Kategori' : 'Edit Kategori',
          style: const TextStyle(
            color: AppColors.bentoTextLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: slugCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Kode Slug (mis: manual_brew)',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Nama Kategori *',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel.tr,
              style: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bentoHoney,
              foregroundColor: AppColors.bentoTextDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (slugCtrl.text.trim().isEmpty ||
                  nameCtrl.text.trim().isEmpty) {
                return;
              }
              final cat = ProductCategory(
                id: existing?.id ?? '',
                slug: slugCtrl.text.trim(),
                nameId: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              final ok = await controller.upsertCategory(cat);
              if (ok && ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              AppStrings.save.tr,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.adminNavCategories.tr,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.bentoTextLight,
                  fontWeight: FontWeight.w900,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bentoHoney,
                  foregroundColor: AppColors.bentoTextDark,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _openCategoryDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Tambah Kategori',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...controller.categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bentoCardDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.nameId,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.bentoTextLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bentoMatcha.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.slug,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.bentoMatcha,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (c.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              c.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.bentoCardLight.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _openCategoryDialog(context, existing: c),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.bentoBase,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.bentoCardLight,
                          size: 18,
                        ),
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

/// Admin Inventory Ledger & Mandatory Stock Opname View (`Phase 4.4 - 4.5`).
class AdminInventoryView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminInventoryView({super.key, required this.controller});

  void _openStockAdjustmentDialog(BuildContext context, CoffeeMenuItem item) {
    String movementType = item.isStockInitialized
        ? 'restock'
        : 'initial_opname';
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  !item.isStockInitialized
                      ? 'Stock Opname Awal: ${item.nameId}'
                      : 'Penyesuaian Stok: ${item.nameId}',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: movementType,
                  dropdownColor: AppColors.bentoCardDark,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Jenis Penyesuaian *',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'initial_opname',
                      child: Text('Stock Opname Awal (Inisialisasi)'),
                    ),
                    DropdownMenuItem(
                      value: 'restock',
                      child: Text('Restock (+ Tambah Stok Masuk)'),
                    ),
                    DropdownMenuItem(
                      value: 'adjustment_in',
                      child: Text('Koreksi Masuk (+)'),
                    ),
                    DropdownMenuItem(
                      value: 'adjustment_out',
                      child: Text('Koreksi Keluar (-)'),
                    ),
                    DropdownMenuItem(
                      value: 'damage',
                      child: Text('Barang Rusak (-)'),
                    ),
                    DropdownMenuItem(
                      value: 'loss',
                      child: Text('Barang Hilang (-)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) movementType = v;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_stock_qty_field'),
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Unit *',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_stock_reason_field'),
                  controller: reasonCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.bentoTextLight),
                  decoration: InputDecoration(
                    labelText: 'Alasan Penyesuaian (Wajib diisi) *',
                    labelStyle: TextStyle(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: AppColors.bentoBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor:
                              AppColors.bentoCardLight.withOpacity(0.8),
                          side: BorderSide(
                            color: AppColors.bentoCardLight.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppStrings.cancel.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('admin_submit_stock_adjust_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bentoHoney,
                          foregroundColor: AppColors.bentoTextDark,
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final qty = int.tryParse(qtyCtrl.text.trim());
                          final reason = reasonCtrl.text.trim();
                          if (qty == null || reason.length < 3) {
                            AppSnackbar.error(
                              title: 'Validasi Stok',
                              message:
                                  'Jumlah unit valid dan alasan wajib diisi (minimal 3 karakter).',
                            );
                            return;
                          }
                          final ok = await controller.adjustProductStock(
                            productId: item.id,
                            movementType: movementType,
                            quantityDelta: qty,
                            reason: reason,
                          );
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                            AppSnackbar.success(
                              title: 'Stok Berhasil Diperbarui',
                              message:
                                  'Penyesuaian stok untuk ${item.nameId} telah tersimpan.',
                            );
                          } else if (controller.errorMessage.value.isNotEmpty) {
                            AppSnackbar.error(
                              title: 'Gagal Menyesuaikan Stok',
                              message: controller.errorMessage.value,
                            );
                          }
                        },
                        child: Text(
                          AppStrings.save.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.adminNavInventory.tr,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...controller.products.where((p) => !p.isArchived).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bentoCardDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nameId,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.bentoTextLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            !item.isStockInitialized
                                ? AppStrings.adminStockNotInitializedBadge.tr
                                : 'Fisik: ${item.stockOnHand} • Reservasi QRIS: ${item.stockReserved} • Tersedia: ${item.availableStock}',
                            style: AppTypography.bodySmall.copyWith(
                              color: !item.isStockInitialized
                                  ? AppColors.bentoTerracotta
                                  : AppColors.bentoCardLight.withOpacity(0.7),
                              fontWeight: !item.isStockInitialized
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: Key('adjust_stock_btn_${item.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !item.isStockInitialized
                            ? AppColors.bentoTerracotta
                            : AppColors.bentoCardLight,
                        foregroundColor: !item.isStockInitialized
                            ? AppColors.bentoTextLight
                            : AppColors.bentoTextDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        minimumSize: const Size(48, 44),
                      ),
                      onPressed: () =>
                          _openStockAdjustmentDialog(context, item),
                      child: Text(
                        !item.isStockInitialized
                            ? 'Stock Opname'
                            : 'Sesuaikan Stok',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Riwayat Pergerakan Stok (Inventory Ledger)',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (controller.movements.isEmpty)
            Text(
              'Belum ada riwayat mutasi stok tercatat.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.6),
              ),
            )
          else
            ...controller.movements.take(25).map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bentoCardDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Produk: ${m.productId} • ${m.movementType}',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.bentoTextLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (m.quantityDelta >= 0
                                      ? AppColors.bentoMatcha
                                      : AppColors.bentoTerracotta)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m.quantityDelta >= 0
                                  ? "+${m.quantityDelta}"
                                  : "${m.quantityDelta}",
                              style: AppTypography.labelSmall.copyWith(
                                color: m.quantityDelta >= 0
                                    ? AppColors.bentoMatcha
                                    : AppColors.bentoTerracotta,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok: ${m.stockBefore} → ${m.stockAfter} • Alasan: ${m.reason}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.bentoCardLight.withOpacity(0.65),
                          fontSize: 11,
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
