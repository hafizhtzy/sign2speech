import 'package:flutter/material.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import '../domain/models/dietary_alert_tag.dart';

class DietaryAlertBadge extends StatelessWidget {
  final DietaryAlertTag tag;
  final bool isCompact;

  const DietaryAlertBadge({
    super.key,
    required this.tag,
    this.isCompact = false,
  });

  Color _getBgColor() {
    switch (tag.severity) {
      case DietaryAlertSeverity.critical:
        return AppColors.amber.withValues(alpha: 0.15);
      case DietaryAlertSeverity.warning:
        return AppColors.amber.withValues(alpha: 0.12);
      case DietaryAlertSeverity.info:
        return AppColors.matcha.withValues(alpha: 0.12);
    }
  }

  Color _getBorderColor() {
    switch (tag.severity) {
      case DietaryAlertSeverity.critical:
        return AppColors.amber;
      case DietaryAlertSeverity.warning:
        return AppColors.amber;
      case DietaryAlertSeverity.info:
        return AppColors.matcha;
    }
  }

  Color _getTextColor() {
    switch (tag.severity) {
      case DietaryAlertSeverity.critical:
      case DietaryAlertSeverity.warning:
        return AppColors.amber;
      case DietaryAlertSeverity.info:
        return AppColors.matcha;
    }
  }

  IconData _getIcon() {
    switch (tag.type) {
      case DietaryAlertType.lactoseIntolerant:
        return Icons.water_drop_outlined;
      case DietaryAlertType.diabetesSugarAlert:
        return Icons.monitor_heart_outlined;
      case DietaryAlertType.nutAllergy:
        return Icons.warning_amber_rounded;
      case DietaryAlertType.dairyAllergy:
        return Icons.no_drinks_outlined;
      case DietaryAlertType.acidRefluxMaag:
        return Icons.healing_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBgColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getBorderColor(), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), size: 14, color: _getTextColor()),
            const SizedBox(width: 4),
            Text(
              tag.detectedKeyword.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: _getTextColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBgColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIcon(), size: 20, color: _getTextColor()),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tag.defaultMessageId,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
