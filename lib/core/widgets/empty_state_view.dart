import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? imagePath;
  final IconData? icon;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.imagePath,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isShortHeight = MediaQuery.sizeOf(context).height < 500;
    final iconSize = isShortHeight ? 32.0 : 44.0;
    final circleSize = isShortHeight ? 64.0 : 96.0;
    final verticalPadding = isShortHeight ? 16.0 : 32.0;
    final spacing = isShortHeight ? 12.0 : 24.0;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null && imagePath!.isNotEmpty)
              Image.asset(
                imagePath!,
                height: isShortHeight ? 90 : 140,
                fit: BoxFit.contain,
                cacheHeight: 280,
              )
            else
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    icon ?? Icons.inbox_outlined,
                    size: iconSize,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            SizedBox(height: spacing),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (isShortHeight
                      ? AppTypography.titleMedium
                      : AppTypography.titleLarge)
                  .copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.muted,
                height: 1.35,
                fontSize: isShortHeight ? 12.5 : 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: spacing),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
