import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../domain/models/admin_dashboard_metrics.dart';

/// Admin Overview View (`Phase 3`):
/// - Warm Coffeehouse Color-Block Bento UI (Swiss Neo-Retro Mobile UI)
/// - Revenue Summary KPIs (Asia/Jakarta timezone)
/// - Period Filter (Today, Yesterday, 7d, 30d, This Month)
/// - 5 `fl_chart` Analytics Visualizations (Daily Sales, Payment Method Pie, Transaction Count Bar, Top Products)
/// - Stock Monitoring Card with direct navigation to Inventory / Products
class AdminOverviewView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminOverviewView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final m = controller.metrics.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPeriodFilterBar(m),
          const SizedBox(height: 10),
          _buildHeroNetSalesCard(m),
          const SizedBox(height: 8),
          _buildRow2AovAndSignCard(m),
          const SizedBox(height: 8),
          _buildRow3TransactionStatusCard(m),
          const SizedBox(height: 8),
          _buildRow4PaymentAndProfitCards(m),
          const SizedBox(height: 8),
          _buildRow5StockAlertNotchedCard(m.stockSummary),
          const SizedBox(height: 14),
          _buildDailySalesChartCard(m),
          const SizedBox(height: 12),
          _buildPaymentMethodAndTxChartsRow(context, m),
          const SizedBox(height: 12),
          _buildTopSellingProductsCard(m),
        ],
      );
    });
  }

  Widget _buildPeriodFilterBar(AdminDashboardMetrics m) {
    final periods = <(AdminReportPeriod, String)>[
      (AdminReportPeriod.today, 'Hari Ini'),
      (AdminReportPeriod.yesterday, 'Kemarin'),
      (AdminReportPeriod.last7Days, '7 Hari'),
      (AdminReportPeriod.last30Days, '30 Hari'),
      (AdminReportPeriod.thisMonth, 'Bulan Ini'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final (period, label) in periods)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Obx(() {
                          final isSelected =
                              controller.selectedPeriod.value == period;
                          return InkWell(
                            onTap: () => controller.setReportPeriod(period),
                            borderRadius: BorderRadius.circular(22),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.bentoCardLight
                                    : AppColors.bentoCardDark,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                label,
                                style: AppTypography.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.bentoTextDark
                                      : AppColors.bentoCardLight
                                          .withOpacity(0.85),
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Standalone Timezone Metadata
            Text(
              'WIB (${m.timezone})',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 1. Hero Block: Net Sales + subtext + 2 overlapping shortcut circles
  Widget _buildHeroNetSalesCard(AdminDashboardMetrics m) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoCardDark,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Penjualan Bersih (Net)',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.bentoCardLight.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupiah(m.netSales),
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.bentoCardLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Penjualan Kotor (Gross)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.bentoCardLight.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${formatRupiah(m.grossSales)} • Refund: ${formatRupiah(m.refundedAmount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.bentoCardLight.withOpacity(0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 2 Overlapping circular buttons (52px diameter)
          SizedBox(
            width: 86,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Left circle: Sign Language Videos shortcut
                Positioned(
                  left: 0,
                  top: 0,
                  child: Tooltip(
                    message: 'Video Bahasa Isyarat',
                    child: InkWell(
                      onTap: () => controller.activeSection.value =
                          AdminSection.signVideos,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.bentoCardLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_library_rounded,
                          color: AppColors.bentoTextDark,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                // Right circle: Sales Reports shortcut (overlaps by 10px)
                Positioned(
                  left: 38,
                  top: 0,
                  child: Tooltip(
                    message: 'Laporan Penjualan',
                    child: InkWell(
                      onTap: () => controller.activeSection.value =
                          AdminSection.salesReports,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.bentoTerracotta,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bentoCardDark,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: AppColors.bentoTextLight,
                          size: 22,
                        ),
                      ),
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

  /// 2. Row 2: 2-Column Action & Giant KPI cards (Equal Height, Radius 28px)
  Widget _buildRow2AovAndSignCard(AdminDashboardMetrics m) {
    return SizedBox(
      height: 155,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: AOV (Warm Oat Cream #F6F0E4)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bentoCardLight,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Rata-rata Order (AOV)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.bentoTextDark.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.north_east_rounded,
                        color: AppColors.bentoTextDark,
                        size: 18,
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatRupiah(m.averageOrderValue),
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.bentoTextDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Text(
                    '${m.unitsSold} unit terjual',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.bentoTextDark.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right Card: Sign-to-Speech (Warm Matcha Sage #B8DC7E)
          Expanded(
            child: InkWell(
              onTap: () =>
                  controller.activeSection.value = AdminSection.signVideos,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bentoMatcha,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          child: Text(
                            'Sign-to-Speech',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.bentoTextDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.waving_hand_rounded,
                          color: AppColors.bentoTextDark,
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      'Kamus &\nVideo Isyarat',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.bentoTextDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.15,
                      ),
                    ),
                    Row(
                      children: const [
                        Text(
                          'Buka Modul',
                          style: TextStyle(
                            color: AppColors.bentoTextDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.bentoTextDark,
                        ),
                      ],
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

  /// 3. Row 3: Full-Width Transaction Status card (Warm Honey Mustard #F6C844)
  Widget _buildRow3TransactionStatusCard(AdminDashboardMetrics m) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoHoney,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.selectedPeriod.value.name.toUpperCase()} • STATUS TRANSAKSI',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.bentoTextDark.withOpacity(0.7),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi Sukses',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.bentoTextDark.withOpacity(0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${m.successCount}',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.bentoTextDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              // Compact Dark Badge Pill for Pending & Gagal
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bentoBase,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pending: ${m.pendingCount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.bentoHoney,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gagal: ${m.failedCount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.bentoTerracotta,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Row 4: 2-Column Analytics cards (Payment split & Net profit, Radius 28px)
  Widget _buildRow4PaymentAndProfitCards(AdminDashboardMetrics m) {
    final total = m.qrisSales + m.cashSales;
    final qrisRatio =
        total > 0 ? (m.qrisSales / total).clamp(0.05, 0.95) : 0.5;

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: QRIS vs Tunai (#2A201B)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bentoCardDark,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Metode Bayar',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (qrisRatio * 100).round(),
                            child: Container(color: AppColors.bentoMatcha),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: ((1 - qrisRatio) * 100).round(),
                            child: Container(color: AppColors.bentoHoney),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.bentoMatcha,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'QRIS: ${formatRupiah(m.qrisSales)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.bentoMatcha,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.bentoHoney,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tunai: ${formatRupiah(m.cashSales)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.bentoHoney,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right Card: Estimasi Laba Bersih (#2A201B)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bentoCardDark,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimasi Laba Bersih',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.bentoCardLight.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  if (m.hasCompleteCostData && m.netProfit != null) ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRupiah(m.netProfit!),
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.bentoMatcha,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Text(
                      'HPP Terhitung Lengkap',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.bentoCardLight.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HPP Belum Diisi',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.bentoHoney,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Harga Modal Belum Lengkap',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.bentoCardLight.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => controller.activeSection.value =
                          AdminSection.products,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bentoHoney,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Atur HPP →',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.bentoTextDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Row 5: Stock Alert Notched Card (Roasted Terracotta #E95B2B)
  Widget _buildRow5StockAlertNotchedCard(AdminStockSummary s) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoTerracotta,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notched / Badge Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bentoBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Monitoring Stok Kafe',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.bentoTextLight,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Bold Stock Opname Highlight
          if (s.uninitializedCount > 0)
            Text(
              'Wajib Stock Opname: ${s.uninitializedCount}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.bentoTextLight,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            )
          else
            Text(
              'Stok Berjalan Normal',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.bentoTextLight,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          const SizedBox(height: 10),
          // Clean Summary Pills & Dark Circle Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStockPill('Aktif: ${s.activeProducts}'),
                    _buildStockPill('Stok: ${s.totalAvailableStock}'),
                    _buildStockPill('Hampir Habis: ${s.lowStockCount}'),
                    _buildStockPill('Habis: ${s.outOfStockCount}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Kelola Stok',
                child: InkWell(
                  onTap: () => controller.activeSection.value =
                      AdminSection.inventory,
                  borderRadius: BorderRadius.circular(23),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.bentoBase,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.bentoTextLight,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bentoBase.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.bentoTextLight,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _buildDailySalesChartCard(AdminDashboardMetrics m) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoCardDark,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Penjualan Harian (${m.startDate} – ${m.endDate})',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (m.dailySeries.isEmpty || m.grossSales == 0)
            const EmptyStateView(
              icon: Icons.show_chart_rounded,
              title: 'Belum Ada Transaksi Penjualan',
              subtitle:
                  'Grafik penjualan harian akan tampil otomatis setelah ada transaksi lunas pada periode ini.',
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: AppColors.bentoCardLight.withOpacity(0.08),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (val) => FlLine(
                      color: AppColors.bentoCardLight.withOpacity(0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: AppColors.bentoHoney,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      spots: [
                        for (int i = 0; i < m.dailySeries.length; i++)
                          FlSpot(
                            i.toDouble(),
                            m.dailySeries[i].grossSales.toDouble(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodAndTxChartsRow(
    BuildContext context,
    AdminDashboardMetrics m,
  ) {
    final total = m.qrisSales + m.cashSales;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoCardDark,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Metode Pembayaran (QRIS vs Tunai)',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (total <= 0)
            Text(
              'Belum ada distribusi pembayaran pada periode ini.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.6),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 36,
                  sections: [
                    PieChartSectionData(
                      value: m.qrisSales.toDouble(),
                      title: 'QRIS (${m.qrisCount})',
                      color: AppColors.bentoMatcha,
                      radius: 50,
                      titleStyle: AppTypography.labelSmall.copyWith(
                        color: AppColors.bentoTextDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    PieChartSectionData(
                      value: m.cashSales.toDouble(),
                      title: 'Tunai (${m.cashCount})',
                      color: AppColors.bentoHoney,
                      radius: 50,
                      titleStyle: AppTypography.labelSmall.copyWith(
                        color: AppColors.bentoTextDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopSellingProductsCard(AdminDashboardMetrics m) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoCardDark,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produk Terlaris (Pesanan Lunas)',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (m.topProducts.isEmpty)
            Text(
              'Belum ada produk terjual pada periode laporan ini.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.6),
              ),
            )
          else
            ...m.topProducts.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.bentoTextLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${p.unitsSold} unit terjual • Kontribusi ${p.revenueSharePercent}%',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.bentoCardLight.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(p.totalRevenue),
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.bentoHoney,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Admin Sales & Financial Integrity Report View (`Phase 10`).
class AdminSalesReportView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminSalesReportView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppStrings.adminNavSalesReports.tr,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.bentoTextLight,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('export_csv_report_btn'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.bentoCardDark,
                    foregroundColor: AppColors.bentoTextLight,
                    side: BorderSide(
                      color: AppColors.bentoCardLight.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: controller.exportCsvReport,
                  icon: const Icon(
                    Icons.table_view_rounded,
                    size: 18,
                    color: AppColors.bentoHoney,
                  ),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('export_pdf_report_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bentoTerracotta,
                    foregroundColor: AppColors.bentoTextLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(48, 48),
                    elevation: 0,
                  ),
                  onPressed: controller.exportPdfReport,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(
                    'Export PDF',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminOverviewView(controller: controller),
      ],
    );
  }
}
