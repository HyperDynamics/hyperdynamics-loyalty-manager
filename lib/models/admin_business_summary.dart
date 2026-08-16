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
    this.salesDashboardEnabled = true,
    this.subscriptionRenewsAt,
    this.maxConcurrentSessions = 1,
    this.activeSessionCount = 0,
    this.maxStaffSeats = 3,
  });

  final String businessId;
  final String displayName;
  final String ownerEmail;
  final bool otpEnabled;
  final bool birthdayEnabled;
  final bool whatsappEnabled;
  final bool exportEnabled;

  /// Unlike the paid add-ons above this defaults to true — the sales card
  /// predates the switch, so an absent field must keep it visible rather than
  /// silently removing a feature every live business already has.
  final bool salesDashboardEnabled;

  /// How many devices each account on this business may be signed in on at
  /// once (the cap is per user account, so staff don't evict each other), and
  /// how many device sessions are currently registered across all of them —
  /// see `beginSession`/`assertSessionActive` in the backend.
  final int maxConcurrentSessions;
  final int activeSessionCount;

  /// How many staff accounts this business may have — owner-managed self-serve
  /// in Settings, but the cap itself is operator-adjustable per business (see
  /// `adminUpdateBusinessFeatures`). Default 3, matching provisioning.
  final int maxStaffSeats;

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
        salesDashboardEnabled: (map['salesDashboardEnabled'] as bool?) ?? true,
        subscriptionRenewsAt: map['subscriptionRenewsAt'] != null ? DateTime.parse(map['subscriptionRenewsAt'] as String) : null,
        maxConcurrentSessions: (map['maxConcurrentSessions'] as num?)?.toInt() ?? 1,
        activeSessionCount: (map['activeSessionCount'] as num?)?.toInt() ?? 0,
        maxStaffSeats: (map['maxStaffSeats'] as num?)?.toInt() ?? 3,
      );
}
