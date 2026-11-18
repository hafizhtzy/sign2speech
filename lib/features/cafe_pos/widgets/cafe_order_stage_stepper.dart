import 'package:flutter/material.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

import '../domain/models/order_enums.dart';

/// Widget stepper horizontal 3 tahap untuk alur pesanan Meja Kasir V2.
///
/// Tampilan: [① Pesan & AI] ── [② Nama & Bayar] ── [③ Ambil Kopi]
/// Saat [idle], stepper disembunyikan (height = 0).
class CafeOrderStageStepper extends StatelessWidget {
  final CafeOrderStage currentStage;
  final bool isDark;

  const CafeOrderStageStepper({
    super.key,
    required this.currentStage,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStage == CafeOrderStage.idle) {
      return const SizedBox.shrink();
    }

    final steps = [
      _StepItem(
        index: 0,
        number: '①',
        label: 'Pesan & AI',
        stage: CafeOrderStage.ordering,
      ),
      _StepItem(
        index: 1,
        number: '②',
        label: 'Nama & Bayar',
        stage: CafeOrderStage.naming,
      ),
      _StepItem(
        index: 2,
        number: '③',
        label: 'Ambil Kopi',
        stage: CafeOrderStage.pickup,
      ),
    ];

    final currentIndex = currentStage.stepIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      color: isDark ? AppColors.darkCanvas : AppColors.canvas,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _buildStep(
                step: steps[i],
                currentIndex: currentIndex,
              ),
            ),
            if (i < steps.length - 1)
              _buildConnector(isCompleted: currentIndex > i),
          ],
        ],
      ),
    );
  }

  Widget _buildStep({
    required _StepItem step,
    required int currentIndex,
  }) {
    final isCompleted = currentIndex > step.index;
    final isActive = currentIndex == step.index;

    final Color dotColor = isCompleted
        ? AppColors.matcha
        : (isActive ? AppColors.secondary : AppColors.border);

    final Color labelColor = isCompleted
        ? AppColors.matcha
        : (isActive ? AppColors.ink : AppColors.muted);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.matcha.withValues(alpha: 0.14)
                : (isActive
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: dotColor,
              width: isActive ? 1.8 : 1.2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 15, color: AppColors.matcha)
                : Text(
                    '${step.index + 1}',
                    style: AppTypography.labelSmall.copyWith(
                      color: isActive ? AppColors.secondary : AppColors.muted,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          step.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: labelColor,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Expanded(
      flex: 0,
      child: Container(
        width: 24,
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.matcha : AppColors.border,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _StepItem {
  final int index;
  final String number;
  final String label;
  final CafeOrderStage stage;

  const _StepItem({
    required this.index,
    required this.number,
    required this.label,
    required this.stage,
  });
}
