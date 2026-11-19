import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/controllers/auth_controller.dart';
import '../../../core/auth/models/app_user_role.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../domain/models/sign_video_metadata.dart';
import '../domain/models/staff_member.dart';

/// Admin Sign Language Content Management View (`Phase 5`).
/// Explicitly displays the mandatory separation banner between Reference Video Library
/// and MotionGRU AI Model Training (`Phase 5.6`).
class AdminSignVideosView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminSignVideosView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavSignVideos.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mandatory Phase 5.6 Warning Banner: Reference Video vs AI Training Pipeline
          Container(
            key: const Key('admin_video_ai_disclaimer_banner'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bentoCardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.bentoHoney.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.bentoHoney,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.adminVideoAiSeparationBanner.tr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.bentoTextLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final lang in ['all', 'BISINDO', 'SIBI'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => controller.videoLangFilter.value = lang,
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: controller.videoLangFilter.value == lang
                              ? AppColors.bentoCardLight
                              : AppColors.bentoCardDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lang == 'all' ? 'Semua Bahasa' : lang,
                          style: AppTypography.labelMedium.copyWith(
                            color: controller.videoLangFilter.value == lang
                                ? AppColors.bentoTextDark
                                : AppColors.bentoCardLight.withOpacity(0.85),
                            fontWeight:
                                controller.videoLangFilter.value == lang
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (controller.filteredVideos.isEmpty)
            Text(
              'Belum ada video metadata di tabel sign_language_videos.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.6),
              ),
            )
          else
            ...controller.filteredVideos.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bentoCardDark,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${v.title} (${v.gloss}) • ${v.languageType}',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.bentoTextLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kategori: ${v.category} • Path: ${v.storagePath}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.bentoCardLight.withOpacity(0.65),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (v.isPublished
                                  ? AppColors.bentoMatcha
                                  : (v.isDraft
                                      ? AppColors.bentoHoney
                                      : AppColors.bentoCardLight))
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          v.publicationStatus.dbValue.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: v.isPublished
                                ? AppColors.bentoMatcha
                                : (v.isDraft
                                    ? AppColors.bentoHoney
                                    : AppColors.bentoCardLight),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!v.isPublished)
                        ElevatedButton(
                          key: Key('publish_video_btn_${v.id}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bentoMatcha,
                            foregroundColor: AppColors.bentoTextDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(60, 34),
                            elevation: 0,
                          ),
                          onPressed: () => controller.updateSignVideoStatus(
                            v,
                            SignPublicationStatus.published,
                          ),
                          child: const Text(
                            'Publish',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (!v.isArchived) ...[
                        const SizedBox(width: 6),
                        OutlinedButton(
                          key: Key('archive_video_btn_${v.id}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.bentoCardLight,
                            side: BorderSide(
                              color: AppColors.bentoCardLight.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(60, 34),
                          ),
                          onPressed: () => controller.updateSignVideoStatus(
                            v,
                            SignPublicationStatus.archived,
                          ),
                          child: const Text(
                            'Archive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Admin Staff / Cashier Management View (`Phase 6`).
class AdminStaffView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminStaffView({super.key, required this.controller});

  void _openInviteCashierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Undang Akun Kasir Baru',
          style: TextStyle(
            color: AppColors.bentoTextLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('invite_cashier_name_field'),
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Nama Kasir *',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('invite_cashier_email_field'),
              controller: emailCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Email Kasir *',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Nomor Telepon (Opsional)',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel.tr,
              style: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('submit_invite_cashier_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bentoHoney,
              foregroundColor: AppColors.bentoTextDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final ok = await controller.inviteCashier(
                email: emailCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (ok && ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Kirim Undangan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmToggleCashierStatus(BuildContext context, StaffMember cashier) {
    final targetStatus = cashier.isActive
        ? AccountStatus.disabled
        : AccountStatus.active;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          cashier.isActive
              ? 'Nonaktifkan Akun Kasir?'
              : 'Aktifkan Kembali Akun Kasir?',
          style: const TextStyle(
            color: AppColors.bentoTextLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          cashier.isActive
              ? 'Sesi aktif "${cashier.fullName}" akan langsung dicabut dari database dan server.'
              : 'Akun "${cashier.fullName}" akan diizinkan kembali mengakses dashboard kasir.',
          style: TextStyle(
            color: AppColors.bentoCardLight.withOpacity(0.85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel.tr,
              style: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cashier.isActive
                  ? AppColors.bentoTerracotta
                  : AppColors.bentoMatcha,
              foregroundColor: cashier.isActive
                  ? AppColors.bentoTextLight
                  : AppColors.bentoTextDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.setCashierStatus(
                cashierId: cashier.id,
                status: targetStatus,
                reason: 'Diubah melalui Admin Dashboard',
              );
            },
            child: const Text(
              'Konfirmasi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavStaff.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.bentoTextLight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('admin_invite_cashier_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bentoHoney,
                  foregroundColor: AppColors.bentoTextDark,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _openInviteCashierDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: const Text(
                  'Undang Kasir',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.filteredCashiers.isEmpty)
            Text(
              'Belum ada akun kasir terdaftar.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.bentoCardLight.withOpacity(0.6),
              ),
            )
          else
            ...controller.filteredCashiers.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bentoCardDark,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c.fullName} (${c.email})',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.bentoTextLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pesanan: ${c.ordersProcessed} • Penjualan: ${formatRupiah(c.totalHandledSales)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.bentoCardLight.withOpacity(0.65),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (c.isActive
                                  ? AppColors.bentoMatcha
                                  : AppColors.bentoTerracotta)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.isActive ? 'AKTIF' : 'NONAKTIF',
                          style: AppTypography.labelSmall.copyWith(
                            color: c.isActive
                                ? AppColors.bentoMatcha
                                : AppColors.bentoTerracotta,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        key: Key('toggle_cashier_status_${c.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.isActive
                              ? AppColors.bentoTerracotta
                              : AppColors.bentoMatcha,
                          side: BorderSide(
                            color: (c.isActive
                                    ? AppColors.bentoTerracotta
                                    : AppColors.bentoMatcha)
                                .withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(60, 34),
                        ),
                        onPressed: () =>
                            _confirmToggleCashierStatus(context, c),
                        child: Text(
                          c.isActive ? 'Nonaktifkan' : 'Aktifkan',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

/// Admin Orders, Transactions & Refund Monitoring View.
class AdminOrdersTransactionsView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminOrdersTransactionsView({super.key, required this.controller});

  void _openRefundDialog(BuildContext context, String orderId, int maxAmount) {
    final amountCtrl = TextEditingController(text: '$maxAmount');
    final reasonCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bentoCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Proses Refund Pesanan $orderId',
          style: const TextStyle(
            color: AppColors.bentoTextLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Nominal Refund (Rp) *',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: AppColors.bentoTextLight),
              decoration: InputDecoration(
                labelText: 'Alasan Refund (Wajib) *',
                labelStyle: TextStyle(
                  color: AppColors.bentoCardLight.withOpacity(0.7),
                ),
                filled: true,
                fillColor: AppColors.bentoBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cancel.tr,
              style: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bentoTerracotta,
              foregroundColor: AppColors.bentoTextLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
              final reason = reasonCtrl.text.trim();
              if (amt <= 0 || reason.length < 3) return;
              final ok = await controller.processOrderRefund(
                orderId: orderId,
                amount: amt,
                reason: reason,
              );
              if (ok && ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Konfirmasi Refund',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.adminNavTransactions.tr,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...controller.orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bentoCardDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${o.queueNumber} • ${o.orderId} (${o.customerName})',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.bentoTextLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (o.paymentMethod.name.toLowerCase() == 'qris'
                                          ? AppColors.bentoMatcha
                                          : AppColors.bentoHoney)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  o.paymentMethod.name.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: o.paymentMethod.name.toLowerCase() == 'qris'
                                        ? AppColors.bentoMatcha
                                        : AppColors.bentoHoney,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (o.paymentStatus == 'paid'
                                          ? AppColors.bentoMatcha
                                          : AppColors.bentoTerracotta)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  o.paymentStatus.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: o.paymentStatus == 'paid'
                                        ? AppColors.bentoMatcha
                                        : AppColors.bentoTerracotta,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Text(
                                'Total: ${formatRupiah(o.grandTotal)}',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.bentoHoney,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (o.paymentStatus == 'paid')
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.bentoTerracotta,
                          side: BorderSide(
                            color: AppColors.bentoTerracotta.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(60, 34),
                        ),
                        onPressed: () =>
                            _openRefundDialog(context, o.orderId, o.grandTotal),
                        child: const Text(
                          'Refund',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

/// Admin Activity & Audit Logs View (`Phase 7` — Read-Only, Immutable).
class AdminAuditLogsView extends StatelessWidget {
  final AdminDashboardController controller;

  const AdminAuditLogsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.adminNavAuditLogs.tr,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Audit log bersifat append-only (immutable) dan tidak dapat diubah atau dihapus.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.bentoCardLight.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          ...controller.auditLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bentoCardDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${log.actorName} (${log.actorRole.toUpperCase()}) • ${log.action}',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.bentoTextLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (log.status == 'success'
                                    ? AppColors.bentoMatcha
                                    : AppColors.bentoTerracotta)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.status.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: log.status == 'success'
                                  ? AppColors.bentoMatcha
                                  : AppColors.bentoTerracotta,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Objek: ${log.entityType} (${log.entityId})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.bentoCardLight.withOpacity(0.65),
                        fontSize: 11,
                      ),
                    ),
                    if (log.beforeData != null || log.afterData != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Sebelum: ${log.beforeData ?? "-"} → Sesudah: ${log.afterData ?? "-"}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.bentoHoney,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

/// Admin Profile View (Role is read-only; no self-escalation allowed).
class AdminProfileView extends StatelessWidget {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    final profile = auth.currentProfile.value;
    final nameCtrl = TextEditingController(text: profile?.fullName ?? 'Admin');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bentoCardDark,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.adminNavProfile.tr,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.bentoTextLight,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bentoBase,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Email: ${profile?.email ?? "-"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.bentoCardLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bentoMatcha.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ADMIN (Read-Only)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.bentoMatcha,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.bentoTextLight),
            decoration: InputDecoration(
              labelText: AppStrings.authFullNameLabel.tr,
              labelStyle: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
              filled: true,
              fillColor: AppColors.bentoBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            style: const TextStyle(color: AppColors.bentoTextLight),
            decoration: InputDecoration(
              labelText: AppStrings.authPhoneLabel.tr,
              labelStyle: TextStyle(
                color: AppColors.bentoCardLight.withOpacity(0.7),
              ),
              filled: true,
              fillColor: AppColors.bentoBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bentoHoney,
              foregroundColor: AppColors.bentoTextDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
            ),
            onPressed: () async {
              final ok = await auth.updateOwnProfile(
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (ok) {
                AppSnackbar.show(
                  title: AppStrings.adminNavProfile.tr,
                  message: 'Profil berhasil diperbarui.',
                  variant: SnackbarVariant.success,
                );
              }
            },
            child: Text(
              AppStrings.save.tr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
