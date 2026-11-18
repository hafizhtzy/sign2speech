import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/supabase/supabase_result.dart';
import '../../cafe_pos/domain/models/cafe_order_ticket.dart';
import '../../cafe_pos/domain/models/coffee_menu_item.dart';
import '../../cafe_pos/domain/models/order_enums.dart';
import '../../cafe_pos/domain/models/parsed_cafe_order_slot.dart';
import '../data/customer_order_service.dart';
import '../domain/models/qris_payment_record.dart';

/// GetX Controller for `CUSTOMER` role catalog browsing, cart validation against
/// initialized stock (`availableStock`), atomic reservation checkout, and QRIS tracking.
class CustomerOrderController extends GetxController {
  final CustomerOrderService _orderService;

  final RxList<CoffeeMenuItem> catalog = <CoffeeMenuItem>[].obs;
  final RxList<ParsedCafeOrderSlot> cartItems = <ParsedCafeOrderSlot>[].obs;
  final RxList<CafeOrderTicket> myOrders = <CafeOrderTicket>[].obs;
  final Rxn<QrisPaymentRecord> activePayment = Rxn<QrisPaymentRecord>();
  final RxBool isLoadingCatalog = false.obs;
  final RxBool isSubmittingCheckout = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedCategory = 'all'.obs;
  RxString? _selectedTableNumber;
  RxString get selectedTableNumber => _selectedTableNumber ??= ''.obs;

  static const List<String> quickTableNumbers = [
    'Meja 01',
    'Meja 02',
    'Meja 03',
    'Meja 04',
    'Meja 05',
    'Meja 06',
    'Meja 07',
    'Meja 08',
  ];

  StreamSubscription<QrisPaymentRecord?>? _paymentSub;
  StreamSubscription<List<CafeOrderTicket>>? _ordersSub;

  CustomerOrderController({
    CustomerOrderService? orderService,
    List<CoffeeMenuItem>? initialCatalogForTest,
  }) : _orderService = orderService ?? CustomerOrderService() {
    if (initialCatalogForTest != null) {
      catalog.assignAll(initialCatalogForTest);
    }
  }

  int get cartSubtotal =>
      cartItems.fold<int>(0, (sum, slot) => sum + slot.totalPrice);

  int get cartTaxAmount => (cartSubtotal * 0.10).round();

  int get cartGrandTotal => cartSubtotal + cartTaxAmount;

  int get cartTotalUnits =>
      cartItems.fold<int>(0, (sum, slot) => sum + slot.quantity);

