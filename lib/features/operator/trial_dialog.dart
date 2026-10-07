import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';

/// Product cap: a trial may never run longer than two weeks. Mirrors
/// `MAX_TRIAL_DAYS` in `functions/src/trial.ts`, which is the real enforcement
/// — this only keeps the console from offering something the callable rejects.
const maxTrialDays = 14;
const defaultTrialDays = 14;

/// Asks how long a trial should run. Returns the chosen number of days, or
/// null if cancelled. Follows the same centered-dialog convention as
/// `showAppConfirmDialog`.
Future<int?> showTrialDialog(BuildContext context, {required String businessName}) {
  return showDialog<int>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (context) => _TrialDialog(businessName: businessName),
  );
}

class _TrialDialog extends StatefulWidget {
  const _TrialDialog({required this.businessName});
  final String businessName;

  @override
  State<_TrialDialog> createState() => _TrialDialogState();
}

class _TrialDialogState extends State<_TrialDialog> {
  int _days = defaultTrialDays;

  @override
  Widget build(BuildContext context) {
    final endsOn = DateTime.now().add(Duration(days: _days));
    return Dialog(
      backgroundColor: AppColors.surfaceElev,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('start trial for ${widget.businessName}', style: AppTypography.h3),
              const SizedBox(height: 12),
              Text(
                'activates the account immediately with every add-on switched on '
                '(birthdays, whatsapp, export). it locks itself the moment the trial '
                'ends — no action needed from you.',
                style: AppTypography.sm.copyWith(height: 1.55),
              ),
              const SizedBox(height: 20),
              Text('trial length', style: AppTypography.xs),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove_rounded,
                    onPressed: _days > 1 ? () => setState(() => _days -= 1) : null,
                  ),
                  SizedBox(
                    width: 86,
                    child: Text(
                      '$_days ${_days == 1 ? 'day' : 'days'}',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add_rounded,
                    // Hard stop at two weeks.
                    onPressed: _days < maxTrialDays ? () => setState(() => _days += 1) : null,
                  ),
                  const SizedBox(width: 12),
                  for (final preset in const [7, 14])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Preset(
                        days: preset,
                        selected: _days == preset,
                        onTap: () => setState(() => _days = preset),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'expires ${_fmt(endsOn)}  ·  max $maxTrialDays days',
                style: AppTypography.xs2.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'cancel',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'start trial',
                      onPressed: () => Navigator.of(context).pop(_days),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Icon(icon, size: 17, color: enabled ? AppColors.textPrimary : AppColors.textDisabled),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({required this.days, required this.selected, required this.onTap});
  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint400.withValues(alpha: 0.16) : AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: selected ? AppColors.mint400 : AppColors.borderSoft),
        ),
        child: Text(
          '${days}d',
          style: AppTypography.xs2.copyWith(
            color: selected ? AppColors.mint400 : AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
