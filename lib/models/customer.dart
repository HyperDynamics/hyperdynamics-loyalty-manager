class Customer {
  const Customer({required this.phone, required this.name, required this.balance, this.dob});

  final String phone;
  final String name;
  final int balance;

  /// `YYYY-MM-DD`, optional — set via the Earn screen. `birthdayMonthDay`
  /// (derived server-side) is what the birthday screen actually queries on;
  /// this is just the display/export value.
  final String? dob;

  factory Customer.fromMap(String phone, Map<String, dynamic> map) => Customer(
        phone: phone,
        name: (map['name'] as String?) ?? 'customer',
        balance: (map['balance'] as num?)?.toInt() ?? 0,
        dob: map['dob'] as String?,
      );
}
