import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_business_summary.dart';
import '../models/pending_business.dart';
import '../models/staff_member.dart';

class AdminFailure implements Exception {
  const AdminFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The operator console's auth is deliberately separate from
/// `AuthRepository`'s business-id login: this signs in with a *real* email,
/// and every write goes through `adminCreateBusiness`, which the backend
/// only accepts from a token carrying the `admin` custom claim (see
/// `functions/src/lib/authContext.ts#requireAdmin`). The hidden route is
/// not the security boundary — that claim check is.
///
/// Shares the app's single `FirebaseAuth` instance, so signing in here
/// replaces any currently signed-in business session in the same browser.
class AdminRepository {
  AdminRepository({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult();
    return token.claims?['admin'] == true;
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException {
      throw const AdminFailure('invalid email or password.');
    }
    if (!await isAdmin()) {
      await _auth.signOut();
      throw const AdminFailure('this account is not authorized.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      // Swallowed deliberately, same as the business login's reset flow —
      // don't reveal whether the email is a real admin account.
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<({String businessId, String loginEmail, String tempPassword})> createBusiness({
    required String businessName,
    required String plan,
    String? ownerEmail,
    String? ownerPhone,
  }) async {
    try {
      final result = await _functions.httpsCallable('adminCreateBusiness').call<Map<String, dynamic>>({
        'businessName': businessName,
        'plan': plan,
        if (ownerEmail != null && ownerEmail.isNotEmpty) 'ownerEmail': ownerEmail,
        if (ownerPhone != null && ownerPhone.isNotEmpty) 'ownerPhone': ownerPhone,
      });
      return (
        businessId: result.data['businessId'] as String,
        loginEmail: result.data['loginEmail'] as String,
        tempPassword: result.data['tempPassword'] as String,
      );
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not create business. please try again.');
    }
  }

  /// Businesses that self-signed up (see `SignupRepository`) and are
  /// waiting on activation — either a Razorpay webhook or a manual approval
  /// here, for payment collected outside Razorpay.
  Future<List<PendingBusiness>> listPending() async {
    try {
      final result = await _functions.httpsCallable('adminListPendingBusinesses').call<List<Object?>>();
      return result.data
          .cast<Map<Object?, Object?>>()
          .map((m) => PendingBusiness.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not load pending businesses.');
    }
  }

  Future<void> approve(String businessId) async {
    try {
      await _functions.httpsCallable('adminApproveBusiness').call<Map<String, dynamic>>({'businessId': businessId});
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not approve business. please try again.');
    }
  }

  /// "Manage businesses" browser — any status, for toggling add-on feature
  /// flags on businesses that are already active (not just pending ones).
  Future<List<AdminBusinessSummary>> listBusinesses({String? search}) async {
    try {
      final result = await _functions.httpsCallable('adminListBusinesses').call<List<Object?>>({
        if (search != null && search.isNotEmpty) 'search': search,
      });
      return result.data
          .cast<Map<Object?, Object?>>()
          .map((m) => AdminBusinessSummary.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not load businesses.');
    }
  }

  Future<void> updateFeatures(
    String businessId, {
    bool? birthdayEnabled,
    bool? whatsappEnabled,
    bool? exportEnabled,
    bool? salesDashboardEnabled,
    int? maxConcurrentSessions,
  }) async {
    try {
      await _functions.httpsCallable('adminUpdateBusinessFeatures').call<Map<String, dynamic>>({
        'businessId': businessId,
        'birthdayEnabled': ?birthdayEnabled,
        'whatsappEnabled': ?whatsappEnabled,
        'exportEnabled': ?exportEnabled,
        'salesDashboardEnabled': ?salesDashboardEnabled,
        'maxConcurrentSessions': ?maxConcurrentSessions,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not update features. please try again.');
    }
  }

  /// Staff seats are operator-controlled, not self-serve — see
  /// `functions/src/staff.ts`. Staff sign in with Google only, so [email] must
  /// be a gmail address; the callable rejects anything else.
  Future<List<StaffMember>> listStaff(String businessId) async {
    try {
      final res = await _functions.httpsCallable('adminListStaff').call<List<dynamic>>({'businessId': businessId});
      return res.data
          .cast<Map<Object?, Object?>>()
          .map((m) => StaffMember.fromMap(m.cast<String, dynamic>()))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not load staff.');
    }
  }

  Future<StaffMember> createStaff(
    String businessId, {
    required String email,
    String? displayName,
  }) async {
    try {
      final res = await _functions.httpsCallable('adminCreateStaff').call<Map<Object?, Object?>>({
        'businessId': businessId,
        'email': email,
        'displayName': ?displayName,
      });
      return StaffMember.fromMap(res.data.cast<String, dynamic>());
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not add staff. please try again.');
    }
  }

  Future<void> removeStaff(String businessId, String uid) async {
    try {
      await _functions.httpsCallable('adminRemoveStaff').call<Map<String, dynamic>>({
        'businessId': businessId,
        'uid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not remove staff. please try again.');
    }
  }

  /// Renews a business's ₹999/year subscription by a year — see
  /// `functions/src/admin.ts#adminRenewSubscription` for the extend-from-
  /// later-of-now-or-current-renewal-date logic.
  Future<void> renewSubscription(String businessId) async {
    try {
      await _functions.httpsCallable('adminRenewSubscription').call<Map<String, dynamic>>({'businessId': businessId});
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not renew subscription. please try again.');
    }
  }

  /// Diagnostic only, not a fraud gate — see
  /// `functions/src/multiLocation.ts#adminCheckMultiLocation` for what
  /// "multi-location" means here (multiple distinct networks transacting
  /// on the same day) and why it's evidence for a conversation, not proof.
  Future<MultiLocationCheck> checkMultiLocation(String businessId, {int days = 30}) async {
    try {
      final result = await _functions.httpsCallable('adminCheckMultiLocation').call<Map<String, dynamic>>({
        'businessId': businessId,
        'days': days,
      });
      return MultiLocationCheck.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      throw AdminFailure(e.message ?? 'could not run the check. please try again.');
    }
  }
}

class MultiLocationCheck {
  const MultiLocationCheck({
    required this.daysAnalyzed,
    required this.totalDistinctIps,
    required this.multiIpDayCount,
    required this.multiIpDays,
  });

  final int daysAnalyzed;
  final int totalDistinctIps;
  final int multiIpDayCount;
  final List<({String day, int distinctIps})> multiIpDays;

  factory MultiLocationCheck.fromMap(Map<String, dynamic> map) => MultiLocationCheck(
        daysAnalyzed: (map['daysAnalyzed'] as num?)?.toInt() ?? 0,
        totalDistinctIps: (map['totalDistinctIps'] as num?)?.toInt() ?? 0,
        multiIpDayCount: (map['multiIpDayCount'] as num?)?.toInt() ?? 0,
        multiIpDays: ((map['multiIpDays'] as List?) ?? const [])
            .cast<Map<Object?, Object?>>()
            .map((m) => (day: m['day'] as String? ?? '', distinctIps: (m['distinctIps'] as num?)?.toInt() ?? 0))
            .toList(),
      );
}
