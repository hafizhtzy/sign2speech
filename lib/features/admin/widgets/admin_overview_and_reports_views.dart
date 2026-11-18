import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../domain/models/admin_dashboard_metrics.dart';

/// Admin Overview View (`Phase 3`):
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
          _buildPeriodFilterBar(),
          const SizedBox(height: 16),
          _buildRevenueKpiGrid(m),
          const SizedBox(height: 20),
          _buildStockHealthBanner(m.stockSummary),
          const SizedBox(height: 20),
          _buildDailySalesChartCard(m),
          const SizedBox(height: 20),
          _buildPaymentMethodAndTxChartsRow(context, m),
          const SizedBox(height: 20),
          _buildTopSellingProductsCard(m),
        ],
      );
    });
  }

  Widget _buildPeriodFilterBar() {
    final periods = <(AdminReportPeriod, String)>[
      (AdminReportPeriod.today, 'Hari Ini'),
      (AdminReportPeriod.yesterday, 'Kemarin'),
      (AdminReportPeriod.last7Days, '7 Hari'),
      (AdminReportPeriod.last30Days, '30 Hari'),
      (AdminReportPeriod.thisMonth, 'Bulan Ini'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (period, label) in periods)
          ChoiceChip(
            label: Text(label),
            selected: controller.selectedPeriod.value == period,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.bgSurface,
            labelStyle: AppTypography.labelMedium.copyWith(
              color: controller.selectedPeriod.value == period
                  ? AppColors.textOnDark
                  : AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => controller.setReportPeriod(period),
          ),
        StatusBadge(
          label: 'WIB (${controller.metrics.value.timezone})',
          variant: BadgeVariant.neutral,
        ),
      ],
    );
  }

  Widget _buildRevenueKpiGrid(AdminDashboardMetrics m) {
    final profitText = m.hasCompleteCostData && m.netProfit != null
        ? formatRupiah(m.netProfit!)
        : 'Harga Modal Belum Lengkap';

    final kpis = <(String, String, String, Color)>[
      ('Penjualan Kotor (Gross)', formatRupiah(m.grossSales), '${m.successCount} transaksi lunas', AppColors.primary),
      ('Penjualan Bersih (Net)', formatRupiah(m.netSales), 'Refund: ${formatRupiah(m.refundedAmount)}', AppColors.matcha),
      ('Rata-rata Order (AOV)', formatRupiah(m.averageOrderValue), '${m.unitsSold} unit terjual', AppColors.secondary),
      ('Status Transaksi', '${m.successCount} Sukses', 'Pending: ${m.pendingCount} • Gagal: ${m.failedCount}', AppColors.amber),
      ('Transaksi QRIS vs Tunai', 'QRIS: ${formatRupiah(m.qrisSales)}', 'Tunai: ${formatRupiah(m.cashSales)}', AppColors.primary),
      ('Estimasi Laba Bersih', profitText, m.hasCompleteCostData ? 'Terhitung dari HPP snapshot' : 'Isi HPP produk untuk hitung profit', AppColors.muted),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpis.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 122,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (ctx, idx) {
        final (title, val, sub, accent) = kpis[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                val,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockHealthBanner(AdminStockSummary s) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => controller.activeSection.value = AdminSection.inventory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Monitoring Stok & Inventaris Kafe',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    controller.activeSection.value = AdminSection.inventory,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Kelola Stok'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: 'Produk Aktif: ${s.activeProducts}',
                variant: BadgeVariant.active,
              ),
              StatusBadge(
                label: 'Total Stok Tersedia: ${s.totalAvailableStock}',
                variant: BadgeVariant.success,
              ),
              StatusBadge(
                label: 'Hampir Habis: ${s.lowStockCount}',
                variant: s.lowStockCount > 0
                    ? BadgeVariant.warning
                    : BadgeVariant.neutral,
              ),
              StatusBadge(
                label: 'Habis: ${s.outOfStockCount}',
                variant: s.outOfStockCount > 0
                    ? BadgeVariant.error
                    : BadgeVariant.neutral,
              ),
              if (s.uninitializedCount > 0)
                StatusBadge(
                  label: 'Wajib Stock Opname: ${s.uninitializedCount}',
                  variant: BadgeVariant.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesChartCard(AdminDashboardMetrics m) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Penjualan Harian (${m.startDate} – ${m.endDate})',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.ink,
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
                  gridData: const FlGridData(show: true),
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
                      color: AppColors.secondary,
                      barWidth: 3,
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
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Metode Pembayaran (QRIS vs Tunai)',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (total <= 0)
            Text(
              'Belum ada distribusi pembayaran pada periode ini.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
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
                      color: AppColors.primary,
                      radius: 50,
                      titleStyle: AppTypography.labelSmall.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    PieChartSectionData(
                      value: m.cashSales.toDouble(),
                      title: 'Tunai (${m.cashCount})',
                      color: AppColors.secondary,
                      radius: 50,
                      titleStyle: AppTypography.labelSmall.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w700,
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
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produk Terlaris (Hanya Pesanan Berhasil Dibayar)',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (m.topProducts.isEmpty)
            Text(
              'Belum ada produk terjual pada periode laporan ini.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
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
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${p.unitsSold} unit terjual • Kontribusi ${p.revenueSharePercent}%',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(p.totalRevenue),
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.secondary,
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
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavSalesReports.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('export_csv_report_btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: controller.exportCsvReport,
                    icon: const Icon(Icons.table_view_rounded, size: 18),
                    label: const Text('Export CSV'),
                  ),
                  ElevatedButton.icon(
                    key: const Key('export_pdf_report_btn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnDark,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: controller.exportPdfReport,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Export PDF'),
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
