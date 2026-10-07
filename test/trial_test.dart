import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/models/admin_business_summary.dart';
import 'package:loyalty_manager/models/business.dart';

Business _business(Map<String, dynamic> overrides) =>
    Business.fromMap('demo', {'displayName': 'demo store', ...overrides});

AdminBusinessSummary _summary(Map<String, dynamic> overrides) =>
    AdminBusinessSummary.fromMap({'businessId': 'demo', 'displayName': 'demo store', ...overrides});

void main() {
  group('Business trial state', () {
    test('defaults to not-a-trial when the field is absent', () {
      // Every business provisioned before trials shipped has no isTrial field;
      // defaulting the other way would label the whole book of business a trial.
      expect(_business({}).isTrial, isFalse);
      expect(_business({}).trialDaysRemaining, isNull);
    });

    test('reads isTrial when present', () {
      expect(_business({'isTrial': true}).isTrial, isTrue);
    });

    test('copyWith preserves isTrial', () {
      // Settings edits go through copyWith; dropping the flag there would make
      // a trial business momentarily look like a paying one.
      final trial = _business({'isTrial': true});
      expect(trial.copyWith(displayName: 'renamed').isTrial, isTrue);
      expect(trial.copyWith(pointsRatio: 20).isTrial, isTrue);
    });

    test('trialDaysRemaining counts whole days up', () {
      final b = Business.fromMap('demo', {
        'isTrial': true,
        'subscriptionRenewsAt': null,
      });
      // No end date => nothing to count.
      expect(b.trialDaysRemaining, isNull);
    });

    test('trialDaysRemaining is null for a paid subscription', () {
      final paid = _business({'isTrial': false});
      expect(paid.trialDaysRemaining, isNull);
    });
  });

  group('AdminBusinessSummary trial state', () {
    test('defaults false, reads true', () {
      expect(_summary({}).isTrial, isFalse);
      expect(_summary({'isTrial': true}).isTrial, isTrue);
    });

    test('counts days left and floors an expired trial at zero', () {
      final ends = DateTime.now().add(const Duration(days: 9, hours: 2));
      final live = _summary({'isTrial': true, 'subscriptionRenewsAt': ends.toIso8601String()});
      expect(live.trialDaysRemaining, 10); // partial day rounds up
      expect(live.subscriptionLapsed, isFalse);

      final past = DateTime.now().subtract(const Duration(days: 3));
      final dead = _summary({'isTrial': true, 'subscriptionRenewsAt': past.toIso8601String()});
      expect(dead.trialDaysRemaining, 0, reason: 'never report negative days left');
      expect(dead.subscriptionLapsed, isTrue);
    });

    test('an expired trial lapses exactly like an expired subscription', () {
      // The lockout deliberately rides on subscriptionLapsed, so no scheduled
      // job has to fire for a trial to stop working.
      final past = DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String();
      expect(_summary({'isTrial': true, 'subscriptionRenewsAt': past}).subscriptionLapsed, isTrue);
      expect(_summary({'isTrial': false, 'subscriptionRenewsAt': past}).subscriptionLapsed, isTrue);
    });
  });
}
