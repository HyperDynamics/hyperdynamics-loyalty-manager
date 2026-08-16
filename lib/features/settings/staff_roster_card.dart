import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/staff_repository.dart';
import '../../models/business.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/staff_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/confirm_dialog.dart';

/// Owner-side staff roster — add/remove staff, capped at
/// [Business.maxStaffSeats]. Staff sign in with Google only, so [_email] must
/// be a gmail address; the callable rejects anything else. Separate from the
/// "staff permissions" card below it: this controls *who exists*, that
/// controls *what they can do*.
class StaffRosterCard extends ConsumerStatefulWidget {
  const StaffRosterCard({super.key, required this.business});
  final Business business;

  @override
  ConsumerState<StaffRosterCard> createState() => _StaffRosterCardState();
}

class _StaffRosterCardState extends ConsumerState<StaffRosterCard> {
  String _email = '';
  String _name = '';
  bool _adding = false;
  String? _error;

  bool get _emailValid => RegExp(r'^[^@\s]+@(gmail\.com|googlemail\.com)$').hasMatch(_email.trim().toLowerCase());

  Future<void> _add() async {
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await ref.read(staffRepositoryProvider).createStaff(
            email: _email.trim(),
            displayName: _name.trim().isEmpty ? null : _name.trim(),
          );
      if (!mounted) return;
      setState(() {
        _email = '';
        _name = '';
      });
      ref.read(toastProvider.notifier).show('staff account added.', ToastTone.success);
    } on StaffFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _adding = false);
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
      await ref.read(staffRepositoryProvider).removeStaff(uid);
      if (mounted) ref.read(toastProvider.notifier).show('staff account removed.', ToastTone.info);
    } on StaffFailure catch (e) {
      if (mounted) ref.read(toastProvider.notifier).show(e.message, ToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(businessStaffProvider).value ?? const [];
    final cap = widget.business.maxStaffSeats;
    final atCap = staff.length >= cap;

    return AppCard(
      padding: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('staff', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text('${staff.length} of $cap seats', style: AppTypography.xs2),
            ],
          ),
          const SizedBox(height: 4),
          Text('staff sign in with google only — what they can do is set below.', style: AppTypography.sm.copyWith(height: 1.5)),
          const SizedBox(height: 16),
          if (staff.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('no staff accounts yet.', style: AppTypography.sm),
            )
          else
            Column(
              children: [
                for (final s in staff)
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
                              Text(s.label, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),
          if (atCap)
            Text(
              "you've reached your limit of $cap staff account${cap == 1 ? '' : 's'} — remove one to add another, or contact us to raise the limit.",
              style: AppTypography.sm.copyWith(height: 1.5),
            )
          else ...[
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'add staff',
                size: AppButtonSize.sm,
                loading: _adding,
                onPressed: _emailValid ? _add : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
