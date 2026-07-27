enum OtpGateway { byo, managed }

class Business {
  const Business({
    required this.id,
    required this.displayName,
    this.logoUrl,
    required this.pointsRatio,
    required this.otpEnabled,
    required this.gateway,
    required this.ownerEmail,
    required this.status,
  });

  final String id;
  final String displayName;
  final String? logoUrl;
  final int pointsRatio;
  final bool otpEnabled;
  final OtpGateway gateway;
  final String ownerEmail;
  final String status;

  factory Business.fromMap(String id, Map<String, dynamic> map) => Business(
        id: id,
        displayName: (map['displayName'] as String?) ?? id,
        logoUrl: map['logoUrl'] as String?,
        pointsRatio: (map['pointsRatio'] as num?)?.toInt() ?? 10,
        otpEnabled: (map['otpEnabled'] as bool?) ?? false,
        gateway: (map['gateway'] == 'byo') ? OtpGateway.byo : OtpGateway.managed,
        ownerEmail: (map['ownerEmail'] as String?) ?? '',
        status: (map['status'] as String?) ?? 'active',
      );

  Business copyWith({
    String? displayName,
    String? logoUrl,
    int? pointsRatio,
    bool? otpEnabled,
    OtpGateway? gateway,
  }) =>
      Business(
        id: id,
        displayName: displayName ?? this.displayName,
        logoUrl: logoUrl ?? this.logoUrl,
        pointsRatio: pointsRatio ?? this.pointsRatio,
        otpEnabled: otpEnabled ?? this.otpEnabled,
        gateway: gateway ?? this.gateway,
        ownerEmail: ownerEmail,
        status: status,
      );
}
