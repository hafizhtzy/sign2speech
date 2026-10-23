import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Elevated tactile card component adhering to the Nordic / Cafe & Instagram Dark design system.
/// Automatically resolves responsive theme background, borders, and touch feedback.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final BorderSide? border;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.border,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 16,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surface;
    final effectiveBorder =
        border ?? BorderSide(color: AppColors.border, width: 1);

    return Material(
      color: effectiveBg,
      elevation: elevation,
      shadowColor: AppColors.isDark
          ? Colors.transparent
          : AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: effectiveBorder,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.secondary.withValues(alpha: 0.08),
        highlightColor: AppColors.secondary.withValues(alpha: 0.04),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
