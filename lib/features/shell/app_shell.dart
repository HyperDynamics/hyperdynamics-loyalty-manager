import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/business.dart';
import '../../providers/business_providers.dart';
import '../../providers/feedback_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/coin.dart';

class _NavItem {
  const _NavItem(this.location, this.icon, this.label, this.tabLabel, {this.isEnabled});
  final String location;
  final IconData icon;
  final String label;
  final String tabLabel;

  /// Null means always enabled. Used for add-on features (e.g. birthdays)
  /// that are only available once admin turns them on for this business —
  /// the item still renders (as the upsell surface) but is disabled.
  final bool Function(Business? business)? isEnabled;
}

const _navItems = [
  _NavItem('/app/dashboard', Icons.home_rounded, 'home', 'home'),
  _NavItem('/app/earn', Icons.add_circle_outline_rounded, 'earn', 'earn'),
  _NavItem('/app/redeem', Icons.star_outline_rounded, 'redeem', 'redeem'),
  _NavItem('/app/customers', Icons.groups_outlined, 'customers', 'customers'),
  _NavItem('/app/birthdays', Icons.cake_outlined, 'birthdays', 'birthdays', isEnabled: _birthdaysEnabled),
  _NavItem('/app/correction', Icons.history_rounded, 'history & correction', 'fix'),
  _NavItem('/app/settings', Icons.settings_outlined, 'settings', 'settings'),
];

bool _birthdaysEnabled(Business? business) => business?.birthdayEnabled ?? false;

/// D. App shell — sidebar nav on wide/desktop viewports, bottom tab bar on
/// narrow/mobile, exactly mirroring the prototype's `showSidebar`/`showTabbar`
/// breakpoint switch. Every authed screen renders inside this as `child`.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'log out?',
      body: "you'll need your business id and password to sign back in.",
      confirmLabel: 'log out',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed) return;
    await ref.read(authRepositoryProvider).logout();
  }

  void _onNavItemTap(BuildContext context, WidgetRef ref, _NavItem item, Business? business) {
    final enabled = item.isEnabled?.call(business) ?? true;
    if (!enabled) {
      ref.read(toastProvider.notifier).show('contact us to enable this feature.', ToastTone.info);
      return;
    }
    context.go(item.location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.wideBreakpoint;
    final business = ref.watch(currentBusinessProvider).value;
    void onItemTap(_NavItem item) => _onNavItemTap(context, ref, item, business);

    final main = Container(
      color: AppColors.bgApp,
      padding: wide
          ? const EdgeInsets.fromLTRB(40, 36, 40, 60)
          : const EdgeInsets.fromLTRB(18, 24, 18, 110),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: child,
        ),
      ),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.bgApp,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              location: location,
              business: business,
              businessName: business?.displayName ?? '',
              logoUrl: business?.logoUrl,
              onLogout: () => _logout(context, ref),
              onItemTap: onItemTap,
            ),
            Expanded(child: SingleChildScrollView(child: main)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SingleChildScrollView(child: main),
      bottomNavigationBar: _TabBar(location: location, business: business, onItemTap: onItemTap),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.location,
    required this.business,
    required this.businessName,
    this.logoUrl,
    required this.onLogout,
    required this.onItemTap,
  });
  final String location;
  final Business? business;
  final String businessName;
  final String? logoUrl;
  final VoidCallback onLogout;
  final ValueChanged<_NavItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.ink900,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
            child: Row(
              children: [
                _BrandMark(logoUrl: logoUrl, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(businessName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('loyalty manager', style: AppTypography.xs2.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final item in _navItems)
            _SidebarButton(
              item: item,
              active: location == item.location,
              enabled: item.isEnabled?.call(business) ?? true,
              onTap: () => onItemTap(item),
            ),
          const Spacer(),
          _SidebarButton(
            item: const _NavItem('', Icons.logout_rounded, 'log out', 'log out'),
            active: false,
            onTap: onLogout,
            mutedIcon: true,
          ),
        ],
      ),
    );
  }
}

/// The sidebar's business identity mark — the uploaded logo (Settings)
/// once set, falling back to the generic brand coin until then.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.logoUrl, required this.size});
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    if (url == null || url.isEmpty) return Coin(symbol: 'H', size: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceInput,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({required this.item, required this.active, this.onTap, this.mutedIcon = false, this.enabled = true});
  final _NavItem item;
  final bool active;
  final VoidCallback? onTap;
  final bool mutedIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textDisabled
        : active
            ? AppColors.mint400
            : (mutedIcon ? AppColors.textTertiary : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.surfaceHover : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap ?? () => context.go(item.location),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 19, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.label, style: AppTypography.sm.copyWith(color: color, fontWeight: FontWeight.w700)),
                ),
                if (!enabled) const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.location, required this.business, required this.onItemTap});
  final String location;
  final Business? business;
  final ValueChanged<_NavItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.glassFill,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              for (final item in _navItems)
                Builder(builder: (context) {
                  final enabled = item.isEnabled?.call(business) ?? true;
                  final color = !enabled
                      ? AppColors.textDisabled
                      : (location == item.location ? AppColors.mint400 : AppColors.textTertiary);
                  return Expanded(
                    child: InkWell(
                      onTap: () => onItemTap(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon, size: 20, color: color),
                            const SizedBox(height: 3),
                            Text(item.tabLabel, style: AppTypography.xs2.copyWith(fontSize: 10, color: color)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
