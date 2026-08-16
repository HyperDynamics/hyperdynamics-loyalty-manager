import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/coin.dart';

/// C. Admin Login Screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _businessId = '';
  String _password = '';
  String? _error;
  bool _submitting = false;
  bool _submittingGoogle = false;

  Future<void> _loginWithGoogle() async {
    setState(() {
      _error = null;
      _submittingGoogle = true;
    });
    try {
      await ref.read(authRepositoryProvider).loginWithGoogle();
      await ref.read(authSessionProvider.notifier).beginDeviceSession();
      // On success, the router redirect fires automatically.
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submittingGoogle = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final repo = ref.read(authRepositoryProvider);
    setState(() => _submitting = true);
    try {
      // Self-signed-up businesses log in with their own real email; every
      // other business (demo, admin-created, legacy razorpay) logs in with
      // its business id, which this screen still handles unchanged.
      if (_businessId.contains('@')) {
        await repo.loginWithEmail(email: _businessId, password: _password);
      } else {
        await repo.login(businessId: _businessId, password: _password);
      }
      await ref.read(authSessionProvider.notifier).beginDeviceSession();
      // On success, authSessionProvider updates and the router redirect
      // to /app/dashboard (or /pending) fires automatically.
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController();
    final businessId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElev,
        title: Text('reset password', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("enter your business id or email and we'll email you a reset link.", style: AppTypography.sm),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTypography.body,
              decoration: const InputDecoration(hintText: 'your business id or email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('send link')),
        ],
      ),
    );
    if (businessId == null || businessId.trim().isEmpty) return;
    try {
      final repo = ref.read(authRepositoryProvider);
      if (businessId.contains('@')) {
        await repo.sendPasswordResetForEmail(businessId);
      } else {
        await repo.sendPasswordReset(businessId);
      }
      if (mounted) {
        ref.read(toastProvider.notifier).show('reset link sent to your registered email.', ToastTone.info);
      }
    } catch (_) {
      if (mounted) {
        // Same generic messaging as login — don't reveal whether the id exists.
        ref.read(toastProvider.notifier).show('reset link sent to your registered email.', ToastTone.info);
      }
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              variant: AppCardVariant.elevated,
              padding: 38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Coin(symbol: 'H', size: 52),
                  const SizedBox(height: 18),
                  Text('admin login', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text('log in with your business id (or email) and password.', style: AppTypography.sm),
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
                    label: 'business id or email',
                    placeholder: 'your business id or email',
                    value: _businessId,
                    onChanged: (v) => setState(() {
                      _businessId = v;
                      _error = null;
                    }),
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    label: 'password',
                    placeholder: '••••••••',
                    obscureText: true,
                    value: _password,
                    onChanged: (v) => setState(() {
                      _password = v;
                      _error = null;
                    }),
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      child: Text('forgot password?', style: AppTypography.xs.copyWith(color: AppColors.textLink)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'log in',
                    block: true,
                    size: AppButtonSize.lg,
                    loading: _submitting,
                    onPressed: _submittingGoogle ? null : _submit,
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
                    label: 'sign in with google',
                    variant: AppButtonVariant.outline,
                    block: true,
                    size: AppButtonSize.lg,
                    loading: _submittingGoogle,
                    onPressed: _submitting ? null : _loginWithGoogle,
                  ),
                  const SizedBox(height: 8),
                  // Staff accounts are created with no password at all — the field
                  // above will never have anything to type, which otherwise reads as
                  // broken rather than "use the button below instead."
                  Text(
                    'staff members: sign in with google above — your account has no password.',
                    textAlign: TextAlign.center,
                    style: AppTypography.xs2,
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: Text("don't have an account? sign up", style: AppTypography.xs.copyWith(color: AppColors.textLink)),
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
