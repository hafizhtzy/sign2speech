import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeVariant { neutral, active, success, warning, error }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case BadgeVariant.active:
        bg = AppColors.softFjord;
        fg = AppColors.secondary;
        border = AppColors.secondary.withValues(alpha: 0.3);
        break;
      case BadgeVariant.success:
        bg = AppColors.success.withValues(alpha: 0.1);
        fg = AppColors.success;
        border = AppColors.success.withValues(alpha: 0.3);
        break;
      case BadgeVariant.warning:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        border = AppColors.warning.withValues(alpha: 0.3);
        break;
      case BadgeVariant.error:
        bg = AppColors.error.withValues(alpha: 0.1);
        fg = AppColors.error;
        border = AppColors.error.withValues(alpha: 0.3);
        break;
      case BadgeVariant.neutral:
        bg = AppColors.paleMist;
        fg = AppColors.ink;
        border = AppColors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
