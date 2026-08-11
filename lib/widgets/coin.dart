import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum CoinTone { mint, gold }

/// The brand mark — a raised metallic coin with a symbol, used for the
/// logo, reward icon, and success checkmark, matching the design system's
/// `Coin` component.
class Coin extends StatefulWidget {
  const Coin({
    super.key,
    required this.symbol,
    this.tone = CoinTone.mint,
    this.size = 42,
    this.spin = false,
    this.glow = true,
  });

  final String symbol;
  final CoinTone tone;
  final double size;
  final bool spin;
  final bool glow;

  @override
  State<Coin> createState() => _CoinState();
}

class _CoinState extends State<Coin> with SingleTickerProviderStateMixin {
  // Assigned in initState, not via a `late` field initializer: the vsync
  // ancestor lookup it triggers needs the widget properly mounted. A
  // lazy `late final = AnimationController(...)` initializer runs on
  // first access — which, for any non-spinning Coin (the common case,
  // since nothing else ever touches `_controller`), ends up being inside
  // dispose(), on an already-deactivating widget, and throws.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.spin) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.tone == CoinTone.mint
        ? const [Color(0xFF5FF3C0), AppColors.mint500, AppColors.mint700]
        : const [Color(0xFFFFF0C4), AppColors.gold400, AppColors.gold600];
    final glowColor = widget.tone == CoinTone.mint ? AppColors.mintGlow : AppColors.goldGlow;

    Widget coin = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        boxShadow: widget.glow
            ? [BoxShadow(color: glowColor, blurRadius: widget.size * 0.9, spreadRadius: -widget.size * 0.15)]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        widget.symbol,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: widget.size * 0.42,
          fontWeight: FontWeight.w900,
          color: AppColors.ink900,
        ),
      ),
    );

    if (!widget.spin) return coin;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.rotate(angle: _controller.value * 6.283185, child: child),
      child: coin,
    );
  }
}
