import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/customer.dart';
import '../models/loyalty_transaction.dart';

class LedgerFailure implements Exception {
  const LedgerFailure(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

class BusinessStats {
  const BusinessStats({required this.todayEarnCount, required this.todayRedeemCount, required this.pointsOutstanding});
  final int todayEarnCount;
  final int todayRedeemCount;
  final int pointsOutstanding;

  factory BusinessStats.fromMap(Map<String, dynamic>? map) => BusinessStats(
        todayEarnCount: (map?['todayEarnCount'] as num?)?.toInt() ?? 0,
        todayRedeemCount: (map?['todayRedeemCount'] as num?)?.toInt() ?? 0,
        pointsOutstanding: (map?['pointsOutstanding'] as num?)?.toInt() ?? 0,
      );
}

/// Everything that mutates a customer's point balance (earn, redeem, reverse)
/// goes through Cloud Functions callables — see the plan's rationale: these
/// need server-side atomic transactions, OTP verification, and race-safety
/// that Firestore security rules alone can't express. This repo only ever
/// *reads* `customers`/`transactions` directly.
class LedgerRepository {
  LedgerRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _customers(String businessId) =>
      _db.collection('businesses').doc(businessId).collection('customers');

  CollectionReference<Map<String, dynamic>> _txns(String businessId) =>
      _db.collection('businesses').doc(businessId).collection('transactions');

  Future<T> _call<T>(String name, Map<String, dynamic> data, T Function(Map<String, dynamic>) map) async {
    try {
      final result = await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return map(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw LedgerFailure(e.message ?? 'something went wrong. please try again.', code: e.code);
    }
  }

  // ---- reads ----

  Stream<Customer?> watchCustomer(String businessId, String phone) => _customers(businessId).doc(phone).snapshots().map(
        (snap) => snap.exists ? Customer.fromMap(snap.id, snap.data()!) : null,
      );

  Future<Customer?> lookupCustomer(String businessId, String phone) async {
    final snap = await _customers(businessId).doc(phone).get();
    return snap.exists ? Customer.fromMap(snap.id, snap.data()!) : null;
  }

  Stream<List<LoyaltyTransaction>> watchRecentTransactions(String businessId, {int limit = 6}) =>
      _txns(businessId).orderBy('createdAt', descending: true).limit(limit).snapshots().map(
            (q) => q.docs.map((d) => LoyaltyTransaction.fromMap(d.id, d.data())).toList(),
          );

  Stream<List<LoyaltyTransaction>> watchCustomerHistory(String businessId, String phone, {int limit = 6}) => _txns(
        businessId,
      ).where('phone', isEqualTo: phone).orderBy('createdAt', descending: true).limit(limit).snapshots().map(
            (q) => q.docs.map((d) => LoyaltyTransaction.fromMap(d.id, d.data())).toList(),
          );

  Stream<List<LoyaltyTransaction>> watchCorrectionFeed(String businessId, {String? phoneFilter, int limit = 60}) {
    Query<Map<String, dynamic>> q = _txns(businessId);
    q = (phoneFilter != null && phoneFilter.isNotEmpty)
        ? q.where('phone', isEqualTo: phoneFilter)
        : q;
    return q.orderBy('createdAt', descending: true).limit(limit).snapshots().map(
          (snap) => snap.docs.map((d) => LoyaltyTransaction.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<BusinessStats> watchStats(String businessId) => _db
      .collection('businesses')
      .doc(businessId)
      .collection('stats')
      .doc('summary')
      .snapshots()
      .map((snap) => BusinessStats.fromMap(snap.data()));

  // ---- writes (callables) ----

  Future<({int points, int newBalance})> earnCredit({required String phone, required num amount}) => _call(
        'earnCredit',
        {'phone': phone, 'amount': amount},
        (data) => (points: (data['points'] as num).toInt(), newBalance: (data['newBalance'] as num).toInt()),
      );

  Future<void> sendOtp({required String phone}) =>
      _call('sendOtp', {'phone': phone}, (_) {});

  Future<int> redeemPoints({
    required String phone,
    required int points,
    String? otpCode,
    bool override = false,
  }) =>
      _call(
        'redeemPoints',
        {'phone': phone, 'points': points, 'otpCode': ?otpCode, 'override': override},
        (data) => (data['newBalance'] as num).toInt(),
      );

  Future<void> reverseTransaction(String txnId) =>
      _call('reverseTransaction', {'txnId': txnId}, (_) {});

  Future<void> saveOtpGatewayCredentials({required String apiKey, required String apiSecret}) =>
      _call('saveOtpGatewayCredentials', {'apiKey': apiKey, 'apiSecret': apiSecret}, (_) {});
}
