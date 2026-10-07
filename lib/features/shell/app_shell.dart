import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/business.dart';
import '../../providers/auth_providers.dart';
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
  const _NavItem(this.location, this.icon, this.label, this.tabLabel, {this.isEnabled, this.staffPermission});
  final String location;
  final IconData icon;
  final String label;
  final String tabLabel;

  /// Null means always enabled. Used for add-on features (e.g. birthdays)
  /// that are only available once admin turns them on for this business —
  /// the item still renders (as the upsell surface) but is disabled.
  final bool Function(Business? business)? isEnabled;

  /// Which staff permission this screen needs, or null for owner-only screens
  /// (settings). Unlike [isEnabled], failing this **hides** the item rather
  /// than disabling it: an add-on the business hasn't bought is an upsell worth
  /// showing, but a permission their owner withheld is not something staff
  /// should be invited to ask about.
  final bool Function(StaffPermissions permissions)? staffPermission;
}

const _navItems = [
  _NavItem('/app/dashboard', Icons.home_rounded, 'home', 'home', staffPermission: _always),
  _NavItem('/app/earn', Icons.add_circle_outline_rounded, 'earn', 'earn', staffPermission: _canEarn),
  _NavItem('/app/redeem', Icons.star_outline_rounded, 'redeem', 'redeem', staffPermission: _canRedeem),
  _NavItem('/app/customers', Icons.groups_outlined, 'customers', 'customers', staffPermission: _canCustomers),
  _NavItem('/app/birthdays', Icons.cake_outlined, 'birthdays', 'birthdays',
      isEnabled: _birthdaysEnabled, staffPermission: _canBirthdays),
  _NavItem('/app/correction', Icons.history_rounded, 'history & correction', 'fix', staffPermission: _canCorrect),
  // No staffPermission ⇒ owner-only.
  _NavItem(settingsLocation, Icons.settings_outlined, 'settings', 'settings'),
];

const settingsLocation = '/app/settings';

/// Whether the bottom tab bar has to carry its own log-out cell.
///
/// On narrow viewports the sidebar — which holds the only standing log-out
/// button — isn't rendered, so the settings screen's button is the sole way
/// out. Staff can't open settings, which left them with no way to sign out at
/// all. Keyed off whether settings is actually reachable rather than off the
/// role directly, so the rule keeps holding if the nav ever changes: grant
/// staff a settings tab and this turns itself off again.
bool needsLogoutTab(Iterable<String> visibleLocations) => !visibleLocations.contains(settingsLocation);

bool _birthdaysEnabled(Business? business) => business?.birthdayEnabled ?? false;

bool _always(StaffPermissions p) => true;
bool _canEarn(StaffPermissions p) => p.earn;
bool _canRedeem(StaffPermissions p) => p.redeem;
bool _canCustomers(StaffPermissions p) => p.customers;
bool _canBirthdays(StaffPermissions p) => p.birthdays;
bool _canCorrect(StaffPermissions p) => p.correction;

/// The nav items this account may see. Owners see everything; staff see only
/// what their business's single staff policy allows. Mirrored by the router's
/// redirect (`router.dart`) so a typed-in URL can't bypass it, and by the
/// callables themselves, which are the actual security boundary.
List<_NavItem> _visibleNavItems(Business? business, bool isOwner) {
  if (isOwner) return _navItems;
  final permissions = business?.staffPermissions ?? StaffPermissions.defaults;
  return _navItems.where((i) => i.staffPermission?.call(permissions) ?? false).toList();
}

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
    final isOwner = ref.watch(authSessionProvider).value?.isOwner ?? true;
    final items = _visibleNavItems(business, isOwner);
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
              items: items,
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
      bottomNavigationBar: _TabBar(
        location: location,
        business: business,
        items: items,
        onItemTap: onItemTap,
        showLogout: needsLogoutTab(items.map((i) => i.location)),
        onLogout: () => _logout(context, ref),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.location,
    required this.business,
    required this.items,
    required this.businessName,
    this.logoUrl,
    required this.onLogout,
    required this.onItemTap,
  });
  final String location;
  final Business? business;
  final List<_NavItem> items;
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
          for (final item in items)
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
  const _TabBar({
    required this.location,
    required this.business,
    required this.items,
    required this.onItemTap,
    this.showLogout = false,
    this.onLogout,
  });
  final String location;
  final Business? business;
  final List<_NavItem> items;
  final ValueChanged<_NavItem> onItemTap;

  /// Whether to append a log-out cell. Set for accounts that can't reach the
  /// settings screen (staff), who would otherwise be stranded on narrow
  /// viewports — the sidebar's log-out button never renders there.
  final bool showLogout;
  final VoidCallback? onLogout;

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
              for (final item in items)
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
              if (showLogout)
                Expanded(
                  child: InkWell(
                    onTap: onLogout,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded, size: 20, color: AppColors.textTertiary),
                          const SizedBox(height: 3),
                          Text('log out',
                              style: AppTypography.xs2.copyWith(fontSize: 10, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
