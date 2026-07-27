enum PaymentOrderStatus { created, paid, failed }

class PaymentOrder {
  const PaymentOrder({required this.id, required this.status, this.businessId});

  final String id;
  final PaymentOrderStatus status;
  final String? businessId;

  factory PaymentOrder.fromMap(String id, Map<String, dynamic> map) => PaymentOrder(
        id: id,
        status: switch (map['status']) {
          'paid' => PaymentOrderStatus.paid,
          'failed' => PaymentOrderStatus.failed,
          _ => PaymentOrderStatus.created,
        },
        businessId: map['businessId'] as String?,
      );
}
