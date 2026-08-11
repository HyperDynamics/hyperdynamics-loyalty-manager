import 'package:cloud_functions/cloud_functions.dart';

class SignupFailure implements Exception {
  const SignupFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Self-serve signup — a distinct concern from login (`AuthRepository`) or
/// payment (`PaymentRepository`): this only ever creates a *pending*
/// business account (see `functions/src/selfSignup.ts`). The caller is
/// expected to sign in with the same email/password right after this
/// succeeds.
class SignupRepository {
  SignupRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<({String businessId})> selfSignup({
    required String businessName,
    required String plan,
    required String email,
    required String password,
    String? ownerPhone,
  }) async {
    try {
      final result = await _functions.httpsCallable('selfSignup').call<Map<String, dynamic>>({
        'businessName': businessName,
        'plan': plan,
        'email': email,
        'password': password,
        if (ownerPhone != null && ownerPhone.isNotEmpty) 'ownerPhone': ownerPhone,
      });
      return (businessId: result.data['businessId'] as String);
    } on FirebaseFunctionsException catch (e) {
      throw SignupFailure(e.message ?? 'could not sign up. please try again.');
    }
  }

  /// Google path — the caller must have already completed the Google OAuth
  /// handshake (`AuthRepository.signInWithGoogleCredentialOnly`) before
  /// calling this, since it runs as that already-authenticated user.
  Future<({String businessId})> selfSignupWithGoogle({
    required String businessName,
    required String plan,
    String? ownerPhone,
  }) async {
    try {
      final result = await _functions.httpsCallable('selfSignupGoogle').call<Map<String, dynamic>>({
        'businessName': businessName,
        'plan': plan,
        if (ownerPhone != null && ownerPhone.isNotEmpty) 'ownerPhone': ownerPhone,
      });
      return (businessId: result.data['businessId'] as String);
    } on FirebaseFunctionsException catch (e) {
      throw SignupFailure(e.message ?? 'could not sign up. please try again.');
    }
  }
}
