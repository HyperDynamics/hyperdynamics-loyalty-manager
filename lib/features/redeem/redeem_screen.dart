import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ledger_repository.dart';
import '../../providers/business_providers.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/ledger_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/coin.dart';
import '../../widgets/txn_list_row.dart';
import '../../widgets/actor_chip.dart';

/// F. Redeem Screen — customer lookup, balance, optional OTP verification,
/// redemption.
class RedeemScreen extends ConsumerStatefulWidget {
  const RedeemScreen({super.key});

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

enum _LookupState { idle, found, notFound }

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  String _phoneInput = '';
  String _lookedUpPhone = '';
  _LookupState _lookupState = _LookupState.idle;

  String _redeemAmount = '';
  bool _otpSent = false;
  String _otpValue = '';
  bool _otpFailed = false;
  bool _submitting = false;
  bool _lookingUp = false;
  bool _sendingOtp = false;

  Future<void> _lookup() async {
    final phone = digitsOnly(_phoneInput);
    setState(() => _lookingUp = true);
    try {
      final customer = await ref.read(ledgerRepositoryProvider).lookupCustomer(
            ref.read(currentBusinessProvider).value?.id ?? '',
            phone,
          );
      if (!mounted) return;
      setState(() {
        _lookedUpPhone = phone;
        _lookupState = customer != null ? _LookupState.found : _LookupState.notFound;
        _redeemAmount = '';
        _otpSent = false;
        _otpValue = '';
        _otpFailed = false;
      });
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _sendingOtp = true);
    try {
      await ref.read(ledgerRepositoryProvider).sendOtp(phone: _lookedUpPhone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _otpValue = '';
        _otpFailed = false;
      });
      ref.read(toastProvider.notifier).show('otp sent to ${maskPhone(_lookedUpPhone)}', ToastTone.info);
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not send otp. please try again.', ToastTone.error);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _doRedeem({bool override = false}) async {
    final points = int.tryParse(_redeemAmount) ?? 0;
    setState(() => _submitting = true);
    try {
      final newBalance = await ref.read(ledgerRepositoryProvider).redeemPoints(
            phone: _lookedUpPhone,
            points: points,
            otpCode: _otpValue.isEmpty ? null : _otpValue,
            override: override,
          );
      if (!mounted) return;
      setState(() {
        _redeemAmount = '';
        _otpSent = false;
        _otpValue = '';
        _otpFailed = false;
      });
      ref.read(toastProvider.notifier).show('$points points redeemed. new balance: $newBalance', ToastTone.success);
    } on LedgerFailure catch (e) {
      if (!mounted) return;
      if (e.message.contains("otp didn't verify") || e.message.contains('already used')) {
        setState(() => _otpFailed = true);
        ref.read(toastProvider.notifier).show(e.message, ToastTone.error);
      } else {
        ref.read(toastProvider.notifier).show(e.message, ToastTone.error);
      }
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('network error — please try again.', ToastTone.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider).value;
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
    final phoneDigits = digitsOnly(_phoneInput);
    final lookupDisabled = phoneDigits.length != 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('redeem', style: AppTypography.overline),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text('redeem points', style: AppTypography.h1)),
            const SizedBox(width: 12),
            const ActorChip(),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'customer phone number',
                      placeholder: '10-digit mobile',
                      value: _phoneInput,
                      numeric: true,
                      maxLength: 10,
                      onChanged: (v) => setState(() {
                        final d = digitsOnly(v);
                        _phoneInput = d.length > 10 ? d.substring(0, 10) : d;
                      }),
                      onSubmitted: lookupDisabled ? null : _lookup,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'look up',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.lg,
                    loading: _lookingUp,
                    onPressed: lookupDisabled ? null : _lookup,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('try any 10-digit number · unknown numbers show the empty state', style: AppTypography.xs2),
            ],
          ),
        ),
        if (_lookupState == _LookupState.notFound) ...[
          const SizedBox(height: 20),
          AppCard(
            variant: AppCardVariant.outline,
            padding: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded, size: 30, color: AppColors.textTertiary),
                const SizedBox(height: 8),
                Text('no customer found', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 6),
                Text(
                  'no account exists for ${maskPhone(_phoneInput)}. check the number, or credit a bill first to enrol them.',
                  style: AppTypography.sm,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        if (_lookupState == _LookupState.found) ...[
          const SizedBox(height: 20),
          _FoundSection(
            wide: wide,
            phone: _lookedUpPhone,
            otpEnabledForBusiness: business?.otpEnabled ?? false,
            redeemAmount: _redeemAmount,
            onRedeemAmountChanged: (v) => setState(() {
              final d = digitsOnly(v);
              _redeemAmount = d.length > 6 ? d.substring(0, 6) : d;
            }),
            otpSent: _otpSent,
            otpValue: _otpValue,
            onOtpChanged: (v) => setState(() {
              final d = digitsOnly(v);
              _otpValue = d.length > 4 ? d.substring(0, 4) : d;
              _otpFailed = false;
            }),
            otpFailed: _otpFailed,
            sendingOtp: _sendingOtp,
            onSendOtp: _sendOtp,
            onForceApprove: () => _doRedeem(override: true),
            submitting: _submitting,
            onConfirm: () => _doRedeem(),
          ),
        ],
      ],
    );
  }
}

