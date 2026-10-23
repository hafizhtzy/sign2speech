import 'package:flutter/material.dart';

/// Official Flutter / Material 3 Responsive Breakpoints & Window Size Classes.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Standard compact breakpoint threshold (Phones portrait < 600dp).
  static const double compactMaxWidth = 600.0;

  /// Standard medium breakpoint threshold (Foldables & Tablets portrait 600 - 839dp).
  static const double mediumMaxWidth = 840.0;

  /// Default optimal readable container width for forms, onboarding, and dialogs.
  static const double maxFormWidth = 580.0;

  /// Default optimal readable container width for settings, reading panes, and detail views.
  static const double maxContentWidth = 960.0;

  /// Default optimal container width for dashboards and list grids.
  static const double maxDashboardWidth = 1140.0;
}

/// Window Size Class enum.
enum WindowSizeClass {
  compact,
  medium,
  expanded,
}

/// Extension on [BuildContext] for clean and performant responsive queries.
extension ResponsiveContext on BuildContext {
  /// Window Size Class derived from available window width.
  WindowSizeClass get windowSizeClass {
    final width = MediaQuery.sizeOf(this).width;
    if (width < ResponsiveBreakpoints.compactMaxWidth) {
      return WindowSizeClass.compact;
    } else if (width < ResponsiveBreakpoints.mediumMaxWidth) {
      return WindowSizeClass.medium;
    } else {
      return WindowSizeClass.expanded;
    }
  }

  /// Whether current app window is phone / compact form factor (< 600dp).
  bool get isCompact => windowSizeClass == WindowSizeClass.compact;

  /// Whether current app window is foldable / tablet portrait (600 - 839dp).
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;

  /// Whether current app window is tablet landscape or desktop (>= 840dp).
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;

  /// Whether current window is considered a large screen (tablet, desktop, or landscape >= 600dp).
  bool get isLargeScreen =>
      MediaQuery.sizeOf(this).width >= ResponsiveBreakpoints.compactMaxWidth;
}

/// Adaptive layout builder widget evaluating available width constraints
/// from the parent widget rather than full screen window.
class AdaptiveLayout extends StatelessWidget {
  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.mediumMaxWidth) {
          return (expanded ?? medium ?? compact)(context);
        } else if (constraints.maxWidth >=
            ResponsiveBreakpoints.compactMaxWidth) {
          return (medium ?? compact)(context);
        } else {
          return compact(context);
        }
      },
    );
  }
}

/// A centered container that enforces a maximum readable width
/// on wide screens (tablets, desktops) while expanding naturally on mobile.
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxDashboardWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
