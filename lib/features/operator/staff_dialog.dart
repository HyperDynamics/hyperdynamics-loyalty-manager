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

/// Read-only staff view for one business, plus the seat-cap stepper. Staff
/// themselves are added/removed by the business owner, self-serve, in their
/// own Settings screen (`StaffRosterCard`) — this exists purely so you can see
/// who's on an account without asking, and adjust how many seats they get.
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
  late int _cap = widget.business.maxStaffSeats;
  bool _savingCap = false;
  String? _error;

  String get _businessId => widget.business.businessId;

  Future<void> _setCap(int next) async {
    final previous = _cap;
    setState(() {
      _cap = next;
      _savingCap = true;
      _error = null;
    });
    try {
      await ref.read(adminRepositoryProvider).updateFeatures(_businessId, maxStaffSeats: next);
      // The row this dialog was opened from is a snapshot; make sure the
      // console's list reflects the new cap once this closes.
      ref.invalidate(adminBusinessesProvider);
    } on AdminFailure catch (e) {
      if (mounted) setState(() => _cap = previous);
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _savingCap = false);
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
              'staff are added and removed by the business owner in their own settings screen. this view is read-only.',
              style: AppTypography.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Text('staff seats', style: AppTypography.sm.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                _Stepper(
                  value: _cap,
                  min: 0,
                  max: 10,
                  loading: _savingCap,
                  onChanged: _setCap,
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: AppTypography.sm.copyWith(color: AppColors.loss)),
            ],
            const SizedBox(height: 18),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 16),

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.label,
                                  style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                Text(s.email, style: AppTypography.xs2),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'done',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bounded −/+ number picker, matching the one in `settings_screen.dart`.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged, this.loading = false});

  final int value;
  final int min;
  final int max;
  final bool loading;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: (!loading && value > min) ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: (!loading && value < max) ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}