class _FoundSection extends ConsumerWidget {
  const _FoundSection({
    required this.wide,
    required this.phone,
    required this.otpEnabledForBusiness,
    required this.redeemAmount,
    required this.onRedeemAmountChanged,
    required this.otpSent,
    required this.otpValue,
    required this.onOtpChanged,
    required this.otpFailed,
    required this.sendingOtp,
    required this.onSendOtp,
    required this.onForceApprove,
    required this.submitting,
    required this.onConfirm,
  });

  final bool wide;
  final String phone;
  final bool otpEnabledForBusiness;
  final String redeemAmount;
  final ValueChanged<String> onRedeemAmountChanged;
  final bool otpSent;
  final String otpValue;
  final ValueChanged<String> onOtpChanged;
  final bool otpFailed;
  final bool sendingOtp;
  final VoidCallback onSendOtp;
  final VoidCallback onForceApprove;
  final bool submitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerWatchProvider(phone)).value;
    final history = ref.watch(customerHistoryProvider(phone)).value ?? const [];
    final balance = customer?.balance ?? 0;

    final rn = int.tryParse(redeemAmount) ?? 0;
    String? redeemError;
    if (redeemAmount.isNotEmpty) {
      if (rn <= 0) {
        redeemError = 'enter a number greater than 0';
      } else if (rn > balance) {
        redeemError = 'exceeds available balance of $balance pts';
      }
    }
    final redeemAmtValid = rn > 0 && rn <= balance;
    final showOtpRow = otpEnabledForBusiness;
    final otpReady = !showOtpRow || (otpSent && otpValue.length == 4);
    final redeemDisabled = !(redeemAmtValid && otpReady) || submitting;
    final confirmLabel = showOtpRow ? 'verify & redeem' : 'redeem';

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          variant: AppCardVariant.elevated,
          padding: 26,
          glow: true,
          child: Row(
            children: [
              const Coin(symbol: '★', tone: CoinTone.gold, size: 64),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${customer?.name ?? 'customer'} · ${maskPhone(phone)}',
                      style: AppTypography.sm.copyWith(fontWeight: FontWeight.w600)),
                  Text('$balance pts', style: AppTypography.figureLg),
                  Text('available balance', style: AppTypography.xs2),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInput(
                label: 'points to redeem',
                placeholder: '0',
                prefixText: '★',
                value: redeemAmount,
                numeric: true,
                onChanged: onRedeemAmountChanged,
                error: redeemError,
              ),
              if (showOtpRow) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('otp verification required',
                              style: AppTypography.xs.copyWith(color: AppColors.gold400, fontSize: 13)),
                          if (!otpSent)
                            AppButton(
                              label: 'send otp',
                              variant: AppButtonVariant.outline,
                              size: AppButtonSize.sm,
                              loading: sendingOtp,
                              onPressed: redeemAmtValid ? onSendOtp : null,
                            ),
                        ],
                      ),
                      if (otpSent) ...[
                        const SizedBox(height: 12),
                        AppInput(
                          label: 'enter otp sent to customer',
                          placeholder: '4-digit code',
                          value: otpValue,
                          numeric: true,
                          maxLength: 4,
                          onChanged: onOtpChanged,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('demo flow · ', style: AppTypography.xs2),
                            GestureDetector(
                              onTap: onSendOtp,
                              child: Text('resend', style: AppTypography.xs2.copyWith(color: AppColors.textLink)),
                            ),
                          ],
                        ),
                        if (otpFailed) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.warnDim,
                              border: Border.all(color: AppColors.warn),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "otp didn't verify. if the customer isn't receiving it, you can override — this is logged.",
                                  style: AppTypography.sm.copyWith(color: const Color(0xFFFFD89A), fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                AppButton(
                                  label: 'force approve — logs as override',
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  block: true,
                                  onPressed: onForceApprove,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppButton(
                label: confirmLabel,
                block: true,
                size: AppButtonSize.lg,
                loading: submitting,
                onPressed: redeemDisabled ? null : onConfirm,
              ),
            ],
          ),
        ),
      ],
    );

    final rightColumn = AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text('visit history', style: AppTypography.xs.copyWith(letterSpacing: 1.4)),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('no visits recorded yet.', style: AppTypography.sm)),
            )
          else
            for (final t in history) customerHistoryTxnRow(t),
        ],
      ),
    );

    if (!wide) {
      return Column(children: [leftColumn, const SizedBox(height: 20), rightColumn]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: leftColumn),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: rightColumn),
      ],
    );
  }
}
