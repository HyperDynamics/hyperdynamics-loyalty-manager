import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: accent ? AppCardVariant.elevated : AppCardVariant.standard,
      glow: accent,
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: AppTypography.figureMd.copyWith(
            color: accent ? AppColors.mint400 : AppColors.textPrimary,
          )),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.xs2),
        ],
      ),
    );
  }
}
