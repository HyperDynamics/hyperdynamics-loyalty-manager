import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_order.dart';
import 'repository_providers.dart';

final paymentOrderProvider = StreamProvider.family<PaymentOrder?, String>((ref, referenceId) {
  if (referenceId.isEmpty) return Stream.value(null);
  return ref.watch(paymentRepositoryProvider).watchOrder(referenceId);
});
