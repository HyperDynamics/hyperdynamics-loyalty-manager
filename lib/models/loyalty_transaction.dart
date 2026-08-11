import 'package:cloud_firestore/cloud_firestore.dart';

enum TxnType { earn, redeem }

enum TxnStatus { ok, reversed }

class LoyaltyTransaction {
  const LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.phone,
    this.amount,
    required this.points,
    required this.status,
    required this.otpOverride,
    required this.createdAt,
    this.billNumber,
  });

  final String id;
  final TxnType type;
  final String phone;
  final num? amount;
  final int points;
  final TxnStatus status;
  final bool otpOverride;
  final DateTime createdAt;
  final String? billNumber;

  bool get isEarn => type == TxnType.earn;
  bool get isReversed => status == TxnStatus.reversed;

  /// Signed point delta this transaction applied to the customer's balance
  /// when it posted (earn = +points, redeem = -points).
  int get pointDelta => isEarn ? points : -points;

  factory LoyaltyTransaction.fromMap(String id, Map<String, dynamic> map) => LoyaltyTransaction(
        id: id,
        type: map['type'] == 'redeem' ? TxnType.redeem : TxnType.earn,
        phone: (map['phone'] as String?) ?? '',
        amount: map['amount'] as num?,
        points: (map['points'] as num?)?.toInt() ?? 0,
        status: map['status'] == 'reversed' ? TxnStatus.reversed : TxnStatus.ok,
        otpOverride: (map['otpOverride'] as bool?) ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        billNumber: map['billNumber'] as String?,
      );
}
