import 'package:firebase_auth/firebase_auth.dart';

/// Generic, non-leaking failure message — deliberately doesn't distinguish
/// "unknown business id" from "wrong password", matching the prototype's
/// login error copy and standard auth practice.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

const _invalidCredentialsMessage = 'invalid business id or password. please check and try again.';

/// Domain used to mint synthetic login emails for "business id" auth, e.g.
/// `mintmax@login.hyperdynamics.app`. Must match `LOGIN_EMAIL_DOMAIN`'s
/// default in `functions/src/config.ts` — provisioning (the Razorpay
/// webhook) mints the Firebase Auth user with exactly this email.
const loginEmailDomain = 'login.hyperdynamics.app';

/// Login here is by "business id", not email. Firebase Auth only speaks
/// email/password, so every business is provisioned (server-side, at
/// payment-webhook time) with a synthetic login email of the form
/// `{businessId}@$loginEmailDomain`. The email is a deterministic function
/// of the business id — not a secret — so it's computed directly here
/// rather than resolved via a Cloud Function: that keeps login (and
/// "forgot password") working independently of Cloud Functions/Blaze being
/// live, and Firebase Auth's own brute-force throttling and (by default)
/// email-enumeration-safe error codes already cover what a custom resolver
/// would have added.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String _loginEmail(String businessId) => '${businessId.trim().toLowerCase()}@$loginEmailDomain';

  Future<void> login({required String businessId, required String password}) async {
    if (businessId.trim().isEmpty || password.isEmpty) {
      throw const AuthFailure('enter both your business id and password to continue.');
    }
    try {
      await _auth.signInWithEmailAndPassword(email: _loginEmail(businessId), password: password);
    } on FirebaseAuthException {
      throw const AuthFailure(_invalidCredentialsMessage);
    }
  }

  Future<void> sendPasswordReset(String businessId) async {
    try {
      await _auth.sendPasswordResetEmail(email: _loginEmail(businessId));
    } on FirebaseAuthException {
      // Swallowed deliberately — the caller shows the same "reset link
      // sent" message regardless, so a nonexistent business id can't be
      // distinguished from a real one via this flow either.
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw const AuthFailure('you are not signed in.');
    try {
      final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthFailure('current password is incorrect.');
      }
      throw AuthFailure(e.message ?? 'could not update password.');
    }
  }

  Future<void> logout() => _auth.signOut();

  /// The `businessId` custom claim set on this admin's account at
  /// provisioning time — every Firestore security rule keys off this.
  Future<String?> currentBusinessId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    return token.claims?['businessId'] as String?;
  }
}
