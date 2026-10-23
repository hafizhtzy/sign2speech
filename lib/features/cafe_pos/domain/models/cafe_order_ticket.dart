import 'dietary_alert_tag.dart';
import 'order_enums.dart';
import 'parsed_cafe_order_slot.dart';

class CafeOrderTicket {
  final String orderId;
  final String queueNumber; // e.g. "A-108"
  final String customerName; // e.g. "Rian"
  final List<ParsedCafeOrderSlot> items;
  final OrderStatus status;
  final OrderPaymentMethod paymentMethod;
  final int amountPaid;
  final DateTime createdAt;

  const CafeOrderTicket({
    required this.orderId,
    required this.queueNumber,
    this.customerName = '',
    required this.items,
    this.status = OrderStatus.draft,
    this.paymentMethod = OrderPaymentMethod.qris,
    this.amountPaid = 0,
    required this.createdAt,
  });

  /// Total sum of all items in ticket.
  int get subtotal =>
      items.fold<int>(0, (sum, item) => sum + item.totalPrice);

  /// 10% PB1 tax or service.
  int get taxAmount => (subtotal * 0.10).round();

  /// Grand total amount to be paid.
  int get grandTotal => subtotal + taxAmount;

  /// Change to be returned when paying cash.
  int get changeAmount =>
      (amountPaid >= grandTotal) ? (amountPaid - grandTotal) : 0;

  /// Aggregated list of all dietary alerts across all order items.
  List<DietaryAlertTag> get allDietaryAlerts {
    final alerts = <DietaryAlertTag>[];
    for (final item in items) {
      for (final alert in item.dietaryAlerts) {
        if (!alerts.contains(alert)) {
          alerts.add(alert);
        }
      }
    }
    return alerts;
  }

  CafeOrderTicket copyWith({
    String? orderId,
    String? queueNumber,
    String? customerName,
    List<ParsedCafeOrderSlot>? items,
    OrderStatus? status,
    OrderPaymentMethod? paymentMethod,
    int? amountPaid,
    DateTime? createdAt,
  }) {
    return CafeOrderTicket(
      orderId: orderId ?? this.orderId,
      queueNumber: queueNumber ?? this.queueNumber,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
