import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HoldConfirmRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Widget? child;

  const HoldConfirmRing({
    super.key,
    required this.progress,
    this.size = 110,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.paleMist.withValues(alpha: 0.5),
            ),
          ),
          // Progress ring
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.secondary,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
