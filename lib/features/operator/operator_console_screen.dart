import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/admin_repository.dart';
import '../../models/admin_business_summary.dart';
import '../../models/pending_business.dart';
import '../../providers/admin_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_segmented_control.dart';
import '../../widgets/app_toggle.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/coin.dart';

/// Operator console — creates a business account directly, bypassing
/// self-signup. For friends & family or anyone admin wants to onboard
/// without them going through the signup form (see `createBusinessAccount`
/// on the backend, tagged `source: 'admin'`). Also hosts the pending-
/// approvals queue and the add-on feature-flag manager for self-signed-up
/// businesses.
class OperatorConsoleScreen extends ConsumerStatefulWidget {
  const OperatorConsoleScreen({super.key});

  @override
  ConsumerState<OperatorConsoleScreen> createState() => _OperatorConsoleScreenState();
}

class _OperatorConsoleScreenState extends ConsumerState<OperatorConsoleScreen> {
  String _businessName = '';
  String _ownerEmail = '';
  String _ownerPhone = '';
  String _plan = 'base';
  bool _submitting = false;
  String? _error;
  ({String businessId, String loginEmail, String tempPassword})? _result;

  Future<void> _logout() async {
    await ref.read(adminRepositoryProvider).logout();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final result = await ref.read(adminRepositoryProvider).createBusiness(
            businessName: _businessName.trim(),
            plan: _plan,
            ownerEmail: _ownerEmail.trim(),
            ownerPhone: _ownerPhone.trim(),
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _businessName = '';
        _ownerEmail = '';
        _ownerPhone = '';
        _plan = 'base';
      });
    } on AdminFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'network error — please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _businessName.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Coin(symbol: 'H', size: 36),
                          const SizedBox(width: 12),
                          Text('operator console', style: AppTypography.h2),
                        ],
                      ),
                      AppButton(label: 'log out', variant: AppButtonVariant.ghost, size: AppButtonSize.sm, onPressed: _logout),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    variant: AppCardVariant.elevated,
                    padding: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('create business', style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Text(
                          'provisions an account directly, bypassing self-signup. use for friends & family or test accounts.',
                          style: AppTypography.xs2.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 22),
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
                          label: 'business name',
                          placeholder: 'e.g. mint & co',
                          value: _businessName,
                          onChanged: (v) => setState(() => _businessName = v),
                        ),
                        const SizedBox(height: 14),
                        AppInput(
                          label: 'owner email (optional)',
                          placeholder: 'sent a welcome email if provided',
                          value: _ownerEmail,
                          onChanged: (v) => setState(() => _ownerEmail = v),
                        ),
                        const SizedBox(height: 14),
                        AppInput(
                          label: 'owner phone (optional)',
                          placeholder: '10-digit mobile',
                          value: _ownerPhone,
                          numeric: true,
                          maxLength: 10,
                          onChanged: (v) => setState(() => _ownerPhone = v),
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
                          label: 'create business',
                          block: true,
                          size: AppButtonSize.lg,
                          loading: _submitting,
                          onPressed: valid && !_submitting ? _submit : null,
                        ),
                      ],
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    _ResultCard(result: _result!),
                  ],
                  const SizedBox(height: 20),
                  const _PendingApprovalsCard(),
                  const SizedBox(height: 20),
                  const _ManageBusinessesCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ({String businessId, String loginEmail, String tempPassword}) result;

  void _copy(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: 'business id: ${result.businessId}\npassword: ${result.tempPassword}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 26,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBadge(label: 'created'),
          const SizedBox(height: 14),
          Text('share these credentials with the business owner:', style: AppTypography.sm),
          const SizedBox(height: 14),
          _row('business id', result.businessId),
          _row('login email', result.loginEmail),
          _row('temp password', result.tempPassword),
          const SizedBox(height: 16),
          AppButton(label: 'copy id + password', variant: AppButtonVariant.outline, onPressed: () => _copy(context)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: AppTypography.xs2)),
            Expanded(
              child: Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      );
}

/// Businesses that self-signed up (see `SignupScreen`/`selfSignup`) and are
/// waiting to be activated — either a Razorpay webhook will do it
/// automatically, or an admin approves here for payment collected outside
/// Razorpay.
class _PendingApprovalsCard extends ConsumerWidget {
  const _PendingApprovalsCard();