  List<CoffeeMenuItem> get filteredCatalog {
    final cat = selectedCategory.value;
    return catalog.where((item) {
      if (item.isArchived) return false;
      if (cat == 'all') return true;
      return item.category == cat;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (catalog.isEmpty) {
      loadCatalog();
    }
    loadMyOrders();
  }

  Future<void> loadCatalog() async {
    isLoadingCatalog.value = true;
    errorMessage.value = '';
    try {
      final res = await _orderService.fetchActiveCatalog();
      switch (res) {
        case SupabaseSuccess(:final data):
          catalog.assignAll(data);
        case SupabaseFailure(:final errorMessage):
          this.errorMessage.value = errorMessage;
      }
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  Future<void> loadMyOrders() async {
    final res = await _orderService.fetchMyOrders();
    if (res is SupabaseSuccess<List<CafeOrderTicket>>) {
      myOrders.assignAll(res.data);
    }
  }

  void watchCustomerOrders(String userId) {
    _ordersSub?.cancel();
    _ordersSub = _orderService.streamMyOrders(userId).listen(
      (orders) => myOrders.assignAll(orders),
      onError: (_) {},
    );
  }

  /// Checks how many units of [productId] are already in the customer's cart.
  int quantityInCartForProduct(String productId) {
    return cartItems
        .where((s) => s.drinkId == productId)
        .fold<int>(0, (sum, s) => sum + s.quantity);
  }

  /// Validates stock opname initialization and available stock before adding to cart.
  bool addToCart(
    CoffeeMenuItem item, {
    int quantity = 1,
    OrderTemperature? temperature,
    OrderCupSize cupSize = OrderCupSize.medium,
    OrderMilkType? milkType,
    OrderSweetnessLevel? sweetness,
    bool extraShot = false,
  }) {
    errorMessage.value = '';

    if (item.isArchived || !item.isAvailable) {
      errorMessage.value = 'Produk "${item.nameId}" sedang tidak aktif.';
      return false;
    }

    if (!item.isStockInitialized) {
      errorMessage.value =
          'Stok "${item.nameId}" belum diopname oleh Admin dan belum dapat dipesan.';
      return false;
    }

    final existingQty = quantityInCartForProduct(item.id);
    if (existingQty + quantity > item.availableStock) {
      errorMessage.value =
          'Stok "${item.nameId}" tersisa ${item.availableStock} unit.';
      return false;
    }

    final temp = temperature ?? item.defaultTemperature;
    final milk = milkType ?? item.defaultMilk;
    final sweet = sweetness ?? item.defaultSweetness;

    final matchIndex = cartItems.indexWhere(
      (s) =>
          s.drinkId == item.id &&
          s.temperature == temp &&
          s.cupSize == cupSize &&
          s.milkType == milk &&
          s.sweetnessLevel == sweet &&
          s.extraShot == extraShot,
    );

    if (matchIndex >= 0) {
      final current = cartItems[matchIndex];
      cartItems[matchIndex] = current.copyWith(
        quantity: current.quantity + quantity,
      );
    } else {
      cartItems.add(
        ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          basePrice: item.basePrice,
          quantity: quantity,
          temperature: temp,
          cupSize: cupSize,
          milkType: milk,
          sweetnessLevel: sweet,
          extraShot: extraShot,
        ),
      );
    }
    return true;
  }

  void decrementCartSlot(int index) {
    if (index < 0 || index >= cartItems.length) return;
    final current = cartItems[index];
    if (current.quantity <= 1) {
      cartItems.removeAt(index);
    } else {
      cartItems[index] = current.copyWith(quantity: current.quantity - 1);
    }
  }

  void clearCart() {
    cartItems.clear();
  }

  /// Submits the cart via `rpc_create_order_with_reservation` and requests a
  /// Midtrans / Sandbox QRIS payment charge.
  Future<QrisPaymentRecord?> checkoutAndCreateQris({
    required String customerName,
    String tableNumber = '',
    String customerNotes = '',
    bool requireTableNumber = false,
  }) async {
    if (isSubmittingCheckout.value) return null;
    if (cartItems.isEmpty) {
      errorMessage.value = 'Keranjang pesanan masih kosong.';
      return null;
    }

    final resolvedTable = tableNumber.trim().isNotEmpty
        ? tableNumber.trim()
        : selectedTableNumber.value.trim();
    if (requireTableNumber && resolvedTable.isEmpty) {
      errorMessage.value = AppStrings.customerTableRequiredWarning.tr;
      return null;
    }

    final baseName = customerName.trim().isEmpty
        ? 'Pelanggan'
        : customerName.trim();
    final formattedCustomerName = resolvedTable.isNotEmpty
        ? '$baseName ($resolvedTable)'
        : baseName;
    final formattedNotes = resolvedTable.isNotEmpty
        ? (customerNotes.trim().isEmpty
              ? 'Meja: $resolvedTable'
              : '[Meja: $resolvedTable] ${customerNotes.trim()}')
        : customerNotes.trim();

    isSubmittingCheckout.value = true;
    errorMessage.value = '';
    try {
      final rand = Random();
      final orderId =
          'ORD-${DateTime.now().millisecondsSinceEpoch}-${100 + rand.nextInt(899)}';
      final queueNumber = 'C-${100 + rand.nextInt(899)}';

      final orderRes = await _orderService.createOrderWithReservation(
        orderId: orderId,
        queueNumber: queueNumber,
        customerName: formattedCustomerName,
        customerNotes: formattedNotes,
        items: cartItems.toList(),
        paymentMethod: 'qris',
        orderSource: 'customer_app',
      );

      switch (orderRes) {
        case SupabaseFailure(:final errorMessage):
          this.errorMessage.value = errorMessage;
          return null;
        case SupabaseSuccess():
          break;
      }

      final grossAmount = cartGrandTotal;
      final qrisRes = await _orderService.requestQrisCharge(
        orderId,
        fallbackGrossAmount: grossAmount,
      );
      return switch (qrisRes) {
        SupabaseSuccess(:final data) => () {
          activePayment.value = data;
          clearCart();
          _watchPaymentStatus(orderId);
          unawaited(loadCatalog());
          unawaited(loadMyOrders());
          return data;
        }(),
        SupabaseFailure(:final errorMessage) => () {
          this.errorMessage.value = errorMessage;
          return null;
        }(),
      };
    } finally {
      isSubmittingCheckout.value = false;
    }
  }

  void _watchPaymentStatus(String orderId) {
    _paymentSub?.cancel();
    _paymentSub = _orderService.streamPaymentForOrder(orderId).listen(
      (payment) {
        if (payment != null) {
          activePayment.value = payment;
          if (payment.isPaid || payment.isExpiredOrFailed) {
            unawaited(loadMyOrders());
            unawaited(loadCatalog());
          }
        }
      },
      onError: (_) {},
    );
  }

  @override
  void onClose() {
    _paymentSub?.cancel();
    _ordersSub?.cancel();
    super.onClose();
  }
}
