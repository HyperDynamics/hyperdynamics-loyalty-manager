import 'package:cloud_firestore/cloud_firestore.dart';

enum OtpGateway { byo, managed }

/// Who the signed-in account is *within* a business. An absent `role` claim
/// means owner — every account that existed before staff shipped is a business's
/// own login, so this must never default to the more restricted role.
enum BusinessRole { owner, staff }

/// The single staff policy a business applies to all of its staff accounts
/// (owner-edited in Settings, mirrored server-side in `lib/authContext.ts`).
/// Deliberately has no `settings` key: staff who could edit settings could grant
/// themselves everything else here, so it stays owner-only and untoggleable.
class StaffPermissions {
  const StaffPermissions({
    this.earn = true,
    this.redeem = true,
    this.correction = true,
    this.customers = false,
    this.birthdays = false,
    this.export = false,
    this.sales = false,
  });

  final bool earn;
  final bool redeem;
  final bool correction;
  final bool customers;
  final bool birthdays;
  final bool export;
  final bool sales;

  static const defaults = StaffPermissions();

  factory StaffPermissions.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const {};
    bool read(String key, bool fallback) => (m[key] as bool?) ?? fallback;
    return StaffPermissions(
      earn: read('earn', true),
      redeem: read('redeem', true),
      correction: read('correction', true),
      customers: read('customers', false),
      birthdays: read('birthdays', false),
      export: read('export', false),
      sales: read('sales', false),
    );
  }

  Map<String, bool> toMap() => {
        'earn': earn,
        'redeem': redeem,
        'correction': correction,
        'customers': customers,
        'birthdays': birthdays,
        'export': export,
        'sales': sales,
      };

  StaffPermissions copyWith({
    bool? earn,
    bool? redeem,
    bool? correction,
    bool? customers,
    bool? birthdays,
    bool? export,
    bool? sales,
  }) =>
      StaffPermissions(
        earn: earn ?? this.earn,
        redeem: redeem ?? this.redeem,
        correction: correction ?? this.correction,
        customers: customers ?? this.customers,
        birthdays: birthdays ?? this.birthdays,
        export: export ?? this.export,
        sales: sales ?? this.sales,
      );
}

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
    this.billNumberRequired = true,
    this.manualPointsEnabled = false,
    this.birthdayWindowDays = 1,
    this.salesDashboardEnabled = true,
    this.staffPermissions = StaffPermissions.defaults,
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
  /// `assertSessionActive` in the backend). [activeSessionIds] is the
  /// current occupants; used client-side only to detect this device having
  /// been evicted by a newer login elsewhere (see `app.dart`'s listener).
  final int maxConcurrentSessions;
  final List<String> activeSessionIds;

  /// Owner-configurable in Settings (all four are in `firestore.rules`'
  /// client-writable allow-list). Bill numbers and the sales card default to
  /// their pre-existing behaviour when the field is absent, so adding these
  /// switches never silently takes a feature away from a live business.
  final bool billNumberRequired;
  final bool manualPointsEnabled;
  final int birthdayWindowDays;

  /// Operator-controlled (`adminUpdateBusinessFeatures`), not client-writable.
  final bool salesDashboardEnabled;

  final StaffPermissions staffPermissions;

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
        billNumberRequired: (map['billNumberRequired'] as bool?) ?? true,
        manualPointsEnabled: (map['manualPointsEnabled'] as bool?) ?? false,
        birthdayWindowDays: ((map['birthdayWindowDays'] as num?)?.toInt() ?? 1).clamp(1, 10),
        salesDashboardEnabled: (map['salesDashboardEnabled'] as bool?) ?? true,
        staffPermissions: StaffPermissions.fromMap((map['staffPermissions'] as Map?)?.cast<String, dynamic>()),
      );

  Business copyWith({
    String? displayName,
    String? logoUrl,
    int? pointsRatio,
    bool? otpEnabled,
    OtpGateway? gateway,
    bool? billNumberRequired,
    bool? manualPointsEnabled,
    int? birthdayWindowDays,
    StaffPermissions? staffPermissions,
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
        billNumberRequired: billNumberRequired ?? this.billNumberRequired,
        manualPointsEnabled: manualPointsEnabled ?? this.manualPointsEnabled,
        birthdayWindowDays: birthdayWindowDays ?? this.birthdayWindowDays,
        salesDashboardEnabled: salesDashboardEnabled,
        staffPermissions: staffPermissions ?? this.staffPermissions,
      );
}
