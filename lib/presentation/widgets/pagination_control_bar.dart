import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Bilah navigasi pagination halaman dengan kontrol Sebelumnya, nomor halaman,
/// Selanjutnya, serta ringkasan jumlah item aktif.
class PaginationControlBar extends StatelessWidget {
  /// Halaman aktif saat ini (1-indexed, mulai dari 1)
  final int currentPage;

  /// Total seluruh halaman yang tersedia
  final int totalPages;

  /// Total seluruh item dalam filter saat ini
  final int totalItems;

  /// Jumlah item per halaman (default 12)
  final int itemsPerPage;

  /// Tampilkan teks ringkasan jumlah kosakata ("Menampilkan X-Y dari Z kosakata")
  final bool showItemCount;

  /// Callback ketika pengguna memilih halaman baru
  final ValueChanged<int> onPageChanged;

  const PaginationControlBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    this.itemsPerPage = 12,
    this.showItemCount = true,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 || totalItems == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final endItem = (currentPage * itemsPerPage).clamp(1, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Info Ringkasan Halaman (dan opsional jumlah item) ───────────
          Row(
            mainAxisAlignment: showItemCount
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              if (showItemCount) ...[
                Expanded(
                  child: Text(
                    AppStrings.paginationShowing.trParams({
                      'start': '$startItem',
                      'end': '$endItem',
                      'total': '$totalItems',
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBgSurface
                      : AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppStrings.paginationPageOf.trParams({
                    'page': '$currentPage',
                    'total': '$totalPages',
                  }),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── 2. Kontrol Navigasi (Prev, Page Numbers, Next) ──────────────────
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tombol Sebelumnya (Previous)
                  _buildNavButton(
                    context: context,
                    icon: Icons.chevron_left_rounded,
                    label: AppStrings.previous.tr,
                    enabled: currentPage > 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPageChanged(currentPage - 1);
                    },
                  ),
                  const SizedBox(width: 6),

                  // Daftar Angka Halaman
                  ..._buildPageChips(context, isDark),

                  const SizedBox(width: 6),

                  // Tombol Selanjutnya (Next)
                  _buildNavButton(
                    context: context,
                    icon: Icons.chevron_right_rounded,
                    label: AppStrings.next.tr,
                    isNext: true,
                    enabled: currentPage < totalPages,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPageChanged(currentPage + 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol aksi Sebelumnya / Selanjutnya dengan touch target >= 48dp
  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool isNext = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: enabled
                  ? (isDark
                      ? AppColors.darkBgSurface
                      : AppColors.bgSurface)
                  : (isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.5)
                      : AppColors.bgSurface.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? (isDark ? AppColors.darkBorder : AppColors.border)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isNext) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: enabled
                        ? (isDark ? AppColors.darkPrimary : AppColors.ink)
                        : (isDark ? AppColors.darkMuted : AppColors.muted)
                            .withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: enabled
                        ? (isDark ? AppColors.darkPrimary : AppColors.ink)
                        : (isDark ? AppColors.darkMuted : AppColors.muted)
                            .withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 4),
                  Icon(
                    icon,
                    size: 20,
                    color: enabled
                        ? (isDark ? AppColors.darkPrimary : AppColors.ink)
                        : (isDark ? AppColors.darkMuted : AppColors.muted)
                            .withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Menghitung dan merender nomor halaman dengan smart window
  List<Widget> _buildPageChips(BuildContext context, bool isDark) {
    final List<Widget> chips = [];
    final List<int> pageNumbers = _calculateVisiblePages();

    for (int i = 0; i < pageNumbers.length; i++) {
      final page = pageNumbers[i];

      // Sisipkan ellipsis jika ada celah halaman
      if (i > 0 && page > pageNumbers[i - 1] + 1) {
        chips.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '•••',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      final isSelected = page == currentPage;
      chips.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Semantics(
            label: 'Halaman $page',
            selected: isSelected,
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSelected
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onPageChanged(page);
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkBgSurface : AppColors.bgSurface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary)
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$page',
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected
                          ? (isDark ? AppColors.darkCanvas : AppColors.surface)
                          : (isDark ? AppColors.darkPrimary : AppColors.ink),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return chips;
  }

  /// Menentukan daftar nomor halaman yang tampil secara adaptif
  List<int> _calculateVisiblePages() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final Set<int> pages = {1, totalPages};
    pages.add(currentPage);

    if (currentPage - 1 >= 1) pages.add(currentPage - 1);
    if (currentPage + 1 <= totalPages) pages.add(currentPage + 1);

    // Pastikan minimal ada 3-4 halaman yang tampak di sekitar
    if (currentPage <= 2) {
      pages.add(2);
      pages.add(3);
    } else if (currentPage >= totalPages - 1) {
      pages.add(totalPages - 1);
      pages.add(totalPages - 2);
    }

    final list = pages.toList()..sort();
    return list;
  }
}
