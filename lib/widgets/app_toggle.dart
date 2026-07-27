import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: AppDurations.quick,
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: checked ? AppColors.mint500 : AppColors.ink400,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
