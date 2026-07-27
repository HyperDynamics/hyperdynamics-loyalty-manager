import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/models/loyalty_transaction.dart';

void main() {
  group('LoyaltyTransaction.fromMap', () {
    test('parses an earn transaction', () {
      final txn = LoyaltyTransaction.fromMap('TX1', {
        'type': 'earn',
        'phone': '9876543210',
        'amount': 450,
        'points': 45,
        'status': 'ok',
        'otpOverride': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 27, 14, 14)),
      });

      expect(txn.isEarn, isTrue);
      expect(txn.isReversed, isFalse);
      // Reversal math (mirrored in functions/src/correction.ts): reversing
      // an earn subtracts its points, i.e. delta is the *negative* of what
      // posting it originally added.
      expect(txn.pointDelta, 45);
    });

    test('parses a redeem transaction', () {
      final txn = LoyaltyTransaction.fromMap('TX2', {
        'type': 'redeem',
        'phone': '9911002200',
        'points': 20,
        'status': 'ok',
        'otpOverride': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 27, 13, 2)),
      });

      expect(txn.isEarn, isFalse);
      expect(txn.otpOverride, isTrue);
      // Reversing a redeem should give the points back.
      expect(txn.pointDelta, -20);
      expect(-txn.pointDelta, 20);
    });

    test('defaults status to ok and reads reversed status explicitly', () {
      final posted = LoyaltyTransaction.fromMap('TX3', {
        'type': 'earn',
        'phone': '9800011122',
        'points': 8,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      expect(posted.isReversed, isFalse);

      final reversed = LoyaltyTransaction.fromMap('TX4', {
        'type': 'earn',
        'phone': '9800011122',
        'points': 8,
        'status': 'reversed',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      expect(reversed.isReversed, isTrue);
    });
  });
}
