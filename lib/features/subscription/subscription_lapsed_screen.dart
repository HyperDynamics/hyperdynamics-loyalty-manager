import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/business_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coin.dart';

/// Shown to a signed-in, *active* business whose ₹999/year subscription has
/// lapsed (`Business.subscriptionLapsed`) — blocks every app screen until
/// admin renews it (see `adminRenewSubscription`). The router bounces here
/// automatically and away again the moment the live `subscriptionRenewsAt`
/// moves into the future (same `currentBusinessProvider` listener wired in
/// `app.dart` that already drives the pending-approval screen).
class SubscriptionLapsedScreen extends ConsumerWidget {
  const SubscriptionLapsedScreen({super.key});

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
                  const Coin(symbol: '!', size: 60),
                  const SizedBox(height: 20),
                  Text('subscription renewal due', style: AppTypography.h1, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    "${business?.displayName ?? 'your account'}'s ₹999/year subscription has lapsed. "
                    "renew to get back into your dashboard — once we've confirmed payment, this unlocks automatically.",
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
