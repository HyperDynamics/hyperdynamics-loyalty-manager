import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../models/admin_business_summary.dart';
import '../../providers/admin_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/confirm_dialog.dart';

/// Staff seat management for one business. Operator-only by design: seats are
/// what HyperDynamics sells, so businesses can't add their own (what the owner
/// *does* control is the staff permission policy, in the app's own Settings).
///
/// Centred `Dialog` with `maxWidth: 440`, matching `showAppConfirmDialog` and
/// the rest of this app's popups.
void showStaffDialog(BuildContext context, AdminBusinessSummary business) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (context) => Dialog(
      backgroundColor: AppColors.surfaceElev,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: _StaffPanel(business: business),
      ),
    ),
  );
}

class _StaffPanel extends ConsumerStatefulWidget {
  const _StaffPanel({required this.business});
  final AdminBusinessSummary business;

  @override
  ConsumerState<_StaffPanel> createState() => _StaffPanelState();
}

class _StaffPanelState extends ConsumerState<_StaffPanel> {
  String _email = '';
  String _name = '';
  bool _saving = false;
  String? _error;

  String get _businessId => widget.business.businessId;

  /// Mirrors the server's check in `staff.ts` so a typo is caught before a
  /// round trip — staff sign in with Google, so a non-gmail address would
  /// create an account that can never actually be signed into.
  bool get _emailValid => RegExp(r'^[^@\s]+@(gmail\.com|googlemail\.com)$').hasMatch(_email.trim().toLowerCase());

  Future<void> _add() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminRepositoryProvider).createStaff(
            _businessId,
            email: _email.trim(),
            displayName: _name.trim().isEmpty ? null : _name.trim(),
          );
      if (!mounted) return;
      setState(() {
        _email = '';
        _name = '';
      });
      ref.invalidate(adminStaffProvider(_businessId));
    } on AdminFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(String uid, String label) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'remove $label?',
      body: 'they lose access immediately and are signed out on every device. their past transactions stay in the ledger.',
      confirmLabel: 'remove',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed) return;
    try {
      await ref.read(adminRepositoryProvider).removeStaff(_businessId, uid);
      ref.invalidate(adminStaffProvider(_businessId));
    } on AdminFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(adminStaffProvider(_businessId));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('staff', style: AppTypography.overline),
            const SizedBox(height: 6),
            Text(widget.business.displayName, style: AppTypography.h2),
            const SizedBox(height: 6),
            Text(
              'staff sign in with google only. what they can do is set by the owner in their own settings screen.',
              style: AppTypography.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),

            staff.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('could not load staff: $e', style: AppTypography.sm.copyWith(color: AppColors.loss)),
              data: (rows) => rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('no staff accounts yet.', style: AppTypography.sm),
                    )
                  : Column(
                      children: [
                        for (final s in rows)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                      Text(
                                        s.label,
                                        style: AppTypography.sm.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(s.email, style: AppTypography.xs2),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'remove',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _remove(s.uid, s.label),
                                  icon: const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 16),

            Text('add a staff account', style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            AppInput(
              label: 'gmail address',
              placeholder: 'name@gmail.com',
              value: _email,
              onChanged: (v) => setState(() {
                _email = v;
                _error = null;
              }),
              error: (_email.isNotEmpty && !_emailValid) ? 'must be a gmail address' : null,
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'name (optional)',
              placeholder: 'shown on their transactions',
              value: _name,
              onChanged: (v) => setState(() => _name = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppTypography.sm.copyWith(color: AppColors.loss)),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'add staff',
                    loading: _saving,
                    onPressed: _emailValid ? _add : null,
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(
                  label: 'done',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
