import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Who is posting this" line for the Earn and Redeem screens.
///
/// The same identity is stamped onto the transaction server-side
/// (`createdByName` in `earn.ts`/`redeem.ts`), so this is the on-screen half of
/// the same accountability: whoever is at the till can see which account the
/// entry will be recorded against before they post it.
class ActorChip extends ConsumerWidget {
  const ActorChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            session.isOwner ? Icons.verified_user_outlined : Icons.badge_outlined,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'posting as ${session.actorLabel}${session.isOwner ? '' : ' · staff'}',
              style: AppTypography.xs2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
