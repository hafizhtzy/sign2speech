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
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          tooltip: AppStrings.cafeBackTooltip.tr,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppStrings.cafeOrderQueueTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: isCompact
                  ? IconButton(
                      icon: Icon(
                        Icons.add_rounded,
                        size: 24,
                        color: AppColors.ink,
                      ),
                      tooltip: AppStrings.cafeStartNextOrder.tr,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () {
                        _controller.startNextCustomerOrder();
                        Navigator.of(context).maybePop();
                      },
                    )
                  : OutlinedButton.icon(
                      onPressed: () {
                        _controller.startNextCustomerOrder();
                        Navigator.of(context).maybePop();
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.ink,
                      ),
                      label: Text(
                        AppStrings.cafeStartNextOrder.tr,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                        side: BorderSide(color: AppColors.border, width: 1.1),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // ── Airy Minimalist Filter Pill Strip (Zero Divider Wall) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: AppStrings.cafeFilterAll.tr,
                          isSelected: _selectedFilter == null,
                          onTap: () => setState(() => _selectedFilter = null),
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: AppStrings.cafeFilterPreparing.tr,
                          isSelected: _selectedFilter == OrderStatus.preparing,
                          onTap: () => setState(
                            () => _selectedFilter = OrderStatus.preparing,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: AppStrings.cafeFilterReady.tr,
                          isSelected:
                              _selectedFilter == OrderStatus.readyForPickup,
                          onTap: () => setState(
                            () => _selectedFilter = OrderStatus.readyForPickup,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: AppStrings.cafeFilterCompleted.tr,
                          isSelected: _selectedFilter == OrderStatus.completed,
                          onTap: () => setState(
                            () => _selectedFilter = OrderStatus.completed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Orders List / Empty State ───────────────────────────────
                Expanded(
                  child: Obx(() {
                    final allOrders = _controller.activeOrdersQueue.toList();
                    final filtered = _getFilteredOrders(allOrders);

                    if (filtered.isEmpty) {
                      return _buildEmptyQueueView();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 22),
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
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.muted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQueueView() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.coffee_rounded,
                size: 38,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              AppStrings.cafeOrderQueueEmpty.tr,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                AppStrings.cafeOrderQueueEmptyDesc.tr,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  _controller.startNextCustomerOrder();
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  AppStrings.cafeStartNextOrder.tr,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
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
    final isDark = AppColors.isDark;
    final (statusColor, statusText) = switch (order.status) {
      OrderStatus.preparing => (
        AppColors.amber,
        AppStrings.cafeFilterPreparing.tr,
      ),
      OrderStatus.readyForPickup => (
        AppColors.matcha,
        AppStrings.cafeFilterReady.tr,
      ),
      OrderStatus.completed => (
        AppColors.muted,
        AppStrings.cafeFilterCompleted.tr,
      ),
      _ => (AppColors.secondary, order.status.name),
    };

    final Color ctaFg = isDark ? AppColors.darkCanvas : AppColors.textOnDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: order.status == OrderStatus.readyForPickup
              ? AppColors.matcha.withValues(alpha: 0.65)
              : AppColors.border,
          width: order.status == OrderStatus.readyForPickup ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Editorial Status Eyebrow + Timestamp (Hasil Speech-to-Sign Style)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatElapsedTime(order.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 2. Bold Editorial Queue Number & Customer Name ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                order.queueNumber,
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.orderId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.customerName.isEmpty
                ? 'Pelanggan Walk-In'
                : 'Atas Nama: ${order.customerName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ── 3. Spacious Order Items List ────────────────────────────────
          if (order.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1, color: AppColors.borderSoft),
            ),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}×',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.drinkNameId,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.cupSize.labelId} • ${item.milkType.labelId} • ${item.sweetnessLevel.labelId} • ${item.temperature.labelId}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatRupiah(item.totalPrice),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (order.customerNotes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Catatan: ${order.customerNotes}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // ── 4. Clean Total & Payment Summary ────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 16),
            child: Divider(height: 1, color: AppColors.borderSoft),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                    'Lunas • ${order.paymentMethod == OrderPaymentMethod.qris ? 'QRIS' : 'Tunai'}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.matcha,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                formatRupiah(order.grandTotal),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 5. Circular Tactile Call Dock (Hasil Speech-to-Sign Signature)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildCircularActionButton(
                  icon: Icons.volume_up_rounded,
                  label: AppStrings.cafeCallCustomerVoice.tr,
                  onTap: () =>
                      _controller.callQueueCustomer(order, isDeaf: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCircularActionButton(
                  icon: Icons.vibration_rounded,
                  label: AppStrings.cafeCallCustomerDeaf.tr,
                  accentColor: AppColors.secondary,
                  isHighlighted: true,
                  onTap: () =>
                      _controller.callQueueCustomer(order, isDeaf: true),
                ),
              ),
              if (order.status == OrderStatus.completed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCircularActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: AppStrings.delete.tr,
                    accentColor: AppColors.error,
                    onTap: () => _controller.removeOrderFromQueue(order.orderId),
                  ),
                ),
              ],
            ],
          ),

          // ── 6. Full-Width Stadium Primary Action (Hasil Speech-to-Sign Style)
          if (order.status == OrderStatus.preparing) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _controller.markOrderReadyForPickup(order),
                icon: const Icon(Icons.check_circle_rounded, size: 19),
                label: Text(
                  AppStrings.cafeMarkReady.tr,
                  style: AppTypography.labelLarge.copyWith(
                    color: ctaFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.matcha,
                  foregroundColor: ctaFg,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
          ],

          if (order.status == OrderStatus.readyForPickup) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _controller.completeOrderPickup(order.orderId),
                icon: const Icon(Icons.done_all_rounded, size: 19),
                label: Text(
                  AppStrings.cafeMarkCompleted.tr,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Circular tactile control button mirroring Hasil Speech-to-Sign's dock.
  Widget _buildCircularActionButton({
    required IconData icon,
    required String label,
    Color? accentColor,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    final Color fg = accentColor ?? AppColors.ink;
    final Color bg = isHighlighted
        ? fg.withValues(alpha: 0.12)
        : AppColors.bgSurface;
    final Color border = isHighlighted
        ? fg.withValues(alpha: 0.45)
        : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label,
          button: true,
          child: Material(
            color: bg,
            shape: CircleBorder(
              side: BorderSide(color: border, width: 1.2),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 54,
                height: 54,
                child: Center(
                  child: Icon(icon, size: 23, color: fg),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: isHighlighted ? fg : AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
