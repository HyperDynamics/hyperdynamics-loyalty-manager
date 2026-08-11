import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
/// default in `functions/src/config.ts` — the admin-create path
/// (`createBusinessAccount`) mints the Firebase Auth user with exactly this
/// email.
const loginEmailDomain = 'login.hyperdynamics.app';

/// Web OAuth client ID for Google sign-in — Firebase Console → Authentication
/// → Sign-in method → Google → Enable auto-creates this. **Placeholder until
/// that manual step is done** (same treatment as the Razorpay/MSG91
/// placeholders in `functions/src/config.ts`) — google sign-in won't work
/// end-to-end until this is replaced with the real value. Web-only for now;
/// see CLAUDE.md's existing notes on Android/iOS being unverified.
const googleWebClientId = 'REPLACE-WITH-FIREBASE-GOOGLE-WEB-CLIENT-ID.apps.googleusercontent.com';

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
  AuthRepository({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

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

  /// Login path for self-signed-up businesses (see `SignupRepository`) —
  /// these accounts were created with the owner's own real email + chosen
  /// password, not a synthetic `{businessId}@$loginEmailDomain` one, so no
  /// translation happens here.
  Future<void> loginWithEmail({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthFailure('enter both your email and password to continue.');
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException {
      throw const AuthFailure(_invalidCredentialsMessage);
    }
  }

  Future<void> sendPasswordResetForEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      // Swallowed deliberately, same reasoning as sendPasswordReset above.
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
  /// [forceRefresh] is required right after a claim was just granted (e.g.
  /// by `selfSignupGoogle`) — the cached ID token wouldn't reflect it yet.
  Future<String?> currentBusinessId({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['businessId'] as String?;
  }

  /// The `sessionId` claim `beginSession` grants this device, if any —
  /// used client-side to detect this device having been evicted by a
  /// newer login elsewhere (see `app.dart`).
  Future<String?> currentSessionId({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['sessionId'] as String?;
  }

  /// Registers this device as an active session for the signed-in business
  /// — call once per fresh sign-in (login or signup), after the
  /// `businessId` claim is confirmed present, never on a page reload of an
  /// already-signed-in session (that would needlessly evict this same
  /// device's own prior session on every refresh). See
  /// `functions/src/sessions.ts` for the eviction/cap logic this backs.
  ///
  /// Returns the new `sessionId` straight from the callable's response
  /// rather than re-deriving it via a token refresh — the business doc's
  /// `activeSessions` write this triggers echoes back through Firestore's
  /// realtime listener almost immediately, and if the caller waited on a
  /// full token-refresh round trip before updating local state, that echo
  /// can arrive first and make this very device look evicted to itself.
  /// The token is still refreshed (in the background, not awaited here) so
  /// the claim is present for future `requireActiveSession` server checks.
  Future<String> beginSession() async {
    final label = kIsWeb ? 'web (${defaultTargetPlatform.name})' : defaultTargetPlatform.name;
    final result = await _functions.httpsCallable('beginSession').call<Map<String, dynamic>>({'deviceLabel': label});
    final sessionId = result.data['sessionId'] as String;
    unawaited(currentSessionId(forceRefresh: true));
    return sessionId;
  }

  /// Deferred until first use rather than at app startup: `googleWebClientId`
  /// is a placeholder until the Google sign-in provider is enabled in the
  /// Firebase Console, and `initialize()` throws on an invalid client id —
  /// doing this in `main()` before `runApp` used to blank the entire app.
  static Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize(clientId: googleWebClientId);
  }

  /// Just the Google OAuth handshake, no assumptions about whether this
  /// account has a `businessId` claim yet — used by both the signup screen
  /// (where it won't, until `selfSignupGoogle` runs) and the login screen
  /// (where it should already).
  Future<void> signInWithGoogleCredentialOnly() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('could not sign in with google. please try again.');
      }
      await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    } on GoogleSignInException {
      throw const AuthFailure('google sign-in was cancelled or failed. please try again.');
    } on FirebaseAuthException {
      throw const AuthFailure('could not sign in with google. please try again.');
    } catch (_) {
      _googleInitFuture = null;
      throw const AuthFailure('google sign-in is not available yet. please use your business id and password.');
    }
  }

  /// Login-screen path: sign in with Google, then require that this account
  /// already has a `businessId` claim (set at signup time by
  /// `selfSignupGoogle`) — if not, this Google account never signed up.
  Future<void> loginWithGoogle() async {
    await signInWithGoogleCredentialOnly();
    final businessId = await currentBusinessId();
    if (businessId == null) {
      await _auth.signOut();
      throw const AuthFailure('no account found for this google account — sign up first.');
    }
  }
}
