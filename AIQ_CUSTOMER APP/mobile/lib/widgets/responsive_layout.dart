import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakpoint;
}

/// A wrapper widget that constrains content width on larger screens (laptop/desktop)
/// while allowing standard edge padding on mobile devices.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool showCardOnDesktop;
  final Color? backgroundColor;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 580.0,
    this.padding = const EdgeInsets.all(24.0),
    this.showCardOnDesktop = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    Widget content = child;

    if (isDesktop && showCardOnDesktop) {
      content = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: padding,
        child: child,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: (isDesktop && showCardOnDesktop)
              ? const EdgeInsets.symmetric(vertical: 36, horizontal: 16)
              : padding,
          child: content,
        ),
      ),
    );
  }
}
