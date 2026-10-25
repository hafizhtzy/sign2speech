import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/utils/currency_formatter.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/cafe_order_ticket.dart';
import '../domain/models/order_enums.dart';

/// Halaman & Dialog Manajemen Antrean Pesanan Kafe (Best Practice Multi-Device Responsive).
/// Menampilkan daftar pesanan yang sedang diproses, siap diambil, atau selesai.
class CafeOrderQueueScreen extends StatefulWidget {
  final CafeCashierController? controller;

  const CafeOrderQueueScreen({super.key, this.controller});

  /// Helper untuk membuka antrean dalam bentuk Dialog responsif di tablet/desktop
  /// atau Bottom Sheet / Full Screen di layar ponsel.
  static Future<void> showAsDialog(BuildContext context, {CafeCashierController? controller}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ctrl = controller ?? Get.find<CafeCashierController>();

    if (screenWidth >= 700) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.canvas,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 800),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CafeOrderQueueScreen(controller: ctrl),
            ),
          ),
        ),
      );
    } else {
      return Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (ctx) => CafeOrderQueueScreen(controller: ctrl),
        ),
      );
    }
  }

  @override
  State<CafeOrderQueueScreen> createState() => _CafeOrderQueueScreenState();
}

class _CafeOrderQueueScreenState extends State<CafeOrderQueueScreen> {
  late final CafeCashierController _controller;
  OrderStatus? _selectedFilter; // null = Semua

  @override
  void initState() {
    super.initState();
    AppTranslations.ensureLoaded();
    _controller = widget.controller ?? Get.find<CafeCashierController>();
  }

  List<CafeOrderTicket> _getFilteredOrders(List<CafeOrderTicket> allOrders) {
    if (_selectedFilter == null) {
      return allOrders;
    }
    return allOrders.where((t) => t.status == _selectedFilter).toList();
  }

