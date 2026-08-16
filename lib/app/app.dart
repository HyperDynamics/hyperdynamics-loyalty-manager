import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/business.dart';
import '../providers/admin_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/business_providers.dart';
import '../providers/feedback_providers.dart';
import '../providers/repository_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/toast_host.dart';
import 'go_router_refresh.dart';
import 'router.dart';

class LoyaltyManagerApp extends ConsumerStatefulWidget {
  const LoyaltyManagerApp({super.key});

  @override
  ConsumerState<LoyaltyManagerApp> createState() => _LoyaltyManagerAppState();
}

class _LoyaltyManagerAppState extends ConsumerState<LoyaltyManagerApp> {
  late final GoRouterRefreshNotifier _refresh;
  late final GoRouter _router;
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    _refresh = GoRouterRefreshNotifier();
    _router = buildRouter(ref, _refresh);
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) => _refresh.notify());
    ref.listen(adminSessionProvider, (previous, next) => _refresh.notify());
    // A pending business's status can flip to active while they're sitting
    // on /pending (Razorpay webhook fires, or an admin approves) — without
    // this, the redirect callback wouldn't re-run until the next manual
    // navigation, so the live status update wouldn't feel live.
    ref.listen(currentBusinessProvider, (previous, next) {
      _refresh.notify();
      // Debounced rather than checked immediately: this device's own
      // `beginSession` write echoes back through this same stream, and a
      // snapshot can arrive before local state catches up — checking
      // straight away risks a device evicting itself. Re-reads both values
      // fresh when the timer fires rather than closing over stale ones.
      _sessionCheckTimer?.cancel();
      _sessionCheckTimer = Timer(const Duration(seconds: 2), () {
        _checkSessionStillActive(ref, ref.read(currentBusinessProvider).value);
      });
    });

    return MaterialApp.router(
      title: 'HyperDynamics Loyalty Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      builder: (context, child) => LoadingOverlay(
        child: Stack(
          children: [
            ?child,
            const ToastHost(),
          ],
        ),
      ),
    );
  }
}

/// Live counterpart to the server-side check in `assertSessionActive`
/// (`functions/src/sessions.ts`) — as soon as this device's `sessionId`
/// disappears from the business's active list (a newer login elsewhere
/// evicted it), sign out immediately instead of waiting for this device's
/// next earn/redeem attempt to fail. `session?.sessionId == null` covers
/// the brief window right after login before `beginDeviceSession` has run.
void _checkSessionStillActive(WidgetRef ref, Business? business) {
  if (business == null) return;
  final localSessionId = ref.read(authSessionProvider).value?.sessionId;
  if (localSessionId == null || business.activeSessionIds.contains(localSessionId)) return;

  ref.read(authRepositoryProvider).logout();
  ref.read(toastProvider.notifier).show(
        "you've been signed out — this account is active on another device.",
        ToastTone.info,
      );
}
