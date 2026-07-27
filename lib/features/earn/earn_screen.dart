import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/ledger_repository.dart';
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
import '../../widgets/coin.dart';
import '../../widgets/list_row.dart';

class _SessionEntry {
  const _SessionEntry({required this.phone, required this.amount, required this.points});
  final String phone;
  final num amount;
  final int points;
}

/// E. Earn Screen.
class EarnScreen extends ConsumerStatefulWidget {
  const EarnScreen({super.key});

  @override
  ConsumerState<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends ConsumerState<EarnScreen> {
  String _phone = '';
  String _amount = '';
  bool _submitting = false;
  String? _networkError;
  final List<_SessionEntry> _sessionEntries = [];

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _networkError = null;
    });
    final phone = digitsOnly(_phone);
    final amount = num.tryParse(_amount) ?? 0;
    try {
      final result = await ref.read(ledgerRepositoryProvider).earnCredit(phone: phone, amount: amount);
      if (!mounted) return;
      setState(() {
        _amount = '';
        _sessionEntries.insert(0, _SessionEntry(phone: phone, amount: amount, points: result.points));
        if (_sessionEntries.length > 5) _sessionEntries.removeLast();
      });
      ref.read(toastProvider.notifier).show('${result.points} points credited to ${maskPhone(phone)}', ToastTone.success);
    } on LedgerFailure catch (e) {
      if (mounted) setState(() => _networkError = e.message);
    } catch (_) {
      if (mounted) setState(() => _networkError = 'network error — could not reach the server.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider).value;
    final ratio = business?.pointsRatio ?? 10;
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;

    final phoneDigits = digitsOnly(_phone);
    final phoneError = (phoneDigits.isNotEmpty && phoneDigits.length < 10) ? 'enter a 10-digit number' : null;
    final amountNum = num.tryParse(_amount) ?? 0;
    final preview = amountNum > 0 ? '${formatInr(amountNum)} → ${pointsForAmount(amountNum, ratio)} pts' : 'enter a bill amount';
    final valid = phoneDigits.length == 10 && amountNum > 0;

    final form = AppCard(
      padding: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInput(
            label: 'customer phone number',
            placeholder: '10-digit mobile',
            value: _phone,
            onChanged: (v) => setState(() {
              final d = digitsOnly(v);
              _phone = d.length > 10 ? d.substring(0, 10) : d;
              _networkError = null;
            }),
            error: phoneError,
            numeric: true,
            maxLength: 10,
          ),
          const SizedBox(height: 18),
          AppInput(
            label: 'bill amount',
            placeholder: '0',
            prefixText: '₹',
            value: _amount,
            onChanged: (v) => setState(() {
              final d = digitsOnly(v);
              _amount = d.substring(0, d.length > 7 ? 7 : d.length);
              _networkError = null;
            }),
            numeric: true,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                const Coin(symbol: '★', size: 40, glow: false),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('live preview', style: AppTypography.xs2.copyWith(letterSpacing: 1.2)),
                    Text(preview, style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.2,
                    )),
                  ],
                ),
              ],
            ),
          ),
          if (_networkError != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lossDim,
                border: Border.all(color: AppColors.loss),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_networkError!, style: AppTypography.sm.copyWith(color: const Color(0xFFFFB9C4), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  AppButton(label: 'retry', variant: AppButtonVariant.ghost, size: AppButtonSize.sm, onPressed: _submit),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: 'credit points',
            block: true,
            size: AppButtonSize.lg,
            loading: _submitting,
            onPressed: valid && !_submitting ? _submit : null,
          ),
          const SizedBox(height: 10),
          Text('ratio: ₹$ratio = 1 point · configurable in settings', style: AppTypography.xs2, textAlign: TextAlign.center),
        ],
      ),
    );

    final sessionList = AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text('this session', style: AppTypography.xs.copyWith(letterSpacing: 1.4)),
          ),
          if (_sessionEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('no points credited yet this session.', style: AppTypography.sm)),
            )
          else ...[
            for (final e in _sessionEntries)
              AppListRow(
                title: maskPhone(e.phone),
                subtitle: '${formatInr(e.amount)} · just now',
                amount: '+${e.points} pts',
                amountTone: AmountTone.gain,
                avatarName: 'E',
                avatarTone: AvatarTone.mint,
                onTap: () => context.go('/app/correction?filter=${e.phone}'),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('tap a row to correct it', style: AppTypography.xs2, textAlign: TextAlign.center),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('earn', style: AppTypography.overline),
        const SizedBox(height: 6),
        Text('credit points', style: AppTypography.h1),
        const SizedBox(height: 24),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              const SizedBox(width: 20),
              Expanded(child: sessionList),
            ],
          )
        else
          Column(children: [form, const SizedBox(height: 20), sessionList]),
      ],
    );
  }
}
