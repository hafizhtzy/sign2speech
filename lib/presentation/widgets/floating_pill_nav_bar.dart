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

/// A lightweight, 60fps-optimized floating capsule bottom navigation bar.
/// Follows Cafe Warm Oat Milk / Espresso design language and Instagram AMOLED Minimalist.
/// Features frosted glassmorphism background blur, tactile spring bounce animation,
/// fluid morphing pill selection, high contrast, and accessible touch targets (>= 48x48 dp).
class FloatingPillNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final activeBg = isDark ? AppColors.secondary : AppColors.primary;
    final activeFg = isDark ? AppColors.darkCanvas : Colors.white;

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(33),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.30 : 0.08,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(33),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 66,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(
                        alpha: isDark ? 0.78 : 0.88,
                      ),
                      borderRadius: BorderRadius.circular(33),
                      border: Border.all(
                        color: AppColors.border.withValues(
                          alpha: isDark ? 0.35 : 0.65,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;

                        return Expanded(
                          flex: isSelected ? 2 : 1,
                          child: _NavBarItemButton(
                            key: ValueKey('nav_item_$index'),
                            item: item,
                            isSelected: isSelected,
                            onTap: () => onTap(index),
                            activeBg: activeBg,
                            activeFg: activeFg,
                            inactiveFg: AppColors.muted,
                          ),
                        );
                      }),
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

/// An interactive nav bar item with tactile spring-scale bounce animation on tap.
class _NavBarItemButton extends StatefulWidget {
  final FloatingPillNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeBg;
  final Color activeFg;
  final Color inactiveFg;

  const _NavBarItemButton({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.activeBg,
    required this.activeFg,
    required this.inactiveFg,
  });

  @override
  State<_NavBarItemButton> createState() => _NavBarItemButtonState();
}

class _NavBarItemButtonState extends State<_NavBarItemButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Tactile spring bounce sequence: scale down to 0.91, then spring back to 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.91,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.91,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0.0);
    if (!widget.isSelected) {
      HapticFeedback.lightImpact();
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.item.label,
      selected: widget.isSelected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox.expand(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.center,
                padding: widget.isSelected
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                    : const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.activeBg
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isSelected
                          ? (widget.item.selectedIcon ?? widget.item.icon)
                          : widget.item.icon,
                      size: widget.isSelected ? 20 : 22,
                      color: widget.isSelected
                          ? widget.activeFg
                          : widget.inactiveFg,
                    ),
                    if (widget.isSelected) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.activeFg,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
