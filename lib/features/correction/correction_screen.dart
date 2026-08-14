import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ledger_repository.dart';
import '../../models/loyalty_transaction.dart';
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
import '../../widgets/confirm_dialog.dart';

/// G. Correction Tool Screen.
class CorrectionScreen extends ConsumerStatefulWidget {
  const CorrectionScreen({super.key, this.initialFilter});

  final String? initialFilter;

  @override
  ConsumerState<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends ConsumerState<CorrectionScreen> {
  late String _filter = widget.initialFilter ?? '';
  String? _selectedId;
  bool _reversing = false;

  Future<void> _reverse(LoyaltyTransaction txn) async {
    final businessId = ref.read(currentBusinessProvider).value?.id ?? '';
    final customer = await ref.read(ledgerRepositoryProvider).lookupCustomer(businessId, txn.phone);
    if (!mounted) return;

    final effect = txn.isEarn ? '−${txn.points} pts' : '+${txn.points} pts';
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'reverse ${txn.isEarn ? 'earn' : 'redeem'}?',
      body: "this will change ${customer?.name ?? 'the customer'}'s balance by $effect and cannot be undone.",
      confirmLabel: 'reverse it',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed || !mounted) return;

    setState(() => _reversing = true);
    try {
      await ref.read(ledgerRepositoryProvider).reverseTransaction(txn.id);
      if (mounted) ref.read(toastProvider.notifier).show('transaction reversed. balance updated.', ToastTone.success);
    } on LedgerFailure catch (e) {
      if (mounted) ref.read(toastProvider.notifier).show(e.message, ToastTone.error);
    } finally {
      if (mounted) setState(() => _reversing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
    final feed = ref.watch(correctionFeedProvider(_filter)).value ?? const [];
    final selected = _selectedId == null ? null : feed.where((t) => t.id == _selectedId).firstOrNull;

    final list = AppCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInput(
            placeholder: 'filter by phone number',
            prefixText: '🔍',
            value: _filter,
            numeric: true,
            onChanged: (v) => setState(() => _filter = digitsOnly(v)),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: feed.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('no transactions match.', style: AppTypography.sm)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: feed.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _CorrectionRow(
                      txn: feed[i],
                      selected: feed[i].id == _selectedId,
                      onTap: () => setState(() => _selectedId = feed[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );

    final detail = AppCard(
      variant: AppCardVariant.elevated,
      padding: 26,
      child: selected == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.restore_rounded, size: 30, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text('select a transaction', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text('pick a row to view its full record and reverse it.', style: AppTypography.sm, textAlign: TextAlign.center),
                ],
              ),
            )
          : _DetailPanel(txn: selected, reversing: _reversing, onReverse: () => _reverse(selected)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('history & correction', style: AppTypography.overline.copyWith(color: AppColors.warn)),
        const SizedBox(height: 6),
        Text('fix a transaction', style: AppTypography.h1),
        const SizedBox(height: 24),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: list),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: detail),
            ],
          )
        else
          Column(children: [list, const SizedBox(height: 20), detail]),
      ],
    );
  }
}

class _CorrectionRow extends StatelessWidget {
  const _CorrectionRow({required this.txn, required this.selected, required this.onTap});
  final LoyaltyTransaction txn;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEarn = txn.isEarn;
    final reversed = txn.isReversed;
    return Material(
      color: selected ? AppColors.surfaceHover : AppColors.surfaceInput,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? AppColors.mint400 : AppColors.borderSubtle, width: selected ? 1.5 : 1),
          ),
          child: Opacity(
            opacity: reversed ? 0.72 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isEarn ? AppColors.gainDim : AppColors.ink400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isEarn ? Icons.add : Icons.star, size: 16,
                          color: isEarn ? AppColors.mint400 : AppColors.gold400),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${isEarn ? 'earn' : 'redeem'} · ${maskPhone(txn.phone)}',
                            style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(relativeTimeLabel(txn.createdAt), style: AppTypography.xs2),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isEarn ? '+' : '−'}${txn.points} pts',
                      style: AppTypography.tabular(AppTypography.sm).copyWith(
                        fontWeight: FontWeight.w800,
                        color: reversed ? AppColors.textDisabled : (isEarn ? AppColors.gain : AppColors.loss),
                      ),
                    ),
                    Text(reversed ? 'reversed' : 'posted', style: AppTypography.xs2.copyWith(
                      fontSize: 10, color: reversed ? AppColors.loss : AppColors.textTertiary,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.txn, required this.reversing, required this.onReverse});
  final LoyaltyTransaction txn;
  final bool reversing;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final isEarn = txn.isEarn;
    final reversed = txn.isReversed;

    Widget row(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.sm),
              Text(value, style: AppTypography.tabular(AppTypography.body).copyWith(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('transaction detail', style: AppTypography.xs.copyWith(letterSpacing: 1.4)),
            Text(reversed ? 'reversed' : 'posted', style: AppTypography.xs2.copyWith(
              color: reversed ? AppColors.loss : AppColors.mint400, fontSize: 11,
            )),
          ],
        ),
        const SizedBox(height: 16),
        row('type', isEarn ? 'earn (points credited)' : 'redeem (points spent)'),
        row('phone', maskPhone(txn.phone)),
        row(isEarn ? 'bill amount' : 'redeemed', isEarn ? formatInr(txn.amount ?? 0) : '${txn.points} pts'),
        if (isEarn) row('bill number', txn.billNumber?.isNotEmpty == true ? txn.billNumber! : '—'),
        row(
          'points',
          '${isEarn ? '+' : '−'}${txn.points}${txn.manualPoints ? ' (manual)' : ''}',
          color: isEarn ? AppColors.gain : AppColors.loss,
        ),
        row('timestamp', relativeTimeLabel(txn.createdAt)),
        // Absent on anything posted before staff roles shipped — omit the line
        // entirely rather than showing "—", which would imply nobody posted it.
        if (txn.createdByName != null)
          row('posted by', '${txn.createdByName}${txn.isStaffEntry ? ' (staff)' : ''}'),
        if (reversed && txn.reversedByName != null) row('reversed by', txn.reversedByName!),
        row('txn id', txn.id),
        const SizedBox(height: 12),
        const Divider(color: AppColors.borderSubtle, height: 1),
        const SizedBox(height: 16),
        if (!reversed) ...[
          Text(
            "reversing this will adjust the customer's balance by ${isEarn ? '−' : '+'}${txn.points} pts. this can't be undone.",
            style: AppTypography.sm.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'reverse this transaction',
            variant: AppButtonVariant.danger,
            block: true,
            loading: reversing,
            onPressed: onReverse,
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lossDim,
              border: Border.all(color: AppColors.loss),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text('already reversed — no further action available.',
                style: AppTypography.sm.copyWith(color: const Color(0xFFFFB9C4), fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
