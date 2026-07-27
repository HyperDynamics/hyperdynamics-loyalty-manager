import 'package:flutter/foundation.dart';

/// Bridges Riverpod's [authSessionProvider] changes into go_router's
/// `refreshListenable`, so the router re-evaluates its `redirect` whenever
/// sign-in state changes (see app.dart, which calls [notify] from a
/// `ref.listen` on the auth session).
class GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
