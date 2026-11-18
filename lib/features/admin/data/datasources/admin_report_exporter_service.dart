import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/admin_dashboard_metrics.dart';

/// Admin-only Financial Report Exporter supporting both RFC-4180 CSV and PDF
/// generation (`pdf`, `printing`, `share_plus` from approved Opsi A).
class AdminReportExporterService {
  const AdminReportExporterService();

  /// Builds an RFC-4180 compliant CSV string from [AdminDashboardMetrics].
  String buildCsvReport(AdminDashboardMetrics metrics) {
    final buf = StringBuffer();
    buf.writeln('Laporan Keuangan Sign2Speech (${metrics.timezone})');
    buf.writeln('Periode,${metrics.startDate} s/d ${metrics.endDate}');
    buf.writeln('Metrik,Nilai');
    buf.writeln('Penjualan Kotor (Gross Sales),${metrics.grossSales}');
    buf.writeln('Total Refund Selesai,${metrics.refundedAmount}');
    buf.writeln('Penjualan Bersih (Net Sales),${metrics.netSales}');
    buf.writeln('Transaksi Berhasil,${metrics.successCount}');
    buf.writeln('Transaksi Pending,${metrics.pendingCount}');
    buf.writeln('Transaksi Gagal/Expired,${metrics.failedCount}');
    buf.writeln('Rata-rata Nilai Order (AOV),${metrics.averageOrderValue}');
    buf.writeln('Unit Produk Terjual,${metrics.unitsSold}');
    buf.writeln('Transaksi QRIS (${metrics.qrisCount}),${metrics.qrisSales}');
    buf.writeln('Transaksi Tunai (${metrics.cashCount}),${metrics.cashSales}');
    buf.writeln(
      'Laba Bersih (Net Profit),${metrics.hasCompleteCostData && metrics.netProfit != null ? metrics.netProfit : "Data Harga Modal Belum Lengkap"}',
    );
    buf.writeln();
    buf.writeln('Produk Terlaris,Unit Terjual,Total Penjualan,Kontribusi (%)');
    for (final p in metrics.topProducts) {
      final escapedName = '"${p.productName.replaceAll('"', '""')}"';
      buf.writeln(
        '$escapedName,${p.unitsSold},${p.totalRevenue},${p.revenueSharePercent}',
      );
    }
    return buf.toString();
  }

  /// Builds a printable PDF document from [AdminDashboardMetrics].
  Future<Uint8List> buildPdfReportBytes(AdminDashboardMetrics metrics) async {
    final doc = pw.Document();
    final profitLabel =
        metrics.hasCompleteCostData && metrics.netProfit != null
        ? formatRupiah(metrics.netProfit!)
        : 'Belum Tersedia (Harga Modal Produk Belum Lengkap)';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Laporan Penjualan & Keuangan Sign2Speech',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Periode: ${metrics.startDate} s/d ${metrics.endDate} - Zona Waktu: ${metrics.timezone}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Indikator Keuangan', 'Nilai'],
            data: [
              ['Penjualan Kotor (Gross Sales)', formatRupiah(metrics.grossSales)],
              ['Total Refund Selesai', formatRupiah(metrics.refundedAmount)],
              ['Penjualan Bersih (Net Sales)', formatRupiah(metrics.netSales)],
              ['Rata-rata Nilai Transaksi (AOV)', formatRupiah(metrics.averageOrderValue)],
              ['Jumlah Transaksi Berhasil', '${metrics.successCount}'],
              ['Jumlah Transaksi Pending', '${metrics.pendingCount}'],
              ['Jumlah Transaksi Gagal / Expired', '${metrics.failedCount}'],
              ['Total Unit Produk Terjual', '${metrics.unitsSold}'],
              ['Pembayaran QRIS (${metrics.qrisCount} trx)', formatRupiah(metrics.qrisSales)],
              ['Pembayaran Tunai (${metrics.cashCount} trx)', formatRupiah(metrics.cashSales)],
              ['Laba Bersih (Net Profit)', profitLabel],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Produk Terlaris (Hanya Transaksi Lunas)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (metrics.topProducts.isEmpty)
            pw.Text('Belum ada penjualan produk pada periode ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Produk',
                'Unit Terjual',
                'Total Penjualan',
                'Kontribusi',
              ],
              data: metrics.topProducts
                  .map(
                    (p) => [
                      p.productName,
                      '${p.unitsSold}',
                      formatRupiah(p.totalRevenue),
                      '${p.revenueSharePercent}%',
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> shareCsvReport(AdminDashboardMetrics metrics) async {
    final csv = buildCsvReport(metrics);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final file = XFile.fromData(
      bytes,
      mimeType: 'text/csv',
      name: 'sign2speech_report_${metrics.startDate}_${metrics.endDate}.csv',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        subject: 'Laporan Penjualan Sign2Speech (${metrics.startDate})',
      ),
    );
  }

  Future<void> printOrSharePdfReport(AdminDashboardMetrics metrics) async {
    final bytes = await buildPdfReportBytes(metrics);
    await Printing.layoutPdf(
      name: 'sign2speech_report_${metrics.startDate}_${metrics.endDate}.pdf',
      onLayout: (_) async => bytes,
    );
  }
}
