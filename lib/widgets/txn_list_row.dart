import 'package:flutter/material.dart';
import '../models/loyalty_transaction.dart';
import '../utils/formatters.dart';
import 'list_row.dart';

/// Recent-activity row (dashboard, correction feed) — title is the masked
/// phone, subtitle is "earn · ₹450 · today · 2:14 pm".
AppListRow feedTxnRow(LoyaltyTransaction t, {VoidCallback? onTap}) {
  final isEarn = t.isEarn;
  final reversed = t.isReversed;
  final typeLabel = isEarn ? 'earn' : 'redeem';
  final sub = '$typeLabel${isEarn && t.amount != null ? ' · ${formatInr(t.amount!)}' : ''} · ${relativeTimeLabel(t.createdAt)}';

  return AppListRow(
    title: maskPhone(t.phone),
    subtitle: sub,
    amount: '${isEarn ? '+' : '−'}${t.points} pts',
    amountTone: reversed ? AmountTone.none : (isEarn ? AmountTone.gain : AmountTone.loss),
    meta: reversed ? 'reversed' : null,
    avatarName: isEarn ? 'E' : 'R',
    avatarTone: isEarn ? AvatarTone.mint : AvatarTone.ink,
    onTap: onTap,
  );
}

/// Customer-history row (redeem screen's "visit history") — title is the
/// transaction type since the phone is already known from context.
AppListRow customerHistoryTxnRow(LoyaltyTransaction t) {
  final isEarn = t.isEarn;
  final reversed = t.isReversed;
  final sub = '${isEarn && t.amount != null ? formatInr(t.amount!) : 'redeem'} · ${relativeTimeLabel(t.createdAt)}';

  return AppListRow(
    title: isEarn ? 'earn' : 'redeem',
    subtitle: sub,
    amount: '${isEarn ? '+' : '−'}${t.points} pts',
    amountTone: reversed ? AmountTone.none : (isEarn ? AmountTone.gain : AmountTone.loss),
    meta: reversed ? 'reversed' : null,
    avatarName: isEarn ? 'E' : 'R',
    avatarTone: isEarn ? AvatarTone.mint : AvatarTone.ink,
  );
}
