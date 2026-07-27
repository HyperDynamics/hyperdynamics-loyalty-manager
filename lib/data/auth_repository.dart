import 'package:cloud_functions/cloud_functions.dart';
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

/// Login here is by "business id", not email. Firebase Auth only speaks
/// email/password, so every business is provisioned (server-side, at
/// payment-webhook time) with a synthetic login email; this repository
/// resolves business id -> that email via a callable before signing in.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String> _resolveLoginEmail(String businessId) async {
    try {
      final result = await _functions
          .httpsCallable('resolveBusinessLoginEmail')
          .call<Map<String, dynamic>>({'businessId': businessId.trim().toLowerCase()});
      final email = result.data['email'] as String?;
      if (email == null || email.isEmpty) throw const AuthFailure(_invalidCredentialsMessage);
      return email;
    } on FirebaseFunctionsException {
      throw const AuthFailure(_invalidCredentialsMessage);
    }
  }

  Future<void> login({required String businessId, required String password}) async {
    if (businessId.trim().isEmpty || password.isEmpty) {
      throw const AuthFailure('enter both your business id and password to continue.');
    }
    final email = await _resolveLoginEmail(businessId);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      throw const AuthFailure(_invalidCredentialsMessage);
    }
  }

  Future<void> sendPasswordReset(String businessId) async {
    final email = await _resolveLoginEmail(businessId);
    await _auth.sendPasswordResetEmail(email: email);
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
