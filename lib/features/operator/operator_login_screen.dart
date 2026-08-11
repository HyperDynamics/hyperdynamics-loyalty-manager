import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/coin.dart';

/// Internal operator login — real email/password auth, gated server-side
/// by the `admin` custom claim (see `AdminRepository`). Not linked from
/// any public screen; reachable only by whoever knows this route.
class OperatorLoginScreen extends ConsumerStatefulWidget {
  const OperatorLoginScreen({super.key});

  @override
  ConsumerState<OperatorLoginScreen> createState() => _OperatorLoginScreenState();
}

class _OperatorLoginScreenState extends ConsumerState<OperatorLoginScreen> {
  String _email = '';
  String _password = '';
  String? _error;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await ref.read(adminRepositoryProvider).login(email: _email, password: _password);
      // On success, adminSessionProvider updates and the router redirect
      // to /hd-ops fires automatically.
    } on AdminFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElev,
        title: Text('reset password', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("enter your email and we'll send a reset link.", style: AppTypography.sm),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTypography.body,
              decoration: const InputDecoration(hintText: 'email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('send link')),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty) return;
    await ref.read(adminRepositoryProvider).sendPasswordReset(email);
    if (mounted) {
      ref.read(toastProvider.notifier).show('reset link sent if that account exists.', ToastTone.info);
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
                  Text('operator login', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text('internal use only.', style: AppTypography.sm),
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
                      child: Text(
                        _error!,
                        style: AppTypography.sm.copyWith(color: const Color(0xFFFFB9C4), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  AppInput(
                    label: 'email',
                    placeholder: 'you@example.com',
                    value: _email,
                    onChanged: (v) => setState(() {
                      _email = v;
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
                    onPressed: _submit,
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
