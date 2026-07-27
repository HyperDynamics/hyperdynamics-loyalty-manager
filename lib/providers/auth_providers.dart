import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

class AuthSession {
  const AuthSession({required this.user, required this.businessId});
  final User user;
  final String businessId;
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

  Future<AuthSession?> _resolve(User? user) async {
    if (user == null) return null;
    final repo = ref.read(authRepositoryProvider);
    final businessId = await repo.currentBusinessId();
    if (businessId == null) return null;
    return AuthSession(user: user, businessId: businessId);
  }

  Future<void> refreshClaims() async {
    final repo = ref.read(authRepositoryProvider);
    final session = await _resolve(repo.currentUser);
    state = AsyncData(session);
  }
}

final authSessionProvider = AsyncNotifierProvider<AuthSessionNotifier, AuthSession?>(AuthSessionNotifier.new);
