import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

class CashierQuickDeck extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onExecute;
  final bool isEmbedded;

  const CashierQuickDeck({
    super.key,
    required this.activeIndex,
    required this.onExecute,
    this.isEmbedded = false,
  });

  static const List<_QuickDeckItem> _deckItems = [
    _QuickDeckItem(
      labelKey: AppStrings.quickDeck1,
      icon: Icons.local_cafe_outlined,
      tag: 'DINE-IN / TAKEAWAY',
    ),
    _QuickDeckItem(
      labelKey: AppStrings.quickDeck2,
      icon: Icons.format_size_rounded,
      tag: 'SIZE',
    ),
    _QuickDeckItem(
      labelKey: AppStrings.quickDeck3,
      icon: Icons.icecream_outlined,
      tag: 'ICE & SUGAR',
    ),
    _QuickDeckItem(
      labelKey: AppStrings.quickDeck4,
      icon: Icons.badge_outlined,
      tag: 'NAME SPELLING',
    ),
    _QuickDeckItem(
      labelKey: AppStrings.quickDeck5,
      icon: Icons.qr_code_2_rounded,
      tag: 'QRIS BILL',
    ),
    _QuickDeckItem(
      labelKey: AppStrings.quickDeck6,
      icon: Icons.handshake_outlined,
      tag: 'THANK YOU',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final listContent = Column(
      children: List.generate(_deckItems.length, (i) {
        final item = _deckItems[i];
        final isPlaying = activeIndex == i;

        return Padding(
          padding: EdgeInsets.only(bottom: i < _deckItems.length - 1 ? 8 : 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Material(
              color: isPlaying
                  ? AppColors.secondary.withValues(alpha: 0.12)
                  : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onExecute(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isPlaying
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.tag,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.labelKey.tr,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isPlaying
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                        color: isPlaying
                            ? AppColors.secondary
                            : AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );

    if (isEmbedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.cafeQuickDeckSubtitle.tr,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          listContent,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.paleMist,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeQuickDeckTitle.tr,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.cafeQuickDeckSubtitle.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          listContent,
        ],
      ),
    );
  }
}

class _QuickDeckItem {
  final String labelKey;
  final IconData icon;
  final String tag;

  const _QuickDeckItem({
    required this.labelKey,
    required this.icon,
    required this.tag,
  });
}
