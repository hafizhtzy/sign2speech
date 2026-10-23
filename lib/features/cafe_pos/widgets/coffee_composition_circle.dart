import 'package:flutter/material.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import '../domain/models/coffee_menu_item.dart';

class CoffeeCompositionCircle extends StatelessWidget {
  final CoffeeMenuItem item;
  final double size;

  const CoffeeCompositionCircle({
    super.key,
    required this.item,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size + 110,
        height: size + 60,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer subtle glow ring
            Container(
              width: size + 20,
              height: size + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),

            // Inner main circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.coffee_rounded,
                      size: size * 0.38,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.nameId,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Composition Point 1: Top Right (e.g. Microfoam)
            if (item.compositionPoints.isNotEmpty)
              Positioned(
                top: 8,
                right: 0,
                child: _buildCompositionCallout(
                  label: item.compositionPoints[0],
                  isRightAligned: true,
                ),
              ),

            // Composition Point 2: Top Left (e.g. Oat Milk)
            if (item.compositionPoints.length > 1)
              Positioned(
                top: 40,
                left: 0,
                child: _buildCompositionCallout(
                  label: item.compositionPoints[1],
                  isRightAligned: false,
                ),
              ),

            // Composition Point 3: Bottom Center/Right (e.g. Espresso)
            if (item.compositionPoints.length > 2)
              Positioned(
                bottom: 8,
                right: 12,
                child: _buildCompositionCallout(
                  label: item.compositionPoints[2],
                  isRightAligned: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionCallout({
    required String label,
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
            color: AppColors.secondary.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isRightAligned
          ? [
              dot,
              const SizedBox(width: 4),
              chip,
            ]
          : [
              chip,
              const SizedBox(width: 4),
              dot,
            ],
    );
  }
}
