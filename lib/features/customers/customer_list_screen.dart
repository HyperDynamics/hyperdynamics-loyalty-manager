import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../providers/business_providers.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/ledger_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/customer_export.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_segmented_control.dart';
import '../../widgets/nudge_sheet.dart';

final _pointsFormat = NumberFormat.decimalPattern('en_IN');

String buildPendingPointsMessage(Customer customer, String businessName) =>
    'Hi ${customer.name}, you have ${_pointsFormat.format(customer.balance)} loyalty points '
    'pending at $businessName. Redeem them on your next visit!';

/// Customer list — sortable by points balance, with a tap-through to a
/// WhatsApp nudge for a customer's pending points.
class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _sort = 'desc';
  bool _exporting = false;

  void _onRowTap(Customer customer) {
    final whatsappEnabled = ref.read(currentBusinessProvider).value?.whatsappEnabled ?? false;
    if (!whatsappEnabled) {
      ref.read(toastProvider.notifier).show("whatsapp nudges aren't enabled for your plan — contact us to enable it.", ToastTone.info);
      return;
    }
    showAppNudgeDialog(context, customer: customer, title: 'whatsapp reminder', buildMessage: buildPendingPointsMessage);
  }

  Future<void> _export(List<Customer> customers, {required bool asPdf}) async {
    final business = ref.read(currentBusinessProvider).value;
    if (business?.exportEnabled != true) {
      ref.read(toastProvider.notifier).show("export isn't enabled for your plan — contact us to enable it.", ToastTone.info);
      return;
    }
    final businessName = business?.displayName ?? 'business';
    setState(() => _exporting = true);
    try {
      await ref.read(busyProvider.notifier).run(
            asPdf ? 'preparing pdf…' : 'preparing csv…',
            () => asPdf ? exportCustomersPdf(customers, businessName: businessName) : exportCustomersCsv(customers, businessName: businessName),
          );
      if (mounted) ref.read(toastProvider.notifier).show('export ready.', ToastTone.success);
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('could not export. please try again.', ToastTone.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider(_sort == 'desc')).value ?? const [];
    final exportEnabled = ref.watch(currentBusinessProvider).value?.exportEnabled ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('customers', style: AppTypography.overline),
        const SizedBox(height: 6),
        Text('customer list', style: AppTypography.h1),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppSegmentedControl(
                options: const [
                  SegmentedOption('desc', 'high → low'),
                  SegmentedOption('asc', 'low → high'),
                ],
                value: _sort,
                onChanged: (v) => setState(() => _sort = v),
              ),
            ),
            const SizedBox(width: 10),
            AppButton(
              label: 'csv',
              variant: exportEnabled ? AppButtonVariant.outline : AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: _exporting ? null : () => _export(customers, asPdf: false),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'pdf',
              variant: exportEnabled ? AppButtonVariant.outline : AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: _exporting ? null : () => _export(customers, asPdf: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: 12,
          child: customers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('no customers yet.', style: AppTypography.sm)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _CustomerRow(
                    customer: customers[i],
                    onTap: () => _onRowTap(customers[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer, required this.onTap});
  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceInput,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text(maskPhone(customer.phone), style: AppTypography.xs2),
                  ],
                ),
              ),
              Text(
                '${_pointsFormat.format(customer.balance)} pts',
                style: AppTypography.tabular(AppTypography.sm).copyWith(fontWeight: FontWeight.w800, color: AppColors.mint400),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

