import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coin.dart';
import '../payment_confirm/launch_checkout.dart';

/// A. Public Landing Page (pre-signup).
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _starting = false;

  Future<void> _startPayment() async {
    setState(() => _starting = true);
    try {
      final busy = ref.read(busyProvider.notifier);
      final order = await busy.run(
        'redirecting to razorpay…',
        () => ref.read(paymentRepositoryProvider).createOnboardingPaymentLink(),
      );
      if (!mounted) return;
      await launchPaymentCheckout(context, checkoutUrl: order.checkoutUrl, referenceId: order.referenceId);
    } catch (_) {
      if (mounted) {
        ref.read(toastProvider.notifier).show('could not start payment. please try again.', ToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.containerMax),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onAdminLogin: () => context.go('/login')),
                  const SizedBox(height: 56),
                  wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 12, child: _Hero(onGetStarted: _starting ? null : _startPayment)),
                            const SizedBox(width: 32),
                            Expanded(flex: 9, child: _PricingCard(onGetStarted: _starting ? null : _startPayment)),
                          ],
                        )
                      : Column(
                          children: [
                            _Hero(onGetStarted: _starting ? null : _startPayment),
                            const SizedBox(height: 28),
                            _PricingCard(onGetStarted: _starting ? null : _startPayment),
                          ],
                        ),
                  const SizedBox(height: 72),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdminLogin});
  final VoidCallback onAdminLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Coin(symbol: 'H', size: 42),
            const SizedBox(width: 14),
            Text('hyperdynamics', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 19)),
          ],
        ),
        AppButton(label: 'admin login', variant: AppButtonVariant.ghost, size: AppButtonSize.sm, onPressed: onAdminLogin),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onGetStarted});
  final VoidCallback? onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'loyalty points,\nwithout the spreadsheet.',
          style: AppTypography.display.copyWith(fontSize: 52),
        ),
        const SizedBox(height: 18),
        Text(
          'earn, redeem, and correct customer loyalty points from one simple admin tool — no POS integration required.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary, fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 32),
        AppButton(label: 'get started — ₹5,000', size: AppButtonSize.lg, onPressed: onGetStarted),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.onGetStarted});
  final VoidCallback? onGetStarted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 34,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBadge(label: 'lifetime'),
          const SizedBox(height: 16),
          Text('₹5,000', style: AppTypography.figureXl),
          const SizedBox(height: 4),
          Text('one-time · flat fee', style: AppTypography.xs2),
          const SizedBox(height: 22),
          for (final feature in const ['earn points', 'redeem points', 'correction tool'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.mint400),
                  const SizedBox(width: 10),
                  Text(feature, style: AppTypography.body.copyWith(fontSize: 15)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text('otp verification for redemptions is a paid add-on.', style: AppTypography.xs2.copyWith(height: 1.5)),
          const SizedBox(height: 22),
          AppButton(label: 'get started — ₹5,000', block: true, size: AppButtonSize.lg, onPressed: onGetStarted),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderSubtle))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('© hyperdynamics', style: AppTypography.xs2),
          Text('support: help@hyperdynamics.app', style: AppTypography.xs2.copyWith(color: AppColors.textLink)),
        ],
      ),
    );
  }
}
