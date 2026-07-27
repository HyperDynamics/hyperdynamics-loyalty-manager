import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/correction/correction_screen.dart';
import '../features/earn/earn_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/payment_confirm/payment_confirm_screen.dart';
import '../features/redeem/redeem_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/dashboard_screen.dart';
import '../providers/auth_providers.dart';
import 'go_router_refresh.dart';

GoRouter buildRouter(WidgetRef ref, GoRouterRefreshNotifier refresh) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final sessionAsync = ref.read(authSessionProvider);
      // Auth state is still resolving (first launch, or right after
      // sign-in while we fetch the businessId claim) — hold position
      // rather than bouncing to /login and back.
      if (sessionAsync.isLoading) return null;

      final loggedIn = sessionAsync.value != null;
      final loc = state.matchedLocation;
      final onAppRoute = loc.startsWith('/app');
      final onLogin = loc == '/login';

      if (!loggedIn && onAppRoute) return '/login';
      if (loggedIn && (onLogin || loc == '/')) return '/app/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(
        path: '/payment/confirm',
        builder: (context, state) => PaymentConfirmScreen(
          referenceId: state.uri.queryParameters['razorpay_payment_link_reference_id'] ??
              state.uri.queryParameters['ref'] ??
              '',
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/app/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/app/earn', builder: (context, state) => const EarnScreen()),
          GoRoute(path: '/app/redeem', builder: (context, state) => const RedeemScreen()),
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
