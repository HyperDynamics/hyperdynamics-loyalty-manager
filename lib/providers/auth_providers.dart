import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart' show BusinessRole;
import 'repository_providers.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.businessId,
    this.sessionId,
    this.role = BusinessRole.owner,
  });
  final User user;
  final String businessId;

  /// This device's `sessionId` claim, if `beginSession` has granted one —
  /// see `AuthSessionNotifier.beginDeviceSession` and `app.dart`'s
  /// eviction listener.
  final String? sessionId;

  /// Owner vs staff within this business. Drives nav/route gating alongside
  /// the business's `staffPermissions`; the server re-checks independently, so
  /// this is presentation, not the security boundary.
  final BusinessRole role;

  bool get isOwner => role == BusinessRole.owner;

  /// Human label for the "who is at the till" line on Earn/Redeem.
  String get actorLabel => user.displayName?.trim().isNotEmpty == true
      ? user.displayName!.trim()
      : (user.email ?? '').split('@').first;
}

/// Single source of truth for "who's logged in, for which business" —
/// combines Firebase Auth's user stream with the `businessId` custom claim.
/// `AsyncData(null)` means signed out; go_router's redirect and every
/// screen in the authed shell key off this.
class AuthSessionNotifier extends AsyncNotifier<AuthSession?> {
  StreamSubscription<User?>? _sub;

  @override
  Future<AuthSession?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());

    _sub = repo.authStateChanges().listen((user) async {
      final session = await _resolve(user);
      if (ref.mounted) state = AsyncData(session);
    });

    return _resolve(repo.currentUser);
  }

  Future<AuthSession?> _resolve(User? user, {bool forceRefresh = false}) async {
    if (user == null) return null;
    final repo = ref.read(authRepositoryProvider);
    final businessId = await repo.currentBusinessId(forceRefresh: forceRefresh);
    if (businessId == null) return null;
    final sessionId = await repo.currentSessionId(forceRefresh: forceRefresh);
    final role = await repo.currentRole(forceRefresh: forceRefresh);
    return AuthSession(user: user, businessId: businessId, sessionId: sessionId, role: role);
  }

  /// Forces a real token refresh — needed right after a claim was just
  /// granted server-side (e.g. by `selfSignupGoogle`), since the cached ID
  /// token wouldn't reflect it otherwise.
  Future<void> refreshClaims() async {
    final repo = ref.read(authRepositoryProvider);
    final session = await _resolve(repo.currentUser, forceRefresh: true);
    state = AsyncData(session);
  }

  /// Registers this device as a fresh active session — call exactly once,
  /// right after a login/signup flow's sign-in succeeds (never on a page
  /// reload of an already-authed session, which would needlessly evict this
  /// same device's own prior registration). Requires the `businessId` claim
  /// to already be present, so call `refreshClaims()` first if this follows
  /// a claim grant that hasn't been picked up locally yet (e.g. Google
  /// self-signup).
  Future<void> beginDeviceSession() async {
    final repo = ref.read(authRepositoryProvider);
    final sessionId = await repo.beginSession();
    // Set local state from the callable's own response immediately —
    // deliberately not re-resolved via a token refresh here, since that
    // round trip can lose the race against Firestore echoing this same
    // write back through `currentBusinessProvider` (see `beginSession`'s
    // doc comment). The token itself still gets refreshed in the
    // background by `beginSession`.
    final current = state.value;
    if (current != null) {
      state = AsyncData(AuthSession(
        user: current.user,
        businessId: current.businessId,
        sessionId: sessionId,
        role: current.role,
      ));
    }
  }
}

final authSessionProvider = AsyncNotifierProvider<AuthSessionNotifier, AuthSession?>(AuthSessionNotifier.new);
