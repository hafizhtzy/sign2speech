import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Data class representing an item within the [FloatingPillNavBar].
class FloatingPillNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const FloatingPillNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// A 60-120fps-optimized floating capsule bottom navigation bar.
/// Follows Cafe Warm Oat Milk / Espresso design language and Instagram AMOLED Minimalist.
/// Features a continuous gliding pill indicator, sub-pixel width interpolation
/// (zero integer flex snaps), isolated GPU frosted glass blur, smooth label reveal,
/// and accessible touch targets (>= 48x48 dp).
class FloatingPillNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingPillNavItem> items;

  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingPillNavBar> createState() => _FloatingPillNavBarState();
}

class _FloatingPillNavBarState extends State<FloatingPillNavBar>
    with SingleTickerProviderStateMixin {
  static const double _activeExtraWeight = 1.0;
  static const Duration _transitionDuration = Duration(milliseconds: 340);

  late final AnimationController _controller;
  late final Animation<double> _curved;

  late List<double> _startWeights;
  late List<double> _targetWeights;
  double _startPillLeftRatio = 0.0;
  double _startPillWidthRatio = 0.0;
  double _targetPillLeftRatio = 0.0;
  double _targetPillWidthRatio = 0.0;
  int? _pressedIndex;

  int get _safeIndex =>
      widget.items.isEmpty ? 0 : widget.currentIndex.clamp(0, widget.items.length - 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _transitionDuration);
    _curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _initGeometry(_safeIndex);
    _controller.value = 1.0;
  }

  void _initGeometry(int activeIndex) {
    final count = widget.items.length;
    _targetWeights = List<double>.generate(
      count,
      (i) => i == activeIndex ? 1.0 : 0.0,
    );
    _startWeights = List<double>.of(_targetWeights);
    final (left, width) = _computePillRatios(_targetWeights, activeIndex);
    _startPillLeftRatio = left;
    _startPillWidthRatio = width;
    _targetPillLeftRatio = left;
    _targetPillWidthRatio = width;
  }

  (double, double) _computePillRatios(List<double> weights, int activeIndex) {
    if (weights.isEmpty) return (0.0, 0.0);
    double total = 0.0;
    for (final w in weights) {
      total += 1.0 + _activeExtraWeight * w;
    }
    if (total <= 0.0) return (0.0, 0.0);

    double left = 0.0;
    for (int i = 0; i < activeIndex && i < weights.length; i++) {
      left += (1.0 + _activeExtraWeight * weights[i]) / total;
    }
    final width = (1.0 + _activeExtraWeight * weights[activeIndex]) / total;
    return (left, width);
  }

  @override
  void didUpdateWidget(FloatingPillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _initGeometry(_safeIndex);
      _controller.value = 1.0;
      return;
    }
    if (oldWidget.currentIndex != widget.currentIndex) {
      final t = _curved.value;
      // Snapshot current mid-flight positions so rapid taps stay silky smooth
      _startWeights = List<double>.generate(
        widget.items.length,
        (i) => lerpDouble(_startWeights[i], _targetWeights[i], t)!,
      );
      _startPillLeftRatio = lerpDouble(
        _startPillLeftRatio,
        _targetPillLeftRatio,
        t,
      )!;
      _startPillWidthRatio = lerpDouble(
        _startPillWidthRatio,
        _targetPillWidthRatio,
        t,
      )!;

      final nextIndex = _safeIndex;
      _targetWeights = List<double>.generate(
        widget.items.length,
        (i) => i == nextIndex ? 1.0 : 0.0,
      );
      final (nextLeft, nextWidth) = _computePillRatios(
        _targetWeights,
        nextIndex,
      );
      _targetPillLeftRatio = nextLeft;
      _targetPillWidthRatio = nextWidth;

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != _safeIndex) {
      HapticFeedback.lightImpact();
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final isDark = AppColors.isDark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final activeBg = isDark ? AppColors.secondary : AppColors.primary;
    final activeFg = isDark ? AppColors.darkCanvas : AppColors.surface;
    final inactiveFg = AppColors.muted;

    return RepaintBoundary(
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          bottomInset > 0 ? bottomInset + 8 : 16,
        ),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(33),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.32)
                        : AppColors.lightPrimary.withValues(alpha: 0.08),
                    blurRadius: isDark ? 10 : 16,
                    offset: Offset(0, isDark ? 3 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(33),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 66,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(
                        alpha: isDark ? 0.84 : 0.88,
                      ),
                      borderRadius: BorderRadius.circular(33),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorderSoft.withValues(alpha: 0.70)
                            : AppColors.lightBorder.withValues(alpha: 0.65),
                        width: 1.1,
                      ),
                    ),
                    // Isolate pill slide animation from BackdropFilter raster layer
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final innerWidth = constraints.maxWidth;
                          return AnimatedBuilder(
                            animation: _curved,
                            builder: (context, _) {
                              final t = _curved.value;
                              final count = widget.items.length;

                              // Compute smoothly interpolated per-slot widths
                              final progresses = List<double>.generate(
                                count,
                                (i) => lerpDouble(
                                  _startWeights[i],
                                  _targetWeights[i],
                                  t,
                                )!.clamp(0.0, 1.0),
                              );

                              double totalWeight = 0.0;
                              for (final p in progresses) {
                                totalWeight += 1.0 + _activeExtraWeight * p;
                              }

                              final pillLeft =
                                  innerWidth *
                                  lerpDouble(
                                    _startPillLeftRatio,
                                    _targetPillLeftRatio,
                                    t,
                                  )!;
                              final pillWidth =
                                  innerWidth *
                                  lerpDouble(
                                    _startPillWidthRatio,
                                    _targetPillWidthRatio,
                                    t,
                                  )!;

                              double cursorLeft = 0.0;
                              final slotWidgets = <Widget>[];

                              for (int i = 0; i < count; i++) {
                                final p = progresses[i];
                                final slotWidth =
                                    innerWidth *
                                    ((1.0 + _activeExtraWeight * p) /
                                        totalWeight);
                                final slotLeft = cursorLeft;
                                cursorLeft += slotWidth;

                                final item = widget.items[i];
                                final isSelected = i == _safeIndex;
                                final isPressed = _pressedIndex == i;
                                final iconColor = Color.lerp(
                                  inactiveFg,
                                  activeFg,
                                  p,
                                )!;
                                final iconSize = lerpDouble(22.0, 20.0, p)!;
                                final showLabel = p > 0.02;
                                final labelOpacity =
                                    ((p - 0.25) / 0.75).clamp(0.0, 1.0);

                                slotWidgets.add(
                                  Positioned(
                                    key: ValueKey('nav_item_$i'),
                                    left: slotLeft,
                                    top: 0,
                                    bottom: 0,
                                    width: slotWidth,
                                    child: Semantics(
                                      label: item.label,
                                      selected: isSelected,
                                      button: true,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (_) {
                                          if (_pressedIndex != i) {
                                            setState(() => _pressedIndex = i);
                                          }
                                        },
                                        onTapUp: (_) {
                                          if (_pressedIndex != null) {
                                            setState(
                                              () => _pressedIndex = null,
                                            );
                                          }
                                        },
                                        onTapCancel: () {
                                          if (_pressedIndex != null) {
                                            setState(
                                              () => _pressedIndex = null,
                                            );
                                          }
                                        },
                                        onTap: () => _handleTap(i),
                                        child: AnimatedScale(
                                          scale: isPressed ? 0.93 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 110,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: lerpDouble(
                                                4.0,
                                                12.0,
                                                p,
                                              )!,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: .center,
                                              children: [
                                                Icon(
                                                  p >= 0.5
                                                      ? (item.selectedIcon ??
                                                            item.icon)
                                                      : item.icon,
                                                  size: iconSize,
                                                  color: iconColor,
                                                ),
                                                if (showLabel)
                                                  Flexible(
                                                    child: ClipRect(
                                                      child: Align(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .centerStart,
                                                        widthFactor: p,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 6,
                                                              ),
                                                          child: Text(
                                                            item.label,
                                                            maxLines: 1,
                                                            softWrap: false,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTypography
                                                                .labelMedium
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: activeFg
                                                                      .withValues(
                                                                        alpha:
                                                                            labelOpacity,
                                                                      ),
                                                                  letterSpacing:
                                                                      0.2,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Gliding active pill indicator
                                  Positioned(
                                    left: pillLeft,
                                    top: 0,
                                    bottom: 0,
                                    width: pillWidth,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: activeBg,
                                        borderRadius: BorderRadius.circular(27),
                                      ),
                                    ),
                                  ),
                                  ...slotWidgets,
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
