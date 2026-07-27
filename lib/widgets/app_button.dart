import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, ghost, outline, danger }

enum AppButtonSize { sm, md, lg }

/// Pill button matching the design system's `Button` component
/// (primary / ghost / outline / danger, sm / md / lg, optional full-width).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.block = false,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool block;
  final bool loading;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false;
  bool _pressed = false;

  double get _height => switch (widget.size) {
    AppButtonSize.sm => 40.0,
    AppButtonSize.md => 48.0,
    AppButtonSize.lg => 58.0,
  };

  double get _fontSize => switch (widget.size) {
    AppButtonSize.sm => 13.0,
    AppButtonSize.md => 15.0,
    AppButtonSize.lg => 16.0,
  };

  EdgeInsets get _padding => switch (widget.size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 16),
    AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 22),
    AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 28),
  };

  bool get _disabled => widget.onPressed == null || widget.loading;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color? bg;
    Gradient? gradient;
    Border? border;
    List<BoxShadow>? shadow;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        fg = AppColors.onAccent;
        bg = null;
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2AF0B0), AppColors.mint500, AppColors.mint600],
        );
        shadow = _hover && !_disabled
            ? [BoxShadow(color: AppColors.mintGlow, blurRadius: 40, spreadRadius: -4)]
            : null;
        break;
      case AppButtonVariant.ghost:
        fg = AppColors.textPrimary;
        bg = _hover ? AppColors.surfaceHover : Colors.transparent;
        break;
      case AppButtonVariant.outline:
        fg = AppColors.textPrimary;
        bg = _hover ? AppColors.surfaceHover.withValues(alpha: 0.5) : Colors.transparent;
        border = Border.all(color: AppColors.borderStrong, width: 1.5);
        break;
      case AppButtonVariant.danger:
        fg = AppColors.white;
        bg = _hover ? const Color(0xFFF4506B) : AppColors.loss;
        break;
    }

    final opacity = _disabled ? 0.45 : 1.0;
    final scale = _pressed && !_disabled ? 0.97 : 1.0;

    Widget child = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 17, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: fg,
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor: _disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: AppDurations.fast,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: AppDurations.quick,
            child: AnimatedContainer(
              duration: AppDurations.quick,
              height: _height,
              width: widget.block ? double.infinity : null,
              padding: _padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: border,
                boxShadow: shadow,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
