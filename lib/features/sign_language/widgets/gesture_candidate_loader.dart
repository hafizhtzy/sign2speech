import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Candidate gesture badge with smooth clockwise stadium/capsule progress ring starting at 12 o'clock.
class GestureCandidateLoader extends StatelessWidget {
  final String label;
  final double progress;
  final bool isConfirmed;

  const GestureCandidateLoader({
    super.key,
    required this.label,
    required this.progress,
    this.isConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    final trimmed = label.trim();
    final isSingleChar = trimmed.length <= 1;
    final display = trimmed.toUpperCase();

    final double fontSize = isSingleChar
        ? 22.0
        : display.length <= 4
            ? 15.0
            : display.length <= 7
                ? 13.0
                : 11.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return CustomPaint(
          foregroundPainter: _CapsuleProgressPainter(
            progress: animatedProgress,
            progressColor: isConfirmed ? AppColors.success : AppColors.secondary,
            trackColor: Colors.white.withValues(alpha: 0.20),
            strokeWidth: 3.2,
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: AnimatedScale(
          scale: isConfirmed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Container(
            constraints: BoxConstraints(
              minWidth: isSingleChar ? 46 : 52,
              minHeight: isSingleChar ? 46 : 40,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSingleChar ? 12 : 14,
              vertical: isSingleChar ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(isSingleChar ? 24 : 20),
              border: Border.all(
                color: isConfirmed
                    ? AppColors.success
                    : AppColors.border.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: isConfirmed ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1.0).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    display,
                    key: ValueKey(display),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isConfirmed) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dynamic stadium/capsule progress ring starting at 12 o'clock
class _CapsuleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CapsuleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final insetRect = rect.deflate(strokeWidth / 2);
    final radius = (insetRect.height / 2).clamp(0.0, insetRect.width / 2);

    final path = Path();
    final topCenter = Offset(
      insetRect.left + insetRect.width / 2,
      insetRect.top,
    );
    path.moveTo(topCenter.dx, topCenter.dy);

    // 1. Top edge: center to top-right
    path.lineTo(insetRect.right - radius, insetRect.top);
    // 2. Top-right arc
    path.arcToPoint(
      Offset(insetRect.right, insetRect.top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 3. Right edge
    path.lineTo(insetRect.right, insetRect.bottom - radius);
    // 4. Bottom-right arc
    path.arcToPoint(
      Offset(insetRect.right - radius, insetRect.bottom),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 5. Bottom edge
    path.lineTo(insetRect.left + radius, insetRect.bottom);
    // 6. Bottom-left arc
    path.arcToPoint(
      Offset(insetRect.left, insetRect.bottom - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 7. Left edge
    path.lineTo(insetRect.left, insetRect.top + radius);
    // 8. Top-left arc
    path.arcToPoint(
      Offset(insetRect.left + radius, insetRect.top),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // 9. Back to top center
    path.lineTo(topCenter.dx, topCenter.dy);

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, trackPaint);

    if (progress <= 0.001) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractLength = metric.length * progress.clamp(0.0, 1.0);
    final extractPath = metric.extractPath(0, extractLength);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CapsuleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
