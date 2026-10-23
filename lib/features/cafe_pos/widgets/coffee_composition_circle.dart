import 'package:flutter/material.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import '../domain/models/coffee_menu_item.dart';

/// Interactive circular diagram depicting coffee layers and composition points.
///
/// Responsive to available parent width and follows the Cafe Warm Oat Milk design tokens.
class CoffeeCompositionCircle extends StatelessWidget {
  final CoffeeMenuItem item;
  final double size;

  const CoffeeCompositionCircle({
    super.key,
    required this.item,
    this.size = 190,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptively scale circle size if on a narrow display
        final maxAvail = constraints.maxWidth;
        final targetDiameter = (maxAvail - 90).clamp(150.0, size);
        final containerWidth = (targetDiameter + 100).clamp(280.0, maxAvail);
        final containerHeight = targetDiameter + 50;

        return Center(
          child: SizedBox(
            width: containerWidth,
            height: containerHeight,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Outer subtle orbit ring
                Container(
                  width: targetDiameter + 24,
                  height: targetDiameter + 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                ),

                // 2. Middle decorative dashed aura ring
                Container(
                  width: targetDiameter + 10,
                  height: targetDiameter + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.paleMist.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                ),

                // 3. Inner main coffee medallion
                Container(
                  width: targetDiameter,
                  height: targetDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Concentric latte cup emblem
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgSurface,
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.coffee_rounded,
                              size: targetDiameter * 0.28,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Beverage title
                          Text(
                            item.nameId,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Composition Point 1: Top Right (e.g. Steamed Oat Milk)
                if (item.compositionPoints.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 0,
                    child: _buildCompositionCallout(
                      label: item.compositionPoints[0],
                      icon: _pickPointIcon(item.compositionPoints[0]),
                      isRightAligned: true,
                    ),
                  ),

                // 5. Composition Point 2: Top Left (e.g. Low-Acid Shot)
                if (item.compositionPoints.length > 1)
                  Positioned(
                    top: 36,
                    left: 0,
                    child: _buildCompositionCallout(
                      label: item.compositionPoints[1],
                      icon: _pickPointIcon(item.compositionPoints[1]),
                      isRightAligned: false,
                    ),
                  ),

                // 6. Composition Point 3: Bottom Right (e.g. Silky Foam)
                if (item.compositionPoints.length > 2)
                  Positioned(
                    bottom: 12,
                    right: 8,
                    child: _buildCompositionCallout(
                      label: item.compositionPoints[2],
                      icon: _pickPointIcon(item.compositionPoints[2]),
                      isRightAligned: true,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _pickPointIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('shot') || lower.contains('espresso') || lower.contains('kopi')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('milk') || lower.contains('susu') || lower.contains('oat')) {
      return Icons.water_drop_rounded;
    } else if (lower.contains('foam') || lower.contains('busa') || lower.contains('crema')) {
      return Icons.cloud_outlined;
    }
    return Icons.auto_awesome_rounded;
  }

  Widget _buildCompositionCallout({
    required String label,
    required IconData icon,
    required bool isRightAligned,
  }) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.45),
            blurRadius: 4,
          ),
        ],
      ),
    );

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isRightAligned
          ? [
              dot,
              const SizedBox(width: 5),
              chip,
            ]
          : [
              chip,
              const SizedBox(width: 5),
              dot,
            ],
    );
  }
}