  Future<void> _approve(BuildContext context, WidgetRef ref, PendingBusiness business) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'approve ${business.displayName}?',
      body: 'this activates their account immediately — they will be able to log in and start using it right away.',
      confirmLabel: 'approve',
    );
    if (!confirmed) return;
    try {
      await ref.read(adminRepositoryProvider).approve(business.businessId);
      ref.invalidate(pendingBusinessesProvider);
    } on AdminFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingBusinessesProvider);

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('pending approvals', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(
            'self-signed-up businesses waiting on activation — approve here if you collected payment outside razorpay.',
            style: AppTypography.xs2.copyWith(height: 1.5),
          ),
          const SizedBox(height: 18),
          pending.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('could not load pending businesses.', style: AppTypography.sm)),
            ),
            data: (businesses) => businesses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('no pending businesses.', style: AppTypography.sm)),
                  )
                : Column(
                    children: [
                      for (final business in businesses) ...[
                        _PendingRow(business: business, onApprove: () => _approve(context, ref, business)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.business, required this.onApprove});
  final PendingBusiness business;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(business.displayName, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    AppBadge(label: business.otpEnabled ? '+ otp — ₹12,999' : 'standard — ₹7,999', tone: business.otpEnabled ? AppBadgeTone.gold : AppBadgeTone.mint),
                  ],
                ),
                const SizedBox(height: 2),
                Text(business.ownerEmail, style: AppTypography.xs2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppButton(label: 'approve', size: AppButtonSize.sm, onPressed: onApprove),
        ],
      ),
    );
  }
}

/// Add-on feature-flag manager — birthday nudges, whatsapp nudges, csv/pdf
/// export are sold separately from the ₹5k base tier; this is where admin
/// turns them on per business once they've paid for the add-on.
class _ManageBusinessesCard extends ConsumerStatefulWidget {
  const _ManageBusinessesCard();

  @override
  ConsumerState<_ManageBusinessesCard> createState() => _ManageBusinessesCardState();
}

class _ManageBusinessesCardState extends ConsumerState<_ManageBusinessesCard> {
  String _search = '';

