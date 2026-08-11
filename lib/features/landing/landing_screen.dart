import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coin.dart';

/// A. Public Landing Page (pre-signup).
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _startSignup(BuildContext context) => context.go('/signup');

  Future<void> _contactSales() => launchUrl(
        Uri(scheme: 'mailto', path: 'info@hyperdynamics.in', queryParameters: {'subject': 'loyalty manager — get started'}),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.containerMax,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onAdminLogin: () => context.go('/login')),
                  const SizedBox(height: 56),
                  const _Hero(),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      AppButton(label: 'sign up', size: AppButtonSize.lg, onPressed: () => _startSignup(context)),
                      AppButton(label: 'contact sales', variant: AppButtonVariant.outline, size: AppButtonSize.lg, onPressed: _contactSales),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const _FeaturesCard(),
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
            Text(
              'hyperdynamics',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ],
        ),
        AppButton(
          label: 'admin login',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          onPressed: onAdminLogin,
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

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
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'earn, redeem, and correct customer loyalty points from one simple admin tool — no POS integration required. sign up or talk to sales to get started.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

const _coreFeatures = [
  'earn points on every bill',
  'redeem points anytime',
  'correction & reversal tool',
  'live dashboard & daily stats',
  'custom business branding',
  'configurable ₹-per-point ratio',
];

const _addOnFeatures = [
  'otp-verified redemptions',
  'birthday nudges — never miss a customer\'s birthday',
  'whatsapp reminders for pending points',
  'csv/pdf export of your full customer list',
];

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;

    Widget list(List<String> features, {bool accentGold = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: accentGold ? AppColors.gold400 : AppColors.mint400),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature, style: AppTypography.body.copyWith(fontSize: 15))),
                  ],
                ),
              ),
          ],
        );

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 34,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('what you get', style: AppTypography.xs.copyWith(letterSpacing: 1.2, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          wide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: list(_coreFeatures)),
                      const SizedBox(width: 32),
                      Expanded(child: list(_addOnFeatures, accentGold: true)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [list(_coreFeatures), const SizedBox(height: 8), list(_addOnFeatures, accentGold: true)],
                ),
          const SizedBox(height: 4),
          Text(
            'birthday nudges, whatsapp reminders, and csv/pdf export are paid add-ons on top of the base plan — talk to sales for pricing.',
            style: AppTypography.xs2.copyWith(height: 1.5),
          ),
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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('© hyperdynamics', style: AppTypography.xs2),
          Text(
            'support: help@hyperdynamics.app',
            style: AppTypography.xs2.copyWith(color: AppColors.textLink),
          ),
        ],
      ),
    );
  }
}
