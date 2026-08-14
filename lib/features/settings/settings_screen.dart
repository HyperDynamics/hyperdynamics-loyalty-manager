import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/auth_repository.dart';
import '../../models/business.dart';
import '../../providers/business_providers.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_segmented_control.dart';
import '../../widgets/app_toggle.dart';
import '../../widgets/confirm_dialog.dart';

/// H. Settings Screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _nameDraft;
  String? _ratioDraft;
  bool _savingProfile = false;
  bool _uploadingLogo = false;

  String _apiKey = '';
  String _apiSecret = '';
  bool _savingGateway = false;

  String _pwCur = '';
  String _pwNew = '';
  bool _savingPassword = false;

  /// Each of these writes a single field straight through — no local draft
  /// state, so the toggle reflects what's actually stored (the business doc
  /// stream re-renders this screen on success, and a failed write leaves the
  /// switch where it was rather than lying about a change that didn't land).
  Future<void> _updateOperations(
    Business business, {
    bool? billNumberRequired,
    bool? manualPointsEnabled,
    int? birthdayWindowDays,
  }) async {
    try {
      await ref.read(businessRepositoryProvider).updateOperations(
            business.id,
            billNumberRequired: billNumberRequired,
            manualPointsEnabled: manualPointsEnabled,
            birthdayWindowDays: birthdayWindowDays,
          );
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not save. please try again.', ToastTone.error);
    }
  }

  Future<void> _updateStaffPermissions(Business business, StaffPermissions next) async {
    try {
      await ref.read(businessRepositoryProvider).updateStaffPermissions(business.id, next);
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not save. please try again.', ToastTone.error);
    }
  }

  /// Add-on-gated rows are hidden rather than shown-disabled: granting staff
  /// access to a module the business hasn't bought would be a toggle that does
  /// nothing, which reads as a bug.
  List<Widget> _staffPermissionRows(Business business) {
    final p = business.staffPermissions;
    final rows = <({String title, String body, bool value, StaffPermissions Function(bool) apply})>[
      (
        title: 'earn points',
        body: 'credit points against a bill.',
        value: p.earn,
        apply: (v) => p.copyWith(earn: v),
      ),
      (
        title: 'redeem points',
        body: 'spend a customer’s balance.',
        value: p.redeem,
        apply: (v) => p.copyWith(redeem: v),
      ),
      (
        title: 'corrections',
        body: 'reverse a past transaction. leave off if only you should undo entries.',
        value: p.correction,
        apply: (v) => p.copyWith(correction: v),
      ),
      (
        title: 'customer list',
        body: 'browse customers and their balances.',
        value: p.customers,
        apply: (v) => p.copyWith(customers: v),
      ),
      if (business.birthdayEnabled)
        (
          title: 'birthdays',
          body: 'see upcoming birthdays and send wishes.',
          value: p.birthdays,
          apply: (v) => p.copyWith(birthdays: v),
        ),
      if (business.exportEnabled)
        (
          title: 'export',
          body: 'download the customer list as csv/pdf.',
          value: p.export,
          apply: (v) => p.copyWith(export: v),
        ),
      if (business.salesDashboardEnabled)
        (
          title: 'sales figures',
          body: 'see revenue totals on the dashboard.',
          value: p.sales,
          apply: (v) => p.copyWith(sales: v),
        ),
    ];

    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        out
          ..add(const SizedBox(height: 16))
          ..add(const Divider(color: AppColors.borderSubtle, height: 1))
          ..add(const SizedBox(height: 14));
      }
      final row = rows[i];
      out.add(_SettingRow(
        title: row.title,
        body: row.body,
        checked: row.value,
        onChanged: (v) => _updateStaffPermissions(business, row.apply(v)),
      ));
    }
    return out;
  }

  Future<void> _saveProfile(Business business) async {
    setState(() => _savingProfile = true);
    try {
      await ref.read(businessRepositoryProvider).updateProfile(
            business.id,
            displayName: _nameDraft,
            pointsRatio: _ratioDraft != null ? int.tryParse(_ratioDraft!) : null,
          );
      if (mounted) {
        ref.read(toastProvider.notifier).show('business profile saved.', ToastTone.success);
        setState(() {
          _nameDraft = null;
          _ratioDraft = null;
        });
      }
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not save. please try again.', ToastTone.error);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _uploadLogo(Business business) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() => _uploadingLogo = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final contentType = ext == 'svg' ? 'image/svg+xml' : (ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/png');
      final url = await ref.read(businessRepositoryProvider).uploadLogo(business.id, bytes, contentType: contentType);
      await ref.read(businessRepositoryProvider).updateProfile(business.id, logoUrl: url);
      if (mounted) ref.read(toastProvider.notifier).show('logo updated.', ToastTone.success);
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not upload logo. please try again.', ToastTone.error);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _toggleOtp(Business business, bool next) async {
    await ref.read(businessRepositoryProvider).setOtpEnabled(business.id, next);
    if (mounted) {
      ref.read(toastProvider.notifier).show(
            next ? 'otp verification enabled.' : 'otp verification disabled.',
            ToastTone.info,
          );
    }
  }

  Future<void> _setGateway(Business business, String value) async {
    await ref.read(businessRepositoryProvider).setGateway(business.id, value == 'byo' ? OtpGateway.byo : OtpGateway.managed);
  }

  Future<void> _saveGatewayCredentials() async {
    setState(() => _savingGateway = true);
    try {
      await ref.read(ledgerRepositoryProvider).saveOtpGatewayCredentials(apiKey: _apiKey, apiSecret: _apiSecret);
      if (mounted) {
        ref.read(toastProvider.notifier).show('gateway credentials saved.', ToastTone.success);
        setState(() {
          _apiKey = '';
          _apiSecret = '';
        });
      }
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not save credentials. please try again.', ToastTone.error);
    } finally {
      if (mounted) setState(() => _savingGateway = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() => _savingPassword = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(currentPassword: _pwCur, newPassword: _pwNew);
      if (mounted) {
        ref.read(toastProvider.notifier).show('password updated.', ToastTone.success);
        setState(() {
          _pwCur = '';
          _pwNew = '';
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) ref.read(toastProvider.notifier).show(e.message, ToastTone.error);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'log out?',
      body: "you'll need your business id and password to sign back in.",
      confirmLabel: 'log out',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed) return;
    await ref.read(authRepositoryProvider).logout();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider).value;
    if (business == null) return const SizedBox.shrink();

    final name = _nameDraft ?? business.displayName;
    final ratio = _ratioDraft ?? business.pointsRatio.toString();
    final ratioValue = int.tryParse(ratio);
    final ratioError = ratio.isEmpty
        ? 'enter a ratio'
        : (ratioValue == null || ratioValue < 1 ? 'must be at least ₹1' : null);
    final pwDisabled = !(_pwCur.isNotEmpty && _pwNew.length >= 4);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('settings', style: AppTypography.overline.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Text('business setup', style: AppTypography.h1),
          const SizedBox(height: 24),

          // Business profile
          AppCard(
            padding: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('business profile', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _uploadingLogo ? null : () => _uploadLogo(business),
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderStrong, style: BorderStyle.solid),
                          image: business.logoUrl != null
                              ? DecorationImage(image: NetworkImage(business.logoUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: business.logoUrl == null
                            ? (_uploadingLogo
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.arrow_upward_rounded, color: AppColors.textTertiary))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('logo', style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        GestureDetector(
                          onTap: _uploadingLogo ? null : () => _uploadLogo(business),
                          child: Text('upload image', style: AppTypography.xs.copyWith(color: AppColors.textLink)),
                        ),
                        Text('png, square', style: AppTypography.xs2),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppInput(label: 'business name', value: name, onChanged: (v) => setState(() => _nameDraft = v)),
                const SizedBox(height: 18),
                AppInput(
                  label: 'points ratio (₹ per 1 point)',
                  prefixText: '₹',
                  numeric: true,
                  value: ratio,
                  // Deliberately does NOT coerce an empty field back to '1'. It used
                  // to, which made the field impossible to retype: clearing it
                  // instantly refilled '1', so typing "50" left you with "150".
                  // Empty is a valid *in-progress* state; it's rejected at save
                  // time by `ratioError` instead.
                  onChanged: (v) => setState(() => _ratioDraft = digitsOnly(v)),
                  error: ratioError,
                  hint: ratioValue != null
                      ? '₹$ratioValue spent earns the customer 1 point'
                      : 'how many rupees of spend earn 1 point',
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'save profile',
                    loading: _savingProfile,
                    onPressed: ratioError == null ? () => _saveProfile(business) : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subscription
          if (business.subscriptionRenewsAt != null) ...[
            AppCard(
              padding: 26,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('subscription', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          business.subscriptionLapsed
                              ? 'lapsed on ${DateFormat('d MMM yyyy').format(business.subscriptionRenewsAt!)} — contact us to renew (₹999/year).'
                              : '₹999/year — renews ${DateFormat('d MMM yyyy').format(business.subscriptionRenewsAt!)}.',
                          style: AppTypography.sm.copyWith(height: 1.5, color: business.subscriptionLapsed ? AppColors.loss : null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Point-of-sale behaviour — what the Earn form asks for.
          AppCard(
            padding: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('earn screen', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 18),
                _SettingRow(
                  title: 'require a bill number',
                  body: business.billNumberRequired
                      ? 'staff must enter the bill/receipt number on every earn — ties each entry to a real receipt.'
                      : 'the bill number field is still shown, but can be left blank.',
                  checked: business.billNumberRequired,
                  onChanged: (v) => _updateOperations(business, billNumberRequired: v),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 14),
                _SettingRow(
                  title: 'allow manual points',
                  body: business.manualPointsEnabled
                      ? 'staff can override the calculated points on a bill — those entries are flagged as manual.'
                      : 'points are always calculated from the bill amount at the ratio above.',
                  checked: business.manualPointsEnabled,
                  onChanged: (v) => _updateOperations(business, manualPointsEnabled: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Birthday window — only meaningful when the add-on is on.
          if (business.birthdayEnabled) ...[
            AppCard(
              padding: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('birthday reminders', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    business.birthdayWindowDays <= 1
                        ? 'the birthdays screen shows customers whose birthday is today.'
                        : 'the birthdays screen shows customers whose birthday falls within the next ${business.birthdayWindowDays} days, so you can reach out ahead of time.',
                    style: AppTypography.sm.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('days ahead', style: AppTypography.sm.copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      _Stepper(
                        value: business.birthdayWindowDays,
                        min: 1,
                        max: 10,
                        onChanged: (v) => _updateOperations(business, birthdayWindowDays: v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // What staff accounts may do — one policy for every staff member on
          // this business. Re-checked server-side on every call.
          AppCard(
            padding: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('staff permissions', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'applies to every staff account on this business. staff are added by hyperdynamics — contact us to add or remove one. settings stay owner-only.',
                  style: AppTypography.sm.copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                ..._staffPermissionRows(business),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // OTP module
          AppCard(
            padding: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('otp verification', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            'require a one-time code before redemptions. ${business.otpEnabled ? 'add-on active — billed monthly.' : 'requires the paid otp add-on.'}',
                            style: AppTypography.sm.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    AppToggle(checked: business.otpEnabled, onChanged: (v) => _toggleOtp(business, v)),
                  ],
                ),
                if (business.otpEnabled) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 14),
                  Text('sms gateway', style: AppTypography.sm.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppSegmentedControl(
                    options: const [SegmentedOption('byo', 'bring your own'), SegmentedOption('managed', 'managed by us')],
                    value: business.gateway == OtpGateway.byo ? 'byo' : 'managed',
                    onChanged: (v) => _setGateway(business, v),
                  ),
                  const SizedBox(height: 16),
                  if (business.gateway == OtpGateway.byo)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppInput(label: 'api key', placeholder: 'your gateway api key', value: _apiKey, onChanged: (v) => setState(() => _apiKey = v)),
                        const SizedBox(height: 14),
                        AppInput(label: 'api secret', placeholder: '••••••••', obscureText: true, value: _apiSecret, onChanged: (v) => setState(() => _apiSecret = v)),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton(
                            label: 'save gateway credentials',
                            size: AppButtonSize.sm,
                            loading: _savingGateway,
                            onPressed: (_apiKey.isNotEmpty && _apiSecret.isNotEmpty) ? _saveGatewayCredentials : null,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInput,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Text(
                        'managed by hyperdynamics — sms billed at ₹0.18 / message on your monthly invoice. nothing to configure.',
                        style: AppTypography.sm.copyWith(height: 1.5),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Change password
          AppCard(
            padding: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('change password', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 18),
                AppInput(label: 'current password', obscureText: true, placeholder: '••••••••', value: _pwCur, onChanged: (v) => setState(() => _pwCur = v)),
                const SizedBox(height: 14),
                AppInput(label: 'new password', obscureText: true, placeholder: 'at least 4 characters', value: _pwNew, onChanged: (v) => setState(() => _pwNew = v)),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'update password',
                    variant: AppButtonVariant.ghost,
                    loading: _savingPassword,
                    onPressed: pwDisabled ? null : _changePassword,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(label: 'log out', variant: AppButtonVariant.outline, onPressed: _logout),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// A labelled description + switch, matching the layout the OTP card already
/// uses inline — extracted here because the operations and staff-permission
/// cards need the same shape a dozen times over.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.body,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String body;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(body, style: AppTypography.sm.copyWith(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        AppToggle(checked: checked, onChanged: onChanged),
      ],
    );
  }
}

/// Bounded −/+ number picker, same visual language as the operator console's
/// session-cap control.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged});

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}
