import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppCardVariant { standard, elevated, glass, outline }

/// Surface card matching the design system's `Card` component.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.padding = 20,
    this.glow = false,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final AppCardVariant variant;
  final double padding;
  final bool glow;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool tappable = widget.interactive || widget.onTap != null;

    Color fill;
    Border? border;
    switch (widget.variant) {
      case AppCardVariant.standard:
        fill = AppColors.surfaceCard;
        border = Border.all(color: AppColors.borderSubtle);
        break;
      case AppCardVariant.elevated:
        fill = AppColors.surfaceElev;
        border = Border.all(color: AppColors.borderSoft);
        break;
      case AppCardVariant.glass:
        fill = AppColors.glassFill;
        border = Border.all(color: AppColors.glassBorder);
        break;
      case AppCardVariant.outline:
        fill = Colors.transparent;
        border = Border.all(color: _hover && tappable ? AppColors.borderStrong : AppColors.borderSoft);
        break;
    }

    Widget content = AnimatedContainer(
      duration: AppDurations.quick,
      padding: EdgeInsets.all(widget.padding),
      transform: Matrix4.translationValues(0, tappable && _hover ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: border,
        boxShadow: [
          if (widget.variant != AppCardVariant.outline)
            const BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 10)),
          if (widget.glow)
            BoxShadow(color: AppColors.mintGlow, blurRadius: 44, spreadRadius: -8),
        ],
      ),
      child: widget.child,
    );

    if (widget.variant == AppCardVariant.glass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: content,
        ),
      );
    }

    if (!tappable) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(onTap: widget.onTap, child: content),
    );
  }
}
