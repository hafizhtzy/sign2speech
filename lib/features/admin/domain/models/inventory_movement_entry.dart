import 'package:flutter/foundation.dart';

@immutable
class InventoryMovementEntry {
  final String id;
  final String productId;
  final String movementType;
  final int quantityDelta;
  final int stockBefore;
  final int stockAfter;
  final int reservedBefore;
  final int reservedAfter;
  final String referenceType;
  final String referenceId;
  final String reason;
  final String? createdBy;
  final DateTime createdAt;

  const InventoryMovementEntry({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantityDelta,
    required this.stockBefore,
    required this.stockAfter,
    this.reservedBefore = 0,
    this.reservedAfter = 0,
    required this.referenceType,
    required this.referenceId,
    required this.reason,
    this.createdBy,
    required this.createdAt,
  });

  factory InventoryMovementEntry.fromPostgresMap(Map<String, dynamic> map) {
    return InventoryMovementEntry(
      id: (map['id'] ?? '').toString(),
      productId: (map['product_id'] ?? map['productId'] ?? '').toString(),
      movementType:
          (map['movement_type'] ?? map['movementType'] ?? '').toString(),
      quantityDelta:
          ((map['quantity_delta'] ?? map['quantityDelta'] ?? 0) as num).toInt(),
      stockBefore:
          ((map['stock_before'] ?? map['stockBefore'] ?? 0) as num).toInt(),
      stockAfter:
          ((map['stock_after'] ?? map['stockAfter'] ?? 0) as num).toInt(),
      reservedBefore:
          ((map['reserved_before'] ?? map['reservedBefore'] ?? 0) as num)
              .toInt(),
      reservedAfter:
          ((map['reserved_after'] ?? map['reservedAfter'] ?? 0) as num).toInt(),
      referenceType:
          (map['reference_type'] ?? map['referenceType'] ?? '').toString(),
      referenceId:
          (map['reference_id'] ?? map['referenceId'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      createdBy: (map['created_by'] ?? map['createdBy'])?.toString(),
      createdAt:
          DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'] ?? '').toString(),
          )?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

@immutable
class LowStockReportEntry {
  final String id;
  final String productId;
  final String reportedBy;
  final int reportedAvailableStock;
  final String note;
  final String status; // 'open', 'acknowledged', 'resolved'
  final DateTime createdAt;

  const LowStockReportEntry({
    required this.id,
    required this.productId,
    required this.reportedBy,
    required this.reportedAvailableStock,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory LowStockReportEntry.fromPostgresMap(Map<String, dynamic> map) {
    return LowStockReportEntry(
      id: (map['id'] ?? '').toString(),
      productId: (map['product_id'] ?? map['productId'] ?? '').toString(),
      reportedBy: (map['reported_by'] ?? map['reportedBy'] ?? '').toString(),
      reportedAvailableStock:
          ((map['reported_available_stock'] ??
                      map['reportedAvailableStock'] ??
                      0)
                  as num)
              .toInt(),
      note: (map['note'] ?? '').toString(),
      status: (map['status'] ?? 'open').toString(),
      createdAt:
          DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'] ?? '').toString(),
          )?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}
