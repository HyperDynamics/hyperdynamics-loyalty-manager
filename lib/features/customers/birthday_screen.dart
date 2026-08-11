import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../providers/ledger_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/nudge_sheet.dart';

String buildBirthdayMessage(Customer customer, String businessName) =>
    'Happy birthday, ${customer.name}! 🎉 Wishing you a wonderful year ahead — from all of us at $businessName.';

/// Customers whose birthday (month + day, regardless of year) is today —
/// gated behind the `birthdayEnabled` add-on flag by the router/nav (see
/// `app_shell.dart`), so reaching this screen already implies it's on.
class BirthdayScreen extends ConsumerWidget {
  const BirthdayScreen({super.key});

  void _openNudgeSheet(BuildContext context, Customer customer) {
    showAppNudgeDialog(context, customer: customer, title: 'birthday wish', buildMessage: buildBirthdayMessage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(todaysBirthdaysProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('birthdays', style: AppTypography.overline),
        const SizedBox(height: 6),
        Text("today's birthdays", style: AppTypography.h1),
        const SizedBox(height: 24),
        AppCard(
          padding: 12,
          child: customers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('no birthdays today.', style: AppTypography.sm)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _BirthdayRow(
                    customer: customers[i],
                    onTap: () => _openNudgeSheet(context, customers[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.customer, required this.onTap});
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
              Row(
                children: [
                  const Text('🎂', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: AppTypography.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(maskPhone(customer.phone), style: AppTypography.xs2),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
