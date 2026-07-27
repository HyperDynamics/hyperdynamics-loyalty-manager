class Customer {
  const Customer({required this.phone, required this.name, required this.balance});

  final String phone;
  final String name;
  final int balance;

  factory Customer.fromMap(String phone, Map<String, dynamic> map) => Customer(
        phone: phone,
        name: (map['name'] as String?) ?? 'customer',
        balance: (map['balance'] as num?)?.toInt() ?? 0,
      );
}
