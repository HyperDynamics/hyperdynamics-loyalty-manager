import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_business_summary.dart';
import '../models/pending_business.dart';
import '../models/staff_member.dart';
import 'repository_providers.dart';

/// Whether the currently signed-in Firebase user carries the `admin`
/// custom claim — separate from `authSessionProvider`, which keys off the
/// `businessId` claim instead. The two are mutually exclusive in practice
/// (an operator account has no `businessId`; a business account has no
/// `admin`), but both watch the same shared `FirebaseAuth` instance.
class AdminSessionNotifier extends AsyncNotifier<bool> {
  StreamSubscription<User?>? _sub;

  @override
  Future<bool> build() async {
    final repo = ref.watch(adminRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());

    _sub = repo.authStateChanges().listen((user) async {
      final isAdmin = user == null ? false : await repo.isAdmin();
      if (ref.mounted) state = AsyncData(isAdmin);
    });

    final user = repo.currentUser;
    return user == null ? false : repo.isAdmin();
  }
}

final adminSessionProvider = AsyncNotifierProvider<AdminSessionNotifier, bool>(AdminSessionNotifier.new);

/// Businesses awaiting activation — no live Firestore read here (matching
/// the admin console's existing callable-only pattern), so this is a plain
/// `FutureProvider`, refreshed via `ref.invalidate` after an approval.
final pendingBusinessesProvider = FutureProvider<List<PendingBusiness>>((ref) {
  return ref.watch(adminRepositoryProvider).listPending();
});

/// "Manage businesses" browser, keyed by search text — a `FutureProvider`
/// like the one above, re-fetched via `ref.invalidate` after a flag toggle.
final adminBusinessesProvider = FutureProvider.family<List<AdminBusinessSummary>, String>((ref, search) {
  return ref.watch(adminRepositoryProvider).listBusinesses(search: search);
});

/// Staff on one business, keyed by business id. Fetched only when the staff
/// panel is opened rather than joined into `adminBusinessesProvider` — that
/// list can hold 200 businesses, and counting staff for each would mean 200
/// extra queries on every console load.
final adminStaffProvider = FutureProvider.family<List<StaffMember>, String>((ref, businessId) {
  return ref.watch(adminRepositoryProvider).listStaff(businessId);
});
