import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/business_providers.dart';
import '../../providers/ledger_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
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
