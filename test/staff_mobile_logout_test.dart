import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/features/shell/app_shell.dart';
import 'package:loyalty_manager/models/business.dart';
import 'package:loyalty_manager/providers/auth_providers.dart';
import 'package:loyalty_manager/providers/business_providers.dart';

/// Only `isOwner` is read off the session by the shell, so a noSuchMethod
/// stub is enough standing in for a real Firebase user.
class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSessionNotifier extends AuthSessionNotifier {
  _FakeSessionNotifier(this.role);
  final BusinessRole role;
  @override
  Future<AuthSession?> build() async =>
      AuthSession(user: _FakeUser(), businessId: 'demo', role: role);
}

final _business = Business(
  id: 'demo',
  displayName: 'demo store',
  pointsRatio: 10,
  otpEnabled: false,
  gateway: OtpGateway.values.first,
  ownerEmail: 'owner@example.com',
  status: 'active',
  birthdayEnabled: true,
  whatsappEnabled: false,
  exportEnabled: false,
  // Every permission on — the widest staff nav, i.e. the most crowded tab bar.
  staffPermissions: const StaffPermissions(
    earn: true, redeem: true, correction: true,
    customers: true, birthdays: true, export: true, sales: true,
  ),
);

/// 390x844 — iPhone-ish, comfortably under the 860 wide breakpoint, so the
/// sidebar is NOT rendered and only the bottom tab bar is on screen.
Future<void> _pumpMobileShell(WidgetTester tester, BusinessRole role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentBusinessProvider.overrideWith((ref) => Stream.value(_business)),
        authSessionProvider.overrideWith(() => _FakeSessionNotifier(role)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: const AppShell(location: '/app/earn', child: SizedBox.shrink()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('staff on mobile get a log out button', (tester) async {
    await _pumpMobileShell(tester, BusinessRole.staff);

    expect(find.text('logout'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    // The sidebar (the other log-out surface) must not be on screen at all.
    expect(find.text('loyalty manager'), findsNothing);
    // And settings — the owner's route to log out — is correctly hidden.
    expect(find.text('settings'), findsNothing);
  });

  testWidgets('owners on mobile reach log out via settings, with no duplicate cell', (tester) async {
    await _pumpMobileShell(tester, BusinessRole.owner);

    expect(find.text('settings'), findsOneWidget);
    expect(find.text('logout'), findsNothing);
  });

  testWidgets('the fullest staff tab bar still lays out without overflow', (tester) async {
    await _pumpMobileShell(tester, BusinessRole.staff);
    // pumpAndSettle would already have thrown on a RenderFlex overflow, but be
    // explicit: every staff tab plus log out is actually on screen.
    for (final label in ['home', 'earn', 'redeem', 'customers', 'birthdays', 'fix', 'logout']) {
      expect(find.text(label), findsOneWidget, reason: 'missing tab: $label');
    }
    expect(tester.takeException(), isNull);
  });
}
