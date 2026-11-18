import 'package:flutter/foundation.dart';

@immutable
class DailySalesPoint {
  final String reportDate;
  final int grossSales;
  final int transactionCount;

  const DailySalesPoint({
    required this.reportDate,
    required this.grossSales,
    required this.transactionCount,
  });

  factory DailySalesPoint.fromMap(Map<String, dynamic> map) {
    return DailySalesPoint(
      reportDate: (map['report_date'] ?? map['reportDate'] ?? '').toString(),
      grossSales: ((map['gross_sales'] ?? map['grossSales'] ?? 0) as num).toInt(),
      transactionCount:
          ((map['transaction_count'] ?? map['transactionCount'] ?? 0) as num)
              .toInt(),
    );
  }
}

@immutable
class TopSellingProduct {
  final String productId;
  final String productName;
  final int unitsSold;
  final int totalRevenue;
  final double revenueSharePercent;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.totalRevenue,
    required this.revenueSharePercent,
  });

  factory TopSellingProduct.fromMap(Map<String, dynamic> map) {
    return TopSellingProduct(
      productId: (map['product_id'] ?? map['productId'] ?? '').toString(),
      productName: (map['product_name'] ?? map['productName'] ?? '').toString(),
      unitsSold: ((map['units_sold'] ?? map['unitsSold'] ?? 0) as num).toInt(),
      totalRevenue:
          ((map['total_revenue'] ?? map['totalRevenue'] ?? 0) as num).toInt(),
      revenueSharePercent:
          ((map['revenue_share_percent'] ?? map['revenueSharePercent'] ?? 0)
                  as num)
              .toDouble(),
    );
  }
}

@immutable
class AdminStockSummary {
  final int activeProducts;
  final int uninitializedCount;
  final int totalAvailableStock;
  final int outOfStockCount;
  final int lowStockCount;

  const AdminStockSummary({
    this.activeProducts = 0,
    this.uninitializedCount = 0,
    this.totalAvailableStock = 0,
    this.outOfStockCount = 0,
    this.lowStockCount = 0,
  });

  factory AdminStockSummary.fromMap(Map<String, dynamic> map) {
    return AdminStockSummary(
      activeProducts:
          ((map['active_products'] ?? map['activeProducts'] ?? 0) as num)
              .toInt(),
      uninitializedCount:
          ((map['uninitialized_count'] ?? map['uninitializedCount'] ?? 0)
                  as num)
              .toInt(),
      totalAvailableStock:
          ((map['total_available_stock'] ?? map['totalAvailableStock'] ?? 0)
                  as num)
              .toInt(),
      outOfStockCount:
          ((map['out_of_stock_count'] ?? map['outOfStockCount'] ?? 0) as num)
              .toInt(),
      lowStockCount:
          ((map['low_stock_count'] ?? map['lowStockCount'] ?? 0) as num).toInt(),
    );
  }
}

/// Authoritative financial and operational metrics from `rpc_admin_dashboard_metrics`.
/// Enforces Phase 3.6 & Phase 10:
/// - `netSales = grossSales - refundedAmount`
/// - `netProfit` is strictly `null` unless `hasCompleteCostData == true` (never fabricated).
@immutable
class AdminDashboardMetrics {
  final String timezone;
  final String startDate;
  final String endDate;
  final int grossSales;
  final int refundedAmount;
  final int netSales;
  final int successCount;
  final int pendingCount;
  final int failedCount;
  final int averageOrderValue;
  final int unitsSold;
  final int qrisCount;
  final int qrisSales;
  final int cashCount;
  final int cashSales;
  final bool hasCompleteCostData;
  final int? netProfit;
  final List<DailySalesPoint> dailySeries;
  final List<TopSellingProduct> topProducts;
  final AdminStockSummary stockSummary;

  const AdminDashboardMetrics({
    this.timezone = 'Asia/Jakarta',
    required this.startDate,
    required this.endDate,
    this.grossSales = 0,
    this.refundedAmount = 0,
    this.netSales = 0,
    this.successCount = 0,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.averageOrderValue = 0,
    this.unitsSold = 0,
    this.qrisCount = 0,
    this.qrisSales = 0,
    this.cashCount = 0,
    this.cashSales = 0,
    this.hasCompleteCostData = false,
    this.netProfit,
    this.dailySeries = const [],
    this.topProducts = const [],
    this.stockSummary = const AdminStockSummary(),
  });

  factory AdminDashboardMetrics.fromMap(Map<String, dynamic> map) {
    final hasCost =
        (map['has_complete_cost_data'] ?? map['hasCompleteCostData'] ?? false) ==
        true;
    final rawProfit = map['net_profit'] ?? map['netProfit'];
    final rawDaily = map['daily_series'] ?? map['dailySeries'];
    final rawTop = map['top_products'] ?? map['topProducts'];
    final rawStock = map['stock_summary'] ?? map['stockSummary'];

    return AdminDashboardMetrics(
      timezone: (map['timezone'] ?? 'Asia/Jakarta').toString(),
      startDate: (map['start_date'] ?? map['startDate'] ?? '').toString(),
      endDate: (map['end_date'] ?? map['endDate'] ?? '').toString(),
      grossSales: ((map['gross_sales'] ?? map['grossSales'] ?? 0) as num).toInt(),
      refundedAmount:
          ((map['refunded_amount'] ?? map['refundedAmount'] ?? 0) as num)
              .toInt(),
      netSales: ((map['net_sales'] ?? map['netSales'] ?? 0) as num).toInt(),
      successCount:
          ((map['success_count'] ?? map['successCount'] ?? 0) as num).toInt(),
      pendingCount:
          ((map['pending_count'] ?? map['pendingCount'] ?? 0) as num).toInt(),
      failedCount:
          ((map['failed_count'] ?? map['failedCount'] ?? 0) as num).toInt(),
      averageOrderValue:
          ((map['average_order_value'] ?? map['averageOrderValue'] ?? 0) as num)
              .toInt(),
      unitsSold: ((map['units_sold'] ?? map['unitsSold'] ?? 0) as num).toInt(),
      qrisCount: ((map['qris_count'] ?? map['qrisCount'] ?? 0) as num).toInt(),
      qrisSales: ((map['qris_sales'] ?? map['qrisSales'] ?? 0) as num).toInt(),
      cashCount: ((map['cash_count'] ?? map['cashCount'] ?? 0) as num).toInt(),
      cashSales: ((map['cash_sales'] ?? map['cashSales'] ?? 0) as num).toInt(),
      hasCompleteCostData: hasCost,
      netProfit: hasCost && rawProfit is num ? rawProfit.toInt() : null,
      dailySeries: rawDaily is List
          ? rawDaily
              .whereType<Map>()
              .map((e) => DailySalesPoint.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      topProducts: rawTop is List
          ? rawTop
              .whereType<Map>()
              .map(
                (e) => TopSellingProduct.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
      stockSummary: rawStock is Map
          ? AdminStockSummary.fromMap(Map<String, dynamic>.from(rawStock))
          : const AdminStockSummary(),
    );
  }
}