  String _formatElapsedTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) {
      return AppStrings.cafeOrderElapsedSeconds.tr;
    } else {
      return AppStrings.cafeOrderElapsedMinutes.trParams({'minutes': '${diff.inMinutes}'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.ink,
            tooltip: AppStrings.cafeBackTooltip.tr,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    AppStrings.cafeOrderQueueTitle.tr,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 16 : 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Obx(() {
                  final count = _controller.activeOrdersQueue.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  );
                }),
              ],
            ),
            Text(
              AppStrings.cafeOrderQueueSubtitle.tr,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.normal,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Button Catat Pesanan Selanjutnya (Touch Target >= 48x48)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 48,
              child: isCompact
                  ? IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.secondary,
                      tooltip: AppStrings.cafeStartNextOrder.tr,
                      onPressed: () {
                        _controller.startNextCustomerOrder();
                        Navigator.of(context).maybePop();
                      },
                    )
                  : TextButton.icon(
                      onPressed: () {
                        _controller.startNextCustomerOrder();
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text(
                        AppStrings.cafeStartNextOrder.tr,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.bgSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            children: [
              // ── Filter Chips Bar ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: AppStrings.cafeFilterAll.tr,
                        isSelected: _selectedFilter == null,
                        count: _controller.activeOrdersQueue.length,
                        onTap: () => setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: AppStrings.cafeFilterPreparing.tr,
                        isSelected: _selectedFilter == OrderStatus.preparing,
                        colorAccent: AppColors.amber,
                        count: _controller.activeOrdersQueue
                            .where((t) => t.status == OrderStatus.preparing)
                            .length,
                        onTap: () => setState(() => _selectedFilter = OrderStatus.preparing),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: AppStrings.cafeFilterReady.tr,
                        isSelected: _selectedFilter == OrderStatus.readyForPickup,
                        colorAccent: AppColors.matcha,
                        count: _controller.activeOrdersQueue
                            .where((t) => t.status == OrderStatus.readyForPickup)
                            .length,
                        onTap: () =>
                            setState(() => _selectedFilter = OrderStatus.readyForPickup),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: AppStrings.cafeFilterCompleted.tr,
                        isSelected: _selectedFilter == OrderStatus.completed,
                        colorAccent: AppColors.primary,
                        count: _controller.activeOrdersQueue
                            .where((t) => t.status == OrderStatus.completed)
                            .length,
                        onTap: () => setState(() => _selectedFilter = OrderStatus.completed),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.border),

              // ── Orders List / Empty State ─────────────────────────────────
              Expanded(
                child: Obx(() {
                  final allOrders = _controller.activeOrdersQueue.toList();
                  final filtered = _getFilteredOrders(allOrders);

                  if (filtered.isEmpty) {
                    return _buildEmptyQueueView();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _buildQueueOrderCard(order);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int count,
    Color? colorAccent,
  }) {
    final activeColor = colorAccent ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.surface : AppColors.ink,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surface.withValues(alpha: 0.25)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueView() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.coffee_rounded,
                size: 40,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.cafeOrderQueueEmpty.tr,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                AppStrings.cafeOrderQueueEmptyDesc.tr,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  _controller.startNextCustomerOrder();
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                label: Text(
                  AppStrings.cafeStartNextOrder.tr,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueOrderCard(CafeOrderTicket order) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.preparing:
        statusColor = AppColors.amber;
        statusText = AppStrings.cafeFilterPreparing.tr;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case OrderStatus.readyForPickup:
        statusColor = AppColors.matcha;
        statusText = AppStrings.cafeFilterReady.tr;
        statusIcon = Icons.notifications_active_rounded;
        break;
      case OrderStatus.completed:
        statusColor = AppColors.muted;
        statusText = AppStrings.cafeFilterCompleted.tr;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      default:
        statusColor = AppColors.secondary;
        statusText = order.status.name;
        statusIcon = Icons.info_outline;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: order.status == OrderStatus.readyForPickup
              ? AppColors.matcha
              : AppColors.border,
          width: order.status == OrderStatus.readyForPickup ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: order.status == OrderStatus.readyForPickup
                ? AppColors.matcha.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card Header ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Queue Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.queueNumber,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName.isEmpty
                            ? 'Pelanggan Walk-In'
                            : 'Atas Nama: ${order.customerName}',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            _formatElapsedTime(order.createdAt),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${order.orderId}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: AppColors.surface),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Items Breakdown ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.drinkNameId,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.cupSize.labelId} • ${item.milkType.labelId} • ${item.sweetnessLevel.labelId} • ${item.temperature.labelId}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.totalPrice),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (order.customerNotes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Catatan: ${order.customerNotes}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),

                // Total and Payment Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          order.paymentMethod == OrderPaymentMethod.qris
                              ? Icons.qr_code_rounded
                              : Icons.payments_rounded,
                          size: 16,
                          color: AppColors.matcha,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lunas (${order.paymentMethod == OrderPaymentMethod.qris ? 'QRIS' : 'Tunai'})',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.matcha,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${formatRupiah(order.grandTotal)}',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Actions Footer Bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSurface.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Panggil Pelanggan Suara (TTS)
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.callQueueCustomer(order, isDeaf: false),
                    icon: const Icon(Icons.volume_up_rounded, size: 18),
                    label: Text(
                      AppStrings.cafeCallCustomerVoice.tr,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),

                // Panggil Teman Tuli (Visual & Getar)
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.callQueueCustomer(order, isDeaf: true),
                    icon: const Icon(Icons.vibration_rounded, size: 18),
                    label: Text(
                      AppStrings.cafeCallCustomerDeaf.tr,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),

                // Tandai Siap Diambil
                if (order.status == OrderStatus.preparing)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _controller.markOrderReadyForPickup(order),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        AppStrings.cafeMarkReady.tr,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.matcha,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        elevation: 0,
                      ),
                    ),
                  ),

                // Serahkan / Selesai
                if (order.status == OrderStatus.readyForPickup)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _controller.completeOrderPickup(order.orderId),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: Text(
                        AppStrings.cafeMarkCompleted.tr,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        elevation: 0,
                      ),
                    ),
                  ),

                // Hapus dari antrean jika selesai
                if (order.status == OrderStatus.completed)
                  SizedBox(
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () => _controller.removeOrderFromQueue(order.orderId),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        AppStrings.delete.tr,
                        style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
