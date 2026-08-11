class PendingBusiness {
  const PendingBusiness({
    required this.businessId,
    required this.displayName,
    required this.otpEnabled,
    required this.ownerEmail,
    required this.ownerPhone,
  });

  final String businessId;
  final String displayName;
  final bool otpEnabled;
  final String ownerEmail;
  final String ownerPhone;

  factory PendingBusiness.fromMap(Map<String, dynamic> map) => PendingBusiness(
        businessId: map['businessId'] as String,
        displayName: (map['displayName'] as String?) ?? '',
        otpEnabled: (map['otpEnabled'] as bool?) ?? false,
        ownerEmail: (map['ownerEmail'] as String?) ?? '',
        ownerPhone: (map['ownerPhone'] as String?) ?? '',
      );
}
