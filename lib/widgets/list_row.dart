import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AmountTone { gain, loss, none }

enum AvatarTone { mint, ink, gold, violet, blue }

/// Row used throughout the app for recent activity / visit history / dashboard lists —
/// mirrors the design system's `ListRow` component.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.amount,
    this.amountTone = AmountTone.none,
    this.meta,
    this.avatarName,
    this.avatarTone = AvatarTone.mint,
    this.divider = true,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? amount;
  final AmountTone amountTone;
  final String? meta;
  final String? avatarName;
  final AvatarTone avatarTone;
  final bool divider;
  final VoidCallback? onTap;
  final Widget? trailing;

  Color get _avatarColor => switch (avatarTone) {
    AvatarTone.mint => AppColors.gainDim,
    AvatarTone.ink => AppColors.ink400,
    AvatarTone.gold => const Color(0x33E8C87E),
    AvatarTone.violet => const Color(0x338B6BF2),
    AvatarTone.blue => const Color(0x334D86F0),
  };

  Color get _avatarFg => switch (avatarTone) {
    AvatarTone.mint => AppColors.mint400,
    AvatarTone.ink => AppColors.textSecondary,
    AvatarTone.gold => AppColors.gold400,
    AvatarTone.violet => AppColors.violet400,
    AvatarTone.blue => AppColors.blue400,
  };

  Color get _amountColor => switch (amountTone) {
    AmountTone.gain => AppColors.gain,
    AmountTone.loss => AppColors.loss,
    AmountTone.none => AppColors.textDisabled,
  };

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (avatarName != null) ...[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _avatarColor, borderRadius: BorderRadius.circular(10)),
              child: Text(
                avatarName!,
                style: AppTypography.sm.copyWith(color: _avatarFg, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.xs2.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (trailing != null)
            trailing!
          else if (amount != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount!,
                  style: AppTypography.tabular(AppTypography.sm).copyWith(
                    color: _amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: AppTypography.xs2.copyWith(fontSize: 10, letterSpacing: 0.5)),
                ],
              ],
            ),
        ],
      ),
    );

    final content = Container(
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            )
          : null,
      child: row,
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
