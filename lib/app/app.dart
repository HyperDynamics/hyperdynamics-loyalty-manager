import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _refresh = GoRouterRefreshNotifier();
    _router = buildRouter(ref, _refresh);
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) => _refresh.notify());

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
