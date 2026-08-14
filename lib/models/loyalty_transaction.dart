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
    this.createdByName,
    this.createdByRole,
    this.manualPoints = false,
    this.reversedByName,
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

  /// Who posted this, stamped server-side at write time (`getActorLabel`) so
  /// the row can name them without a user lookup. Null on transactions written
  /// before staff roles shipped — render those without an attribution line
  /// rather than guessing.
  final String? createdByName;
  final String? createdByRole;

  /// True when the points were typed in rather than derived from the bill
  /// amount — only possible where the business has `manualPointsEnabled`.
  final bool manualPoints;

  final String? reversedByName;

  bool get isStaffEntry => createdByRole == 'staff';

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
        createdByName: (map['createdByName'] as String?)?.trim().isNotEmpty == true
            ? (map['createdByName'] as String).trim()
            : null,
        createdByRole: map['createdByRole'] as String?,
        manualPoints: (map['manualPoints'] as bool?) ?? false,
        reversedByName: (map['reversedByName'] as String?)?.trim().isNotEmpty == true
            ? (map['reversedByName'] as String).trim()
            : null,
      );
}