  Future<void> _toggle(
    AdminBusinessSummary business, {
    bool? birthdayEnabled,
    bool? whatsappEnabled,
    bool? exportEnabled,
    int? maxConcurrentSessions,
  }) async {
    try {
      await ref.read(adminRepositoryProvider).updateFeatures(
            business.businessId,
            birthdayEnabled: birthdayEnabled,
            whatsappEnabled: whatsappEnabled,
            exportEnabled: exportEnabled,
            maxConcurrentSessions: maxConcurrentSessions,
          );
      ref.invalidate(adminBusinessesProvider(_search));
    } on AdminFailure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _checkMultiLocation(AdminBusinessSummary business) async {
    try {
      final result = await ref.read(adminRepositoryProvider).checkMultiLocation(business.businessId);
      if (mounted) _showMultiLocationResult(context, business.displayName, result);
    } on AdminFailure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _renew(AdminBusinessSummary business) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'renew ${business.displayName}?',
      body: 'extends their ₹999/year subscription by a year from whichever is later — today, or their current renewal date.',
      confirmLabel: 'renew',
    );
    if (!confirmed) return;
    try {
      await ref.read(adminRepositoryProvider).renewSubscription(business.businessId);
      ref.invalidate(adminBusinessesProvider(_search));
    } on AdminFailure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final businesses = ref.watch(adminBusinessesProvider(_search));

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('manage businesses', style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(
            'toggle add-on features per business — birthdays, whatsapp nudges, csv/pdf export.',
            style: AppTypography.xs2.copyWith(height: 1.5),
          ),
          const SizedBox(height: 18),
          AppInput(
            placeholder: 'search by name, id, or owner email',
            prefixText: '🔍',
            value: _search,
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 18),
          businesses.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('could not load businesses.', style: AppTypography.sm)),
            ),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('no businesses match.', style: AppTypography.sm)),
                  )
                : Column(
                    children: [
                      for (final business in rows) ...[
                        _ManageBusinessRow(
                          business: business,
                          onToggle: _toggle,
                          onRenew: () => _renew(business),
                          onCheckLocations: () => _checkMultiLocation(business),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ManageBusinessRow extends StatelessWidget {
  const _ManageBusinessRow({required this.business, required this.onToggle, required this.onRenew, required this.onCheckLocations});
  final AdminBusinessSummary business;
  final Future<void> Function(
    AdminBusinessSummary business, {
    bool? birthdayEnabled,
    bool? whatsappEnabled,
    bool? exportEnabled,
    int? maxConcurrentSessions,
  }) onToggle;
  final VoidCallback onRenew;
  final VoidCallback onCheckLocations;

  @override
  Widget build(BuildContext context) {
    final renewsAt = business.subscriptionRenewsAt;
    final lapsed = business.subscriptionLapsed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: lapsed ? AppColors.loss : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(business.displayName, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('${business.businessId} · ${business.ownerEmail}', style: AppTypography.xs2),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _FeatureSwitch(
                label: 'birthdays',
                checked: business.birthdayEnabled,
                onChanged: (v) => onToggle(business, birthdayEnabled: v),
              ),
              _FeatureSwitch(
                label: 'whatsapp',
                checked: business.whatsappEnabled,
                onChanged: (v) => onToggle(business, whatsappEnabled: v),
              ),
              _FeatureSwitch(
                label: 'export',
                checked: business.exportEnabled,
                onChanged: (v) => onToggle(business, exportEnabled: v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('max devices', style: AppTypography.xs2),
              const SizedBox(width: 10),
              _StepperButton(
                icon: Icons.remove_rounded,
                onPressed: business.maxConcurrentSessions > 1
                    ? () => onToggle(business, maxConcurrentSessions: business.maxConcurrentSessions - 1)
                    : null,
              ),
              SizedBox(
                width: 28,
                child: Text('${business.maxConcurrentSessions}', textAlign: TextAlign.center, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700)),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onPressed: business.maxConcurrentSessions < 20
                    ? () => onToggle(business, maxConcurrentSessions: business.maxConcurrentSessions + 1)
                    : null,
              ),
              const SizedBox(width: 10),
              Text('· ${business.activeSessionCount} active now', style: AppTypography.xs2),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  renewsAt == null
                      ? 'not yet approved — no subscription date'
                      : '${lapsed ? 'lapsed' : 'renews'} ${DateFormat('d MMM yyyy').format(renewsAt)}',
                  style: AppTypography.xs2.copyWith(color: lapsed ? AppColors.loss : AppColors.textTertiary),
                ),
              ),
              AppButton(label: 'check locations', size: AppButtonSize.sm, variant: AppButtonVariant.ghost, onPressed: onCheckLocations),
              const SizedBox(width: 8),
              if (renewsAt != null)
                AppButton(label: 'renew +1yr', size: AppButtonSize.sm, variant: AppButtonVariant.outline, onPressed: onRenew),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the raw evidence from `adminCheckMultiLocation` — deliberately not
/// a verdict ("this business is cheating"), just the data (which days saw
/// transactions from more than one network) so the operator can judge
/// context themselves before reaching out.
void _showMultiLocationResult(BuildContext context, String businessName, MultiLocationCheck result) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (context) => Dialog(
      backgroundColor: AppColors.surfaceElev,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$businessName — network activity', style: AppTypography.h3),
                const SizedBox(height: 6),
                Text(
                  'not proof of anything on its own — a business that\'s genuinely mobile (delivery, home visits) can look the same. use this as a starting point for a conversation, not a verdict.',
                  style: AppTypography.xs2.copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _StatBlock(label: 'days analyzed', value: '${result.daysAnalyzed}')),
                    Expanded(child: _StatBlock(label: 'distinct networks', value: '${result.totalDistinctIps}')),
                    Expanded(child: _StatBlock(label: 'multi-network days', value: '${result.multiIpDayCount}')),
                  ],
                ),
                const SizedBox(height: 18),
                if (result.multiIpDays.isEmpty)
                  Text('no days with more than one network — nothing to flag.', style: AppTypography.sm)
                else ...[
                  Text('days with multiple networks', style: AppTypography.xs.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  for (final d in result.multiIpDays)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(d.day, style: AppTypography.sm),
                          Text('${d.distinctIps} networks', style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                AppButton(label: 'close', block: true, variant: AppButtonVariant.outline, onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.h2),
        Text(label, style: AppTypography.xs2),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHover,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: onPressed == null ? AppColors.textDisabled : AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _FeatureSwitch extends StatelessWidget {
  const _FeatureSwitch({required this.label, required this.checked, required this.onChanged});
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.xs2),
        const SizedBox(width: 8),
        Transform.scale(
          scale: 0.7,
          child: AppToggle(checked: checked, onChanged: onChanged),
        ),
      ],
    );
  }
}
