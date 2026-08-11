import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/business.dart';
import '../../providers/business_providers.dart';
import '../../providers/ledger_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_segmented_control.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/txn_list_row.dart';

/// D. Admin Dashboard (Home).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider).value;
    final stats = ref.watch(businessStatsProvider).value;
    final recent = ref.watch(recentTransactionsProvider).value ?? const [];
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
    final todayLabel = 'today · ${DateFormat('d MMM').format(DateTime.now()).toLowerCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('dashboard', style: AppTypography.overline),
                  const SizedBox(height: 6),
                  Text(business?.displayName ?? '', style: AppTypography.h1),
                ],
              ),
            ),
            Text(todayLabel, style: AppTypography.xs2),
          ],
        ),
        if (business != null) _RenewalBanner(business: business),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: wide ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: wide ? 1.6 : 3.2,
          children: [
            StatTile(label: 'earns today', value: '${stats?.todayEarnCount ?? 0}', accent: true),
            StatTile(label: 'redeems today', value: '${stats?.todayRedeemCount ?? 0}'),
            StatTile(label: 'points outstanding', value: NumberFormat.decimalPattern('en_IN').format(stats?.pointsOutstanding ?? 0)),
          ],
        ),
        const SizedBox(height: 14),
        _ActionRow(wide: wide, cards: [
          _ActionCard(icon: Icons.add_circle_outline_rounded, title: 'credit points', subtitle: 'log a bill & earn', onTap: () => context.go('/app/earn')),
          _ActionCard(icon: Icons.star_outline_rounded, title: 'redeem points', subtitle: 'look up & spend', onTap: () => context.go('/app/redeem')),
          _ActionCard(icon: Icons.history_rounded, title: 'fix a mistake', subtitle: 'reverse a txn', onTap: () => context.go('/app/correction')),
        ]),
        const SizedBox(height: 24),
        const _SalesSummarySection(),
        const SizedBox(height: 24),
        AppCard(
          padding: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text('recent activity', style: AppTypography.xs.copyWith(letterSpacing: 1.4)),
              ),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('no activity yet.', style: AppTypography.sm)),
                )
              else
                for (final t in recent) feedTxnRow(t),
            ],
          ),
        ),
      ],
    );
  }
}

/// Non-blocking heads-up once renewal is close, so it isn't a surprise when
/// the full-screen lockout (`SubscriptionLapsedScreen`) kicks in.
class _RenewalBanner extends StatelessWidget {
  const _RenewalBanner({required this.business});
  final Business business;

  @override
  Widget build(BuildContext context) {
    final renewsAt = business.subscriptionRenewsAt;
    // A lapsed subscription never reaches this screen at all — the router
    // redirects to SubscriptionLapsedScreen first — so this banner only
    // ever needs to cover the "coming up soon" case.
    if (renewsAt == null) return const SizedBox.shrink();
    final daysLeft = renewsAt.difference(DateTime.now()).inDays;
    if (daysLeft > 14) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warnDim,
          border: Border.all(color: AppColors.warn),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'your ₹999/year subscription renews in $daysLeft day${daysLeft == 1 ? '' : 's'} (${DateFormat('d MMM yyyy').format(renewsAt)}).',
          style: AppTypography.sm.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Start-of-day boundaries for a preset, end exclusive so "today" is
/// inclusive of everything posted so far.
DateRange _presetRange(String preset, DateTime? customStart, DateTime? customEnd) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));

  return switch (preset) {
    'week' => (start: todayStart.subtract(Duration(days: now.weekday - 1)), end: tomorrowStart),
    'month' => (start: DateTime(now.year, now.month), end: tomorrowStart),
    'custom' => (
        start: customStart ?? todayStart,
        end: (customEnd ?? todayStart).add(const Duration(days: 1)),
      ),
    _ => (start: todayStart, end: tomorrowStart),
  };
}

class _SalesSummarySection extends ConsumerStatefulWidget {
  const _SalesSummarySection();

  @override
  ConsumerState<_SalesSummarySection> createState() => _SalesSummarySectionState();
}

class _SalesSummarySectionState extends ConsumerState<_SalesSummarySection> {
  String _preset = 'today';
  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: (_customStart != null && _customEnd != null)
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (picked == null) return;
    setState(() {
      _preset = 'custom';
      _customStart = picked.start;
      _customEnd = picked.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
    final range = _presetRange(_preset, _customStart, _customEnd);
    final summary = ref.watch(salesSummaryProvider(range)).value;

    return AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text('sales', style: AppTypography.xs.copyWith(letterSpacing: 1.4)),
          ),
          Row(
            children: [
              Expanded(
                child: AppSegmentedControl(
                  options: const [
                    SegmentedOption('today', 'today'),
                    SegmentedOption('week', 'this week'),
                    SegmentedOption('month', 'this month'),
                  ],
                  value: _preset == 'custom' ? '' : _preset,
                  onChanged: (v) => setState(() {
                    _preset = v;
                    _customStart = null;
                    _customEnd = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: _preset == 'custom' ? 'custom range' : 'custom…',
                variant: _preset == 'custom' ? AppButtonVariant.primary : AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: _pickCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: wide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: wide ? 1.5 : 1.6,
            children: [
              StatTile(label: 'total sales', value: formatInr(summary?.totalSales ?? 0), accent: true),
              StatTile(label: 'transactions', value: '${summary?.earnCount ?? 0}'),
              StatTile(label: 'points issued', value: NumberFormat.decimalPattern('en_IN').format(summary?.pointsIssued ?? 0)),
              StatTile(label: 'points redeemed', value: NumberFormat.decimalPattern('en_IN').format(summary?.pointsRedeemed ?? 0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.wide, required this.cards});
  final bool wide;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          cards[i],
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      interactive: true,
      padding: 22,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.xs2),
        ],
      ),
    );
  }
}
