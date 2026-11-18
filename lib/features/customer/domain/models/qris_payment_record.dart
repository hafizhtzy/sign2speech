import 'package:flutter/foundation.dart';

/// Immutable representation of a QRIS / Cash payment record from `public.payments`.
/// Supports Midtrans Core API `actions` (`generate-qr-code-v2` / `generate-qr-code`)
/// as well as optional `qr_string` and explicit `isSimulation` differentiation.
@immutable
class QrisPaymentRecord {
  final String id;
  final String orderId;
  final String provider; // 'midtrans', 'cash', 'sandbox_simulator'
  final bool isSimulation;
  final String paymentMethod;
  final String? midtransOrderId;
  final String? midtransTransactionId;
  final int grossAmount;
  final String status; // 'pending', 'paid', 'failed', 'expired', 'cancelled', 'refunded'
  final String? qrString;
  final String? qrCodeUrl;
  final List<Map<String, dynamic>> qrisActions;
  final String? acquirer;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final bool verifiedByWebhook;

  const QrisPaymentRecord({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.isSimulation,
    this.paymentMethod = 'qris',
    this.midtransOrderId,
    this.midtransTransactionId,
    required this.grossAmount,
    required this.status,
    this.qrString,
    this.qrCodeUrl,
    this.qrisActions = const [],
    this.acquirer,
    this.expiresAt,
    this.paidAt,
    this.verifiedByWebhook = false,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isExpiredOrFailed =>
      status == 'expired' || status == 'failed' || status == 'cancelled';

  /// Extracts the QR image URL from `qrCodeUrl` or Midtrans `actions`
  /// (`generate-qr-code-v2` or `generate-qr-code`) without assuming `qrString` is present.
  String? get resolvedQrImageUrl {
    if (qrCodeUrl != null && qrCodeUrl!.trim().isNotEmpty) {
      return qrCodeUrl!.trim();
    }
    for (final action in qrisActions) {
      final name = action['name']?.toString() ?? '';
      final url = action['url']?.toString() ?? '';
      if ((name == 'generate-qr-code-v2' || name == 'generate-qr-code') &&
          url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  bool get hasQrString => qrString != null && qrString!.trim().isNotEmpty;

  factory QrisPaymentRecord.fromPostgresMap(Map<String, dynamic> map) {
    final rawActions = map['qris_actions'] ?? map['actions'];
    final parsedActions = <Map<String, dynamic>>[];
    if (rawActions is List) {
      for (final item in rawActions) {
        if (item is Map) {
          parsedActions.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return QrisPaymentRecord(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] ?? map['orderId'] ?? '').toString(),
      provider: (map['provider'] ?? 'midtrans').toString(),
      isSimulation:
          (map['is_simulation'] ?? map['isSimulation'] ?? false) == true,
      paymentMethod:
          (map['payment_method'] ?? map['paymentMethod'] ?? 'qris').toString(),
      midtransOrderId:
          (map['midtrans_order_id'] ?? map['midtransOrderId'])?.toString(),
      midtransTransactionId:
          (map['midtrans_transaction_id'] ?? map['midtransTransactionId'])
              ?.toString(),
      grossAmount:
          ((map['gross_amount'] ?? map['grossAmount'] ?? 0) as num).toInt(),
      status: (map['status'] ?? 'pending').toString(),
      qrString: (map['qr_string'] ?? map['qrString'])?.toString(),
      qrCodeUrl: (map['qr_code_url'] ?? map['qrCodeUrl'])?.toString(),
      qrisActions: parsedActions,
      acquirer: map['acquirer']?.toString(),
      expiresAt: DateTime.tryParse(
        (map['expires_at'] ?? map['expiresAt'] ?? '').toString(),
      )?.toUtc(),
      paidAt: DateTime.tryParse(
        (map['paid_at'] ?? map['paidAt'] ?? '').toString(),
      )?.toUtc(),
      verifiedByWebhook:
          (map['verified_by_webhook'] ?? map['verifiedByWebhook'] ?? false) ==
          true,
    );
  }
}
