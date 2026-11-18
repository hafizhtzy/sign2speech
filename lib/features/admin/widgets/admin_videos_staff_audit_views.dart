import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/auth/controllers/auth_controller.dart';
import '../../../core/auth/models/app_user_role.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/status_badge.dart';
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
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavSignVideos.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
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
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.adminVideoAiSeparationBanner.tr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final lang in ['all', 'BISINDO', 'SIBI'])
                ChoiceChip(
                  label: Text(lang == 'all' ? 'Semua Bahasa' : lang),
                  selected: controller.videoLangFilter.value == lang,
                  onSelected: (_) => controller.videoLangFilter.value = lang,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.filteredVideos.isEmpty)
            Text(
              'Belum ada video metadata di tabel sign_language_videos.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            )
          else
            ...controller.filteredVideos.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
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
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kategori: ${v.category} • Path: ${v.storagePath}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: v.publicationStatus.dbValue.toUpperCase(),
                        variant: v.isPublished
                            ? BadgeVariant.success
                            : (v.isDraft
                                  ? BadgeVariant.warning
                                  : BadgeVariant.neutral),
                      ),
                      const SizedBox(width: 8),
                      if (!v.isPublished)
                        TextButton(
                          key: Key('publish_video_btn_${v.id}'),
                          onPressed: () => controller.updateSignVideoStatus(
                            v,
                            SignPublicationStatus.published,
                          ),
                          child: const Text('Publish'),
                        ),
                      if (!v.isArchived)
                        TextButton(
                          key: Key('archive_video_btn_${v.id}'),
                          onPressed: () => controller.updateSignVideoStatus(
                            v,
                            SignPublicationStatus.archived,
                          ),
                          child: const Text('Archive'),
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
        title: const Text('Undang Akun Kasir Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('invite_cashier_name_field'),
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kasir *'),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('invite_cashier_email_field'),
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Kasir *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon (Opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
            key: const Key('submit_invite_cashier_btn'),
            onPressed: () async {
              final ok = await controller.inviteCashier(
                email: emailCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (ok && ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Kirim Undangan'),
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
        title: Text(
          cashier.isActive
              ? 'Nonaktifkan Akun Kasir?'
              : 'Aktifkan Kembali Akun Kasir?',
        ),
        content: Text(
          cashier.isActive
              ? 'Sesi aktif "${cashier.fullName}" akan langsung dicabut dari database dan server.'
              : 'Akun "${cashier.fullName}" akan diizinkan kembali mengakses dashboard kasir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.setCashierStatus(
                cashierId: cashier.id,
                status: targetStatus,
                reason: 'Diubah melalui Admin Dashboard',
              );
            },
            child: const Text('Konfirmasi'),
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
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.adminNavStaff.tr,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('admin_invite_cashier_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnDark,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _openInviteCashierDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Undang Kasir'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.filteredCashiers.isEmpty)
            Text(
              'Belum ada akun kasir terdaftar.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            )
          else
            ...controller.filteredCashiers.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
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
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pesanan Diproses: ${c.ordersProcessed} • Penjualan: ${formatRupiah(c.totalHandledSales)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: c.isActive ? 'AKTIF' : 'NONAKTIF',
                        variant: c.isActive
                            ? BadgeVariant.success
                            : BadgeVariant.error,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        key: Key('toggle_cashier_status_${c.id}'),
                        onPressed: () =>
                            _confirmToggleCashierStatus(context, c),
                        child: Text(c.isActive ? 'Nonaktifkan' : 'Aktifkan'),
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
        title: Text('Proses Refund Pesanan $orderId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Refund (Rp) *',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan Refund (Wajib) *',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel.tr),
          ),
          ElevatedButton(
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
            child: const Text('Konfirmasi Refund'),
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
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...controller.orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
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
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Metode: ${o.paymentMethod.name.toUpperCase()} • Status Bayar: ${o.paymentStatus} • Total: ${formatRupiah(o.grandTotal)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (o.paymentStatus == 'paid')
                      OutlinedButton(
                        onPressed: () =>
                            _openRefundDialog(context, o.orderId, o.grandTotal),
                        child: const Text('Refund'),
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
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Audit log bersifat append-only (immutable) dan tidak dapat diubah atau dihapus.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ...controller.auditLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${log.actorName} (${log.actorRole.toUpperCase()}) • ${log.action}',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: log.status.toUpperCase(),
                          variant: log.status == 'success'
                              ? BadgeVariant.success
                              : BadgeVariant.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Objek: ${log.entityType} (${log.entityId})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (log.beforeData != null || log.afterData != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Sebelum: ${log.beforeData ?? "-"} → Sesudah: ${log.afterData ?? "-"}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontSize: 12,
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

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.adminNavProfile.tr,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text('Email: ${profile?.email ?? "-"} • Role: ADMIN (Read-Only)'),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: AppStrings.authFullNameLabel.tr,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            decoration: InputDecoration(
              labelText: AppStrings.authPhoneLabel.tr,
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: AppStrings.save.tr,
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
          ),
        ],
      ),
    );
  }
}
