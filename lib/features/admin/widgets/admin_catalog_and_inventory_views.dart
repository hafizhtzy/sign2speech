import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('admin_product_name_field'),
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Produk *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_product_sku_field'),
                  controller: skuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'SKU / Kode Produk (Unik)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori *'),
                  items: const [
                    DropdownMenuItem(value: 'coffee', child: Text('Kopi Signature')),
                    DropdownMenuItem(value: 'non_coffee', child: Text('Non-Kopi & Matcha')),
                    DropdownMenuItem(value: 'snack', child: Text('Camilan & Pastry')),
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
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual (Rp) *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_product_cost_field'),
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Modal / HPP (Rp, Opsional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ambang Minimum Stok',
                  ),
                ),
                if (existing == null || !existing.isStockInitialized) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('admin_product_initial_opname_field'),
                    controller: opnameCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Opname Awal (Kosongkan jika belum opname)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppStrings.cancel.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        key: const Key('admin_save_product_btn'),
                        label: AppStrings.save.tr,
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
        title: Text(targetArchive ? 'Arsipkan Produk?' : 'Aktifkan Produk?'),
        content: Text(
          targetArchive
              ? 'Produk "${item.nameId}" akan disembunyikan dari katalog aktif namun data transaksi historis tetap aman.'
              : 'Produk "${item.nameId}" akan diaktifkan kembali pada katalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.setProductArchived(item, targetArchive);
            },
            child: const Text('Konfirmasi'),
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
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavProducts.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('admin_add_product_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnDark,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _openProductDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Produk'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => controller.productSearchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Cari nama produk atau SKU...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (key, label) in [
                ('all', 'Semua Aktif'),
                ('uninitialized', 'Belum Opname'),
                ('low', 'Stok Menipis'),
                ('out', 'Stok Habis'),
                ('archived', 'Diarsipkan'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: controller.productStockFilter.value == key,
                  onSelected: (_) => controller.productStockFilter.value = key,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...list.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.nameId} ${item.sku != null ? "(${item.sku})" : ""}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Harga Jual: ${formatRupiah(item.basePrice)} • HPP: ${item.costPrice != null ? formatRupiah(item.costPrice!) : "Belum diisi"}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusBadge(
                            label: !item.isStockInitialized
                                ? AppStrings.adminStockNotInitializedBadge.tr
                                : 'Tersedia: ${item.availableStock} (Fisik: ${item.stockOnHand}, Reservasi: ${item.stockReserved})',
                            variant: !item.isStockInitialized || item.isLowStock
                                ? BadgeVariant.warning
                                : (item.isOutOfStock
                                      ? BadgeVariant.error
                                      : BadgeVariant.success),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit Produk',
                      onPressed: () =>
                          _openProductDialog(context, existing: item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: item.isArchived ? 'Aktifkan' : 'Arsipkan',
                      onPressed: () => _confirmArchiveToggle(context, item),
                      icon: Icon(
                        item.isArchived
                            ? Icons.restore_rounded
                            : Icons.archive_outlined,
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
        title: Text(existing == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: slugCtrl,
              decoration: const InputDecoration(
                labelText: 'Kode Slug (mis: manual_brew)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kategori *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
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
            child: Text(AppStrings.save.tr),
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
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                AppStrings.adminNavCategories.tr,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnDark,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _openCategoryDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Kategori'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...controller.categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.nameId} (${c.slug})',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (c.description.isNotEmpty)
                            Text(
                              c.description,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _openCategoryDialog(context, existing: c),
                      icon: const Icon(Icons.edit_outlined),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: movementType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Penyesuaian *',
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
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Unit *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_stock_reason_field'),
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Penyesuaian (Wajib diisi) *',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(AppStrings.cancel.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        key: const Key('admin_submit_stock_adjust_btn'),
                        label: AppStrings.save.tr,
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
                          }
                        },
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
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...controller.products.where((p) => !p.isArchived).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
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
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            !item.isStockInitialized
                                ? AppStrings.adminStockNotInitializedBadge.tr
                                : 'Fisik: ${item.stockOnHand} • Reservasi QRIS: ${item.stockReserved} • Tersedia: ${item.availableStock}',
                            style: AppTypography.bodySmall.copyWith(
                              color: !item.isStockInitialized
                                  ? AppColors.amber
                                  : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      key: Key('adjust_stock_btn_${item.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !item.isStockInitialized
                            ? AppColors.amber
                            : AppColors.primary,
                        foregroundColor: AppColors.textOnDark,
                        minimumSize: const Size(48, 44),
                      ),
                      onPressed: () =>
                          _openStockAdjustmentDialog(context, item),
                      child: Text(
                        !item.isStockInitialized
                            ? 'Stock Opname'
                            : 'Sesuaikan Stok',
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
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (controller.movements.isEmpty)
            Text(
              'Belum ada riwayat mutasi stok tercatat.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            )
          else
            ...controller.movements.take(25).map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produk: ${m.productId} • Tipe: ${m.movementType} (${m.quantityDelta >= 0 ? "+${m.quantityDelta}" : m.quantityDelta})',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Stok sebelum: ${m.stockBefore} → Stok setelah: ${m.stockAfter} • Alasan: ${m.reason}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
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
