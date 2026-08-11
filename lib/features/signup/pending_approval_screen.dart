import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/business_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coin.dart';

/// Shown to a signed-in business whose account is still `status: 'pending'`
/// — payment is collected outside the app, and admin approves once it's
/// confirmed. The router bounces here automatically (see `router.dart`) and
/// away again the moment the business's live `status` flips to `active`
/// (see the `currentBusinessProvider` listener wired in `app.dart`).
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  Future<void> _logout(WidgetRef ref) => ref.read(authRepositoryProvider).logout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              variant: AppCardVariant.elevated,
              padding: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Coin(symbol: 'H', size: 60),
                  const SizedBox(height: 20),
                  Text('almost there, ${business?.displayName ?? ''}', style: AppTypography.h1, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    "your account is created and pending approval. once we've confirmed your payment, our team will "
                    "activate it and you'll be able to log in right away.",
                    style: AppTypography.sm,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Text('questions? info@hyperdynamics.in', style: AppTypography.xs.copyWith(color: AppColors.textLink)),
                  const SizedBox(height: 22),
                  AppButton(label: 'log out', variant: AppButtonVariant.ghost, onPressed: () => _logout(ref)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
