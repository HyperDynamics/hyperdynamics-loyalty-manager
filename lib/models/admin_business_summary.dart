/// A row in the operator console's "manage businesses" list — separate from
/// [PendingBusiness] (used specifically by the pending-approvals card),
/// since this covers businesses of any status and carries the feature-flag
/// fields instead of signup metadata.
class AdminBusinessSummary {
  const AdminBusinessSummary({
    required this.businessId,
    required this.displayName,
    required this.ownerEmail,
    required this.otpEnabled,
    required this.birthdayEnabled,
    required this.whatsappEnabled,
    required this.exportEnabled,
    this.subscriptionRenewsAt,
    this.maxConcurrentSessions = 1,
    this.activeSessionCount = 0,
  });

  final String businessId;
  final String displayName;
  final String ownerEmail;
  final bool otpEnabled;
  final bool birthdayEnabled;
  final bool whatsappEnabled;
  final bool exportEnabled;

  /// How many devices may be signed in to this business's shared login at
  /// once, and how many currently are — see `beginSession`/
  /// `requireActiveSession` in the backend.
  final int maxConcurrentSessions;
  final int activeSessionCount;

  /// Null for a still-pending business — the ₹999/year clock starts at
  /// approval, not at signup.
  final DateTime? subscriptionRenewsAt;

  bool get subscriptionLapsed => subscriptionRenewsAt != null && subscriptionRenewsAt!.isBefore(DateTime.now());

  factory AdminBusinessSummary.fromMap(Map<String, dynamic> map) => AdminBusinessSummary(
        businessId: map['businessId'] as String,
        displayName: (map['displayName'] as String?) ?? '',
        ownerEmail: (map['ownerEmail'] as String?) ?? '',
        otpEnabled: (map['otpEnabled'] as bool?) ?? false,
        birthdayEnabled: (map['birthdayEnabled'] as bool?) ?? false,
        whatsappEnabled: (map['whatsappEnabled'] as bool?) ?? false,
        exportEnabled: (map['exportEnabled'] as bool?) ?? false,
        subscriptionRenewsAt: map['subscriptionRenewsAt'] != null ? DateTime.parse(map['subscriptionRenewsAt'] as String) : null,
        maxConcurrentSessions: (map['maxConcurrentSessions'] as num?)?.toInt() ?? 1,
        activeSessionCount: (map['activeSessionCount'] as num?)?.toInt() ?? 0,
      );
}
