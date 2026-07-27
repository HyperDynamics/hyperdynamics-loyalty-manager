import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/utils/formatters.dart';

void main() {
  group('digitsOnly', () {
    test('strips non-digit characters', () {
      expect(digitsOnly('98765 43210'), '9876543210');
      expect(digitsOnly('+91-98765-43210'), '919876543210');
      expect(digitsOnly(''), '');
    });
  });

  group('maskPhone', () {
    test('keeps first 5 digits, masks the rest', () {
      expect(maskPhone('9876543210'), '98765XXXXX');
    });

    test('returns raw digits unmasked when under 5 digits', () {
      expect(maskPhone('987'), '987');
    });

    test('strips formatting before masking', () {
      expect(maskPhone('98765-43210'), '98765XXXXX');
    });
  });

  group('formatInr', () {
    test('applies Indian digit grouping', () {
      expect(formatInr(450), '₹450');
      expect(formatInr(123456), '₹1,23,456');
    });
  });

  group('pointsForAmount', () {
    test('floors amount / ratio, matching the server-side calculation', () {
      expect(pointsForAmount(450, 10), 45);
      expect(pointsForAmount(455, 10), 45);
      expect(pointsForAmount(9, 10), 0);
    });

    test('returns 0 for a non-positive ratio instead of throwing', () {
      expect(pointsForAmount(450, 0), 0);
      expect(pointsForAmount(450, -5), 0);
    });
  });

  group('relativeTimeLabel', () {
    test('labels a moment today as "today"', () {
      final label = relativeTimeLabel(DateTime.now().subtract(const Duration(minutes: 5)));
      expect(label, startsWith('today · '));
    });

    test('labels a moment 25 hours ago as "yesterday"', () {
      final label = relativeTimeLabel(DateTime.now().subtract(const Duration(hours: 25)));
      expect(label, startsWith('yesterday · '));
    });
  });
}
