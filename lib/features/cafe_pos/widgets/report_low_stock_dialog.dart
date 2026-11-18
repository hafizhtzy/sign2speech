import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/supabase/supabase_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../data/datasources/supabase_cafe_pos_service.dart';
import '../domain/models/coffee_menu_item.dart';

/// Dialog for CASHIER to view read-only stock levels and send a Low Stock Report
/// to ADMIN without allowing direct stock modification by the cashier.
class ReportLowStockDialog extends StatefulWidget {
  final List<CoffeeMenuItem> catalog;
  final SupabaseCafePosService? posService;

  const ReportLowStockDialog({
    super.key,
    required this.catalog,
    this.posService,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CoffeeMenuItem> catalog,
    SupabaseCafePosService? posService,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReportLowStockDialog(
        catalog: catalog,
        posService: posService,
      ),
    );
  }

  @override
  State<ReportLowStockDialog> createState() => _ReportLowStockDialogState();
}

class _ReportLowStockDialogState extends State<ReportLowStockDialog> {
  CoffeeMenuItem? _selectedItem;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  SupabaseCafePosService get _service =>
      widget.posService ??
      (Get.isRegistered<SupabaseCafePosService>()
          ? Get.find<SupabaseCafePosService>()
          : SupabaseCafePosService());

  @override
  void initState() {
    super.initState();
    if (widget.catalog.isNotEmpty) {
      _selectedItem = widget.catalog.first;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final item = _selectedItem;
    final note = _noteCtrl.text.trim();
    if (item == null || note.length < 3 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.reportLowStockToAdmin(
        productId: item.id,
        reportedAvailableStock: item.availableStock,
        note: note,
      );
      if (!mounted) return;
      switch (res) {
        case SupabaseSuccess():
          Navigator.of(context).pop();
          AppSnackbar.show(
            title: AppStrings.cashierReportLowStockTitle.tr,
            message: AppStrings.cashierReportLowStockSuccess.tr,
            variant: SnackbarVariant.success,
          );
        case SupabaseFailure(:final errorMessage):
          AppSnackbar.error(
            title: AppStrings.cashierReportLowStockTitle.tr,
            message: errorMessage,
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.cashierReportLowStockTitle.tr,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  AppStrings.cashierStockReadOnlyNotice.tr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.catalog.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const Key('low_stock_product_dropdown'),
                  isExpanded: true,
                  initialValue: _selectedItem?.id,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: widget.catalog.map((item) {
                    final stockText = !item.isStockInitialized
                        ? 'Belum Opname'
                        : 'Stok: ${item.availableStock}';
                    return DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        '${item.nameId} ($stockText)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedItem = widget.catalog
                          .where((e) => e.id == val)
                          .firstOrNull;
                    });
                  },
                ),
              if (_selectedItem != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: StatusBadge(
                        label: !_selectedItem!.isStockInitialized
                            ? AppStrings.customerStockUninitialized.tr
                            : 'Tersedia: ${_selectedItem!.availableStock}',
                        variant: _selectedItem!.isLowStock ||
                                _selectedItem!.isOutOfStock
                            ? BadgeVariant.warning
                            : BadgeVariant.neutral,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                key: const Key('low_stock_note_field'),
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppStrings.cashierReportLowStockNoteHint.tr,
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.cancel.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      key: const Key('submit_low_stock_report_btn'),
                      label: AppStrings.cashierReportLowStockBtn.tr,
                      isLoading: _isSubmitting,
                      onPressed: _submitReport,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
