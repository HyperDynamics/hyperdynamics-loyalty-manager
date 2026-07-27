import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/payment_order.dart';

class PaymentRepository {
  PaymentRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Creates a Razorpay Payment Link for the flat ₹5,000 onboarding fee and
  /// a `paymentOrders` doc to correlate the later webhook. Returns the
  /// hosted Razorpay checkout URL to redirect to (external, not embedded).
  Future<({String referenceId, String checkoutUrl})> createOnboardingPaymentLink() async {
    final result = await _functions.httpsCallable('createOnboardingPaymentLink').call<Map<String, dynamic>>();
    return (
      referenceId: result.data['referenceId'] as String,
      checkoutUrl: result.data['checkoutUrl'] as String,
    );
  }

  Stream<PaymentOrder?> watchOrder(String referenceId) => _db
      .collection('paymentOrders')
      .doc(referenceId)
      .snapshots()
      .map((snap) => snap.exists ? PaymentOrder.fromMap(snap.id, snap.data()!) : null);
}
