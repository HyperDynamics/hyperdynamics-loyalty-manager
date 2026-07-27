import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/payment_order.dart';
import '../../providers/payment_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coin.dart';

/// B. Post-Payment Confirmation Page — reflects the *webhook-confirmed*
/// status in Firestore, not the redirect query params (which could be
/// stale or spoofed), matching the spec's "shown if redirected back
/// without confirmed webhook success" requirement.
class PaymentConfirmScreen extends ConsumerWidget {
  const PaymentConfirmScreen({super.key, required this.referenceId});

  final String referenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(paymentOrderProvider(referenceId));

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: orderAsync.when(
              loading: () => const _PendingCard(),
              error: (_, _) => const _FailureCard(),
              data: (order) {
                if (referenceId.isEmpty || order == null) return const _FailureCard();
                return switch (order.status) {
                  PaymentOrderStatus.paid => const _SuccessCard(),
                  PaymentOrderStatus.failed => const _FailureCard(),
                  PaymentOrderStatus.created => const _PendingCard(),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 40,
      glow: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Coin(symbol: '✓', size: 76, spin: true),
          const SizedBox(height: 20),
          Text('payment received', style: AppTypography.h1, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'check your email for your business id and password.',
            style: AppTypography.sm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          AppButton(
            label: 'go to admin login',
            block: true,
            size: AppButtonSize.lg,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.mint400),
          ),
          const SizedBox(height: 20),
          Text('confirming your payment…', style: AppTypography.h3, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            "this usually takes a few seconds. if it's been a while, contact support and we'll sort it out.",
            style: AppTypography.sm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text('support: help@hyperdynamics.app', style: AppTypography.xs.copyWith(color: AppColors.textLink)),
        ],
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.loss),
          const SizedBox(height: 16),
          Text('payment not confirmed', style: AppTypography.h3, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            "we couldn't confirm this payment. if you were charged, contact support — otherwise you can retry.",
            style: AppTypography.sm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text('support: help@hyperdynamics.app', style: AppTypography.xs.copyWith(color: AppColors.textLink)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'retry payment',
                  variant: AppButtonVariant.outline,
                  block: true,
                  onPressed: () => context.go('/'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'contact support',
                  block: true,
                  onPressed: () => context.go('/login'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
