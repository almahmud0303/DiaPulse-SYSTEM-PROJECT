import 'package:flutter/material.dart';

/// Simple responsive helpers for mobile/tablet/web layouts.
class Responsive {
  static const double phoneMax = 600;
  static const double tabletMax = 1024;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phoneMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= phoneMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// Max content width for centered layouts.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1400) return 1200;
    if (w >= tabletMax) return 1100;
    return double.infinity;
  }

  /// Adaptive page padding.
  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletMax) return const EdgeInsets.all(28);
    if (w >= phoneMax) return const EdgeInsets.all(22);
    return const EdgeInsets.all(16);
  }
}

/// Centers content and constrains its max width.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
        child: child,
      ),
    );
  }
}

