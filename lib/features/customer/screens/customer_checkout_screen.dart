import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/controllers/auth_controller.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/status_badge.dart';
import '../../cafe_pos/bindings/cafe_pos_binding.dart';
import '../../cafe_pos/controllers/cafe_cashier_controller.dart';
import '../../cafe_pos/domain/models/coffee_menu_item.dart';
import '../../cafe_pos/widgets/cafe_order_ticket_card.dart';
import '../controllers/customer_order_controller.dart';
import '../domain/models/qris_payment_record.dart';

/// Customer Self-Order, Cart Checkout, QRIS Payment, and Own Order History Screen.
/// Strictly enforces CUSTOMER permissions (no Cashier/Admin controls).
class CustomerCheckoutScreen extends StatefulWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CustomerOrderController _controller;
  final TextEditingController _nameCtrl = TextEditingController();
  TextEditingController? _tableNumberCtrlInternal;
  TextEditingController get _tableNumberCtrl =>
      _tableNumberCtrlInternal ??= TextEditingController();
  TextEditingController? _pairingCodeCtrlInternal;
  TextEditingController get _pairingCodeCtrl =>
      _pairingCodeCtrlInternal ??= TextEditingController(
        text: CafeCashierController.defaultCounterId,
      );
  final TextEditingController _notesCtrl = TextEditingController();
  RxBool? _isCounterPairingModeInternal;
  RxBool get _isCounterPairingMode =>
      _isCounterPairingModeInternal ??= false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = Get.isRegistered<CustomerOrderController>()
        ? Get.find<CustomerOrderController>()
        : Get.put(CustomerOrderController());

    if (_controller.selectedTableNumber.value.isNotEmpty) {
      _tableNumberCtrl.text = _controller.selectedTableNumber.value;
    }

    if (Get.isRegistered<AuthController>()) {
      final profile = Get.find<AuthController>().currentProfile.value;
      if (profile != null && profile.fullName.isNotEmpty) {
        _nameCtrl.text = profile.fullName;
        _controller.watchCustomerOrders(profile.id);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _tableNumberCtrlInternal?.dispose();
    _pairingCodeCtrlInternal?.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePairWithCashier() async {
    final code = _pairingCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      AppSnackbar.error(
        title: AppStrings.customerCounterPairingTitle.tr,
        message: AppStrings.customerCounterPairingRequired.tr,
      );
      return;
    }

    if (!Get.isRegistered<CafeCashierController>()) {
      CafePosBinding().dependencies();
    }
    final cafeCtrl = Get.find<CafeCashierController>();
    await cafeCtrl.joinRoomSession(code);
    if (!mounted) return;
    AppSnackbar.success(
      title: AppStrings.customerCounterPairingTitle.tr,
      message: AppStrings.customerCounterPairedSuccess.trParams({'code': code}),
    );
    Get.toNamed(AppRoutes.cafeCashierCounter);
  }

  Future<void> _handleCheckout() async {
    final tableNumber = _tableNumberCtrl.text.trim();
    _controller.selectedTableNumber.value = tableNumber;
    final payment = await _controller.checkoutAndCreateQris(
      customerName: _nameCtrl.text.trim(),
      tableNumber: tableNumber,
      customerNotes: _notesCtrl.text.trim(),
      requireTableNumber: true,
    );
    if (!mounted) return;
    if (payment != null) {
      _showQrisDialog(payment);
    } else if (_controller.errorMessage.value.isNotEmpty) {
      AppSnackbar.error(
        title: AppStrings.customerCartTitle.tr,
        message: _controller.errorMessage.value,
      );
    }
  }

  void _showQrisDialog(QrisPaymentRecord initialPayment) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              final payment = _controller.activePayment.value ?? initialPayment;
              final qrImageUrl = payment.resolvedQrImageUrl;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          AppStrings.customerPayQrisBtn.tr,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (payment.isSimulation)
                        const StatusBadge(
                          label: 'SIMULASI SANDBOX',
                          variant: BadgeVariant.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order ID: ${payment.orderId} • ${formatRupiah(payment.grossAmount)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (payment.isPaid) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.matcha,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pembayaran QRIS Terverifikasi!',
                      textAlign: .center,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.matcha,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: qrImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: qrImageUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) => CustomPaint(
                                painter: QrisMatrixPainter(
                                  seed: payment.qrString ?? payment.orderId,
                                ),
                              ),
                            )
                          : CustomPaint(
                              painter: QrisMatrixPainter(
                                seed: payment.qrString ?? payment.orderId,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status: ${payment.status.toUpperCase()}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    label: AppStrings.ok.tr,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppStrings.customerOrderCardTitle.tr,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.secondary,
          tabs: [
            Tab(text: AppStrings.customerMenuTitle.tr),
            Tab(text: AppStrings.customerOrdersTitle.tr),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCatalogAndCartTab(context),
            _buildMyOrdersTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogAndCartTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: ResponsiveContentWrapper(
        maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderLocationModeCard(context),
            const SizedBox(height: 18),
            Obx(() {
              final items = _controller.filteredCatalog;
              if (_controller.isLoadingCatalog.value && items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (items.isEmpty) {
                return EmptyStateView(
                  icon: Icons.coffee_outlined,
                  title: AppStrings.customerMenuTitle.tr,
                  subtitle: AppStrings.customerMenuSubtitle.tr,
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisExtent: 215,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemBuilder: (ctx, idx) => _buildMenuCard(items[idx]),
              );
            }),
            const SizedBox(height: 24),
            Obx(() {
              if (_controller.cartItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.customerCartTitle.tr,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_controller.cartItems.length, (i) {
                      final slot = _controller.cartItems[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${slot.quantity}x ${slot.drinkNameId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              formatRupiah(slot.totalPrice),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                onPressed: () =>
                                    _controller.decrementCartSlot(i),
                                icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    TextField(
                      key: const Key('customer_cart_table_number_input'),
                      controller: _tableNumberCtrl,
                      onChanged: (v) =>
                          _controller.selectedTableNumber.value = v.trim(),
                      decoration: InputDecoration(
                        labelText: AppStrings.customerTableNumberLabel.tr,
                        hintText: AppStrings.customerTableNumberHint.tr,
                        prefixIcon: Icon(
                          Icons.table_restaurant_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.authFullNameLabel.tr,
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Text(
                          AppStrings.cafeGrandTotal.tr,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          formatRupiah(_controller.cartGrandTotal),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      key: const Key('customer_checkout_submit_btn'),
                      label: AppStrings.customerCheckoutBtn.tr,
                      isLoading: _controller.isSubmittingCheckout.value,
                      onPressed: _handleCheckout,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderLocationModeCard(BuildContext context) {
    return Obx(() {
      final isPairingMode = _isCounterPairingMode.value;
      final selectedTable = _controller.selectedTableNumber.value;

      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Switcher: Order dari Tempat Duduk vs Tablet Meja Kasir (Pairing)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('mode_table_seat_tab'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _isCounterPairingMode.value = false,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: !isPairingMode
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_restaurant_rounded,
                              size: 16,
                              color: !isPairingMode
                                  ? AppColors.textOnDark
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppStrings.customerOrderModeTable.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: !isPairingMode
                                      ? AppColors.textOnDark
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: InkWell(
                      key: const Key('mode_counter_tablet_pairing_tab'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _isCounterPairingMode.value = true,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isPairingMode
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sync_alt_rounded,
                              size: 16,
                              color: isPairingMode
                                  ? AppColors.textOnDark
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppStrings.customerOrderModeCounterTablet.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isPairingMode
                                      ? AppColors.textOnDark
                                      : AppColors.muted,
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
            ),
            const SizedBox(height: 16),
            if (!isPairingMode) ...[
              Text(
                AppStrings.customerTableNumberLabel.tr,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('customer_table_number_input'),
                controller: _tableNumberCtrl,
                onChanged: (val) =>
                    _controller.selectedTableNumber.value = val.trim(),
                decoration: InputDecoration(
                  hintText: AppStrings.customerTableNumberHint.tr,
                  prefixIcon: Icon(
                    Icons.table_restaurant_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CustomerOrderController.quickTableNumbers.map((tbl) {
                  final isSelected = selectedTable == tbl;
                  return InkWell(
                    key: Key('quick_table_chip_$tbl'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _tableNumberCtrl.text = tbl;
                      _controller.selectedTableNumber.value = tbl;
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        minWidth: 72,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tbl,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.textOnDark
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                AppStrings.customerCounterPairingTitle.tr,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.customerCounterPairingDesc.tr,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('customer_pairing_code_input'),
                controller: _pairingCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: AppStrings.customerCounterPairingCodeHint.tr,
                  prefixIcon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                key: const Key('customer_pair_cashier_btn'),
                label: AppStrings.customerCounterPairBtn.tr,
                icon: Icons.sync_alt_rounded,
                onPressed: _handlePairWithCashier,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMenuCard(CoffeeMenuItem item) {
    final stockBadgeLabel = !item.isStockInitialized
        ? AppStrings.customerStockUninitialized.tr
        : item.isOutOfStock
        ? AppStrings.customerStockOut.tr
        : AppStrings.customerStockAvailable.trParams({
            'count': '${item.availableStock}',
          });

    final canOrder = item.canBeOrderedWithControlledStock;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: .spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nameId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(item.basePrice),
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: StatusBadge(
                  label: stockBadgeLabel,
                  variant: canOrder
                      ? (item.isLowStock
                            ? BadgeVariant.warning
                            : BadgeVariant.success)
                      : BadgeVariant.neutral,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              item.descriptionId,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () =>
                      Get.toNamed(AppRoutes.coffeeDetail, arguments: item),
                  child: const Text('Detail'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  key: Key('add_to_cart_${item.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnDark,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: canOrder
                      ? () {
                          final added = _controller.addToCart(item);
                          if (!added &&
                              _controller.errorMessage.value.isNotEmpty) {
                            AppSnackbar.error(
                              title: item.nameId,
                              message: _controller.errorMessage.value,
                            );
                          }
                        }
                      : null,
                  child: const Text('+ Keranjang'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersTab(BuildContext context) {
    return Obx(() {
      final orders = _controller.myOrders;
      if (orders.isEmpty) {
        return EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: AppStrings.customerOrdersTitle.tr,
          subtitle: 'Belum ada riwayat pesanan pada akun Anda.',
        );
      }
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final order = orders[idx];
          return AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.queueNumber} • ${order.orderId}',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${order.status.name} • Pembayaran: ${order.paymentStatus}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(order.grandTotal),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
