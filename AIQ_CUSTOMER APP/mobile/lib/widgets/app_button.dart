import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final Widget? icon;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height = 56,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Color fgColor;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        fgColor = widget.onPressed == null ? Colors.white54 : Colors.white;
        break;
      case AppButtonVariant.danger:
        fgColor = widget.onPressed == null ? Colors.white54 : Colors.white;
        break;
      case AppButtonVariant.secondary:
        fgColor = widget.onPressed == null ? AppColors.textMuted : AppColors.textPrimary;
        break;
      case AppButtonVariant.outline:
        fgColor = widget.onPressed == null ? AppColors.primary.withOpacity(0.4) : AppColors.primary;
        break;
      case AppButtonVariant.ghost:
        fgColor = widget.onPressed == null ? AppColors.textMuted : AppColors.textPrimary;
        break;
    }

    final child = widget.isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: fgColor,
                ),
              ),
            ],
          );

    final buttonStyle = switch (widget.variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          disabledBackgroundColor: widget.onPressed == null ? AppColors.primary.withOpacity(0.2) : AppColors.primary,
          disabledForegroundColor: fgColor,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(widget.fullWidth ? double.infinity : 0, widget.height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
      AppButtonVariant.danger => ElevatedButton.styleFrom(
          disabledBackgroundColor: widget.onPressed == null ? AppColors.error.withOpacity(0.2) : AppColors.error,
          disabledForegroundColor: fgColor,
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          minimumSize: Size(widget.fullWidth ? double.infinity : 0, widget.height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
          disabledBackgroundColor: widget.onPressed == null ? AppColors.surfaceElevated : AppColors.border,
          disabledForegroundColor: fgColor,
          backgroundColor: AppColors.border,
          foregroundColor: AppColors.textPrimary,
          minimumSize: Size(widget.fullWidth ? double.infinity : 0, widget.height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
      AppButtonVariant.outline => OutlinedButton.styleFrom(
          disabledForegroundColor: fgColor,
          foregroundColor: AppColors.primary,
          minimumSize: Size(widget.fullWidth ? double.infinity : 0, widget.height),
          side: BorderSide(color: widget.onPressed == null ? AppColors.border.withOpacity(0.5) : AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      AppButtonVariant.ghost => TextButton.styleFrom(
          disabledForegroundColor: fgColor,
          foregroundColor: AppColors.textPrimary,
          minimumSize: Size(widget.fullWidth ? double.infinity : 0, widget.height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: Colors.transparent,
        ),
    };

    Widget buttonWidget;
    if (widget.variant == AppButtonVariant.outline) {
      buttonWidget = OutlinedButton(
        style: buttonStyle as ButtonStyle,
        onPressed: null, // We handle taps manually to sync with animation
        child: child,
      );
    } else {
      buttonWidget = ElevatedButton(
        style: buttonStyle as ButtonStyle,
        onPressed: null, // We handle taps manually to sync with animation
        child: child,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, childWidget) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: childWidget,
          );
        },
        child: buttonWidget,
      ),
    );
  }
}
