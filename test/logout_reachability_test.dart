import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/features/shell/app_shell.dart';

void main() {
  group('needsLogoutTab', () {
    test('owners reach log out through settings, so the tab bar needs none', () {
      expect(
        needsLogoutTab(const [
          '/app/dashboard',
          '/app/earn',
          '/app/redeem',
          '/app/customers',
          '/app/birthdays',
          '/app/correction',
          settingsLocation,
        ]),
        isFalse,
      );
    });

    test('staff cannot reach settings, so the tab bar must carry log out', () {
      // The regression: on a narrow viewport the sidebar isn't rendered, so
      // without this cell a staff account had no way to sign out at all.
      expect(
        needsLogoutTab(const ['/app/dashboard', '/app/earn', '/app/redeem', '/app/correction']),
        isTrue,
      );
    });

    test('holds for a maximally restricted staff account', () {
      expect(needsLogoutTab(const ['/app/dashboard']), isTrue);
      expect(needsLogoutTab(const <String>[]), isTrue);
    });

    test('turns itself off again if settings ever becomes staff-reachable', () {
      // Guards the rule rather than the role: if someone later grants staff a
      // settings tab, the duplicate log-out cell disappears on its own.
      expect(needsLogoutTab(const ['/app/earn', settingsLocation]), isFalse);
    });
  });
}
