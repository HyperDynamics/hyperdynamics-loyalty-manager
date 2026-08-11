import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/correction/correction_screen.dart';
import '../features/customers/birthday_screen.dart';
import '../features/customers/customer_list_screen.dart';
import '../features/earn/earn_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/operator/operator_console_screen.dart';
import '../features/operator/operator_login_screen.dart';
import '../features/redeem/redeem_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/dashboard_screen.dart';
import '../features/signup/pending_approval_screen.dart';
import '../features/signup/signup_screen.dart';
import '../features/subscription/subscription_lapsed_screen.dart';
import '../providers/admin_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/business_providers.dart';
import 'go_router_refresh.dart';

GoRouter buildRouter(WidgetRef ref, GoRouterRefreshNotifier refresh) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // The operator console has its own, separate session (real email
      // auth + `admin` claim, not `businessId`) — handled independently so
      // it's never affected by, or interferes with, the business redirect
      // logic below.
      if (loc.startsWith('/hd-ops')) {
        final adminAsync = ref.read(adminSessionProvider);
        if (adminAsync.isLoading) return null;
        final isAdmin = adminAsync.value == true;
        final onOperatorLogin = loc == '/hd-ops/login';
        if (!isAdmin && !onOperatorLogin) return '/hd-ops/login';
        if (isAdmin && onOperatorLogin) return '/hd-ops';
        return null;
      }

      final sessionAsync = ref.read(authSessionProvider);
      // Auth state is still resolving (first launch, or right after
      // sign-in while we fetch the businessId claim) — hold position
      // rather than bouncing to /login and back.
      if (sessionAsync.isLoading) return null;

      final loggedIn = sessionAsync.value != null;
      final onAppRoute = loc.startsWith('/app');
      final onAuthGateRoute = loc == '/login' || loc == '/' || loc == '/signup';
      final onPending = loc == '/pending';
      final onLapsed = loc == '/subscription-lapsed';

      if (!loggedIn && (onAppRoute || onPending || onLapsed)) return '/login';

      // A signed-in business whose account isn't active yet (self-signup,
      // not yet paid or approved) is confined to /pending, and one whose
      // ₹999/year subscription has lapsed is confined to
      // /subscription-lapsed, until the corresponding admin action flips
      // it — see the currentBusinessProvider listener in app.dart, which
      // re-runs this redirect the moment either happens.
      if (loggedIn) {
        final bizAsync = ref.read(currentBusinessProvider);
        if (bizAsync.isLoading) return null;
        final business = bizAsync.value;
        final pending = business?.status == 'pending';
        final lapsed = !pending && (business?.subscriptionLapsed ?? false);

        if (pending && !onPending) return '/pending';
        if (lapsed && !onLapsed) return '/subscription-lapsed';
        if (!pending && !lapsed && (onAuthGateRoute || onPending || onLapsed)) return '/app/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => SignupScreen(plan: state.uri.queryParameters['plan'])),
      GoRoute(path: '/pending', builder: (context, state) => const PendingApprovalScreen()),
      GoRoute(path: '/subscription-lapsed', builder: (context, state) => const SubscriptionLapsedScreen()),
      GoRoute(path: '/hd-ops/login', builder: (context, state) => const OperatorLoginScreen()),
      GoRoute(path: '/hd-ops', builder: (context, state) => const OperatorConsoleScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/app/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/app/earn', builder: (context, state) => const EarnScreen()),
          GoRoute(path: '/app/redeem', builder: (context, state) => const RedeemScreen()),
          GoRoute(path: '/app/customers', builder: (context, state) => const CustomerListScreen()),
          GoRoute(path: '/app/birthdays', builder: (context, state) => const BirthdayScreen()),
          GoRoute(
            path: '/app/correction',
            builder: (context, state) => CorrectionScreen(initialFilter: state.uri.queryParameters['filter']),
          ),
          GoRoute(path: '/app/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
}
