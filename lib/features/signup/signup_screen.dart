import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/auth_repository.dart';
import '../../data/signup_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_segmented_control.dart';
import '../../widgets/coin.dart';

/// Signup screen — collects business name, email, and a chosen password
/// *before* payment. Creates a pending business account (`selfSignup`
/// callable), then signs the owner in with the same credentials; the
/// router's redirect takes it from there (to `/pending`, since the account
/// isn't active yet).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.plan});

  final String? plan;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late String _plan = widget.plan == 'otp' ? 'otp' : 'base';
  String _businessName = '';
  String _email = '';
  String _password = '';
  String? _error;
  bool _submitting = false;
  bool _submittingGoogle = false;

  bool get _valid => _businessName.trim().isNotEmpty && _email.contains('@') && _password.length >= 6;

  Future<void> _submit() async {
    if (!_valid) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await ref.read(signupRepositoryProvider).selfSignup(
            businessName: _businessName.trim(),
            plan: _plan,
            email: _email.trim(),
            password: _password,
          );
      await ref.read(authRepositoryProvider).loginWithEmail(email: _email.trim(), password: _password);
      await ref.read(authSessionProvider.notifier).beginDeviceSession();
      // On success, authSessionProvider updates and the router redirect
      // to /pending fires automatically (the business isn't active yet).
    } on SignupFailure catch (e) {
      setState(() => _error = e.message);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitWithGoogle() async {
    if (_businessName.trim().isEmpty) {
      setState(() => _error = 'enter a business name before signing up with google.');
      return;
    }
    setState(() {
      _error = null;
      _submittingGoogle = true;
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogleCredentialOnly();
      await ref.read(signupRepositoryProvider).selfSignupWithGoogle(
            businessName: _businessName.trim(),
            plan: _plan,
          );
      // The claim was just granted server-side — force a real token
      // refresh so authSessionProvider (and the router redirect) sees it,
      // and so `beginSession`'s callable request carries a token that
      // actually has the businessId claim on it.
      await ref.read(authSessionProvider.notifier).refreshClaims();
      await ref.read(authSessionProvider.notifier).beginDeviceSession();
    } on SignupFailure catch (e) {
      setState(() => _error = e.message);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submittingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              variant: AppCardVariant.elevated,
              padding: 38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Coin(symbol: 'H', size: 52),
                  const SizedBox(height: 18),
                  Text('create your account', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text("set up your login now — you'll be approved once we've confirmed your payment.", style: AppTypography.sm),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lossDim,
                        border: Border.all(color: AppColors.loss),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(_error!, style: AppTypography.sm.copyWith(color: const Color(0xFFFFB9C4), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 18),
                  ],
                  AppInput(
                    label: 'business name',
                    placeholder: 'e.g. mint & co',
                    value: _businessName,
                    onChanged: (v) => setState(() => _businessName = v),
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    label: 'email',
                    placeholder: 'you@example.com',
                    value: _email,
                    onChanged: (v) => setState(() => _email = v),
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    label: 'password',
                    placeholder: 'at least 6 characters',
                    obscureText: true,
                    value: _password,
                    onChanged: (v) => setState(() => _password = v),
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 18),
                  Text('plan', style: AppTypography.xs.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  AppSegmentedControl(
                    options: const [
                      SegmentedOption('base', 'standard — ₹7,999'),
                      SegmentedOption('otp', '+ otp — ₹12,999'),
                    ],
                    value: _plan,
                    onChanged: (v) => setState(() => _plan = v),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'sign up',
                    block: true,
                    size: AppButtonSize.lg,
                    loading: _submitting,
                    onPressed: _valid && !_submitting && !_submittingGoogle ? _submit : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or', style: AppTypography.xs2),
                      ),
                      const Expanded(child: Divider(color: AppColors.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'sign up with google',
                    variant: AppButtonVariant.outline,
                    block: true,
                    size: AppButtonSize.lg,
                    loading: _submittingGoogle,
                    onPressed: !_submitting && !_submittingGoogle ? _submitWithGoogle : null,
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text('already have an account? log in', style: AppTypography.xs.copyWith(color: AppColors.textLink)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
