import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.birthdayEnabled,
    required this.whatsappEnabled,
    required this.exportEnabled,
    this.subscriptionRenewsAt,
    this.maxConcurrentSessions = 1,
    this.activeSessionIds = const [],
  });

  final String id;
  final String displayName;
  final String? logoUrl;
  final int pointsRatio;
  final bool otpEnabled;
  final OtpGateway gateway;
  final String ownerEmail;
  final String status;

  /// Add-on features, admin-controlled only (see firestore.rules — these
  /// are never in the client-writable field allow-list, unlike `otpEnabled`
  /// which the business can self-toggle from Settings).
  final bool birthdayEnabled;
  final bool whatsappEnabled;
  final bool exportEnabled;

  /// When the ₹999/year subscription is next due — admin-only (set at
  /// approval/renewal time, see `functions/src/admin.ts`). Null only for a
  /// still-`pending` business that hasn't been approved yet.
  final DateTime? subscriptionRenewsAt;

  /// How many devices can be signed in to this business's shared login at
  /// once (admin-configurable, default 1 — see `beginSession`/
  /// `requireActiveSession` in the backend). [activeSessionIds] is the
  /// current occupants; used client-side only to detect this device having
  /// been evicted by a newer login elsewhere (see `app.dart`'s listener).
  final int maxConcurrentSessions;
  final List<String> activeSessionIds;

  bool get subscriptionLapsed => subscriptionRenewsAt != null && subscriptionRenewsAt!.isBefore(DateTime.now());

  factory Business.fromMap(String id, Map<String, dynamic> map) => Business(
        id: id,
        displayName: (map['displayName'] as String?) ?? id,
        logoUrl: map['logoUrl'] as String?,
        pointsRatio: (map['pointsRatio'] as num?)?.toInt() ?? 10,
        otpEnabled: (map['otpEnabled'] as bool?) ?? false,
        gateway: (map['gateway'] == 'byo') ? OtpGateway.byo : OtpGateway.managed,
        ownerEmail: (map['ownerEmail'] as String?) ?? '',
        status: (map['status'] as String?) ?? 'active',
        birthdayEnabled: (map['birthdayEnabled'] as bool?) ?? false,
        whatsappEnabled: (map['whatsappEnabled'] as bool?) ?? false,
        exportEnabled: (map['exportEnabled'] as bool?) ?? false,
        subscriptionRenewsAt: (map['subscriptionRenewsAt'] as Timestamp?)?.toDate(),
        maxConcurrentSessions: (map['maxConcurrentSessions'] as num?)?.toInt() ?? 1,
        activeSessionIds: ((map['activeSessions'] as List?) ?? const [])
            .cast<Map<Object?, Object?>>()
            .map((m) => m['sessionId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
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
        birthdayEnabled: birthdayEnabled,
        whatsappEnabled: whatsappEnabled,
        exportEnabled: exportEnabled,
        subscriptionRenewsAt: subscriptionRenewsAt,
        maxConcurrentSessions: maxConcurrentSessions,
        activeSessionIds: activeSessionIds,
      );
}
