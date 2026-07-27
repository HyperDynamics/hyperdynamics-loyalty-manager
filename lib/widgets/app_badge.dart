import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppBadgeTone { mint, gold, loss, warn, info, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = AppBadgeTone.mint});

  final String label;
  final AppBadgeTone tone;

  (Color, Color) _colors() => switch (tone) {
    AppBadgeTone.mint => (AppColors.gainDim, AppColors.mint400),
    AppBadgeTone.gold => (const Color(0x33E8C87E), AppColors.gold400),
    AppBadgeTone.loss => (AppColors.lossDim, AppColors.loss),
    AppBadgeTone.warn => (AppColors.warnDim, AppColors.warn),
    AppBadgeTone.info => (const Color(0x334D86F0), AppColors.blue400),
    AppBadgeTone.neutral => (AppColors.surfaceHover, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: AppTypography.xs2.copyWith(color: fg, letterSpacing: 0.4),
      ),
    );
  }
}
