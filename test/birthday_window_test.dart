import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/data/ledger_repository.dart';

/// The window is built by walking real `DateTime`s and formatting each as
/// `MM-dd`, specifically so month-end and year-end wrap fall out for free —
/// doing string arithmetic on `MM-dd` would need special cases for both.
void main() {
  group('LedgerRepository.birthdayWindowKeys', () {
    test('a one-day window is just today', () {
      final keys = LedgerRepository.birthdayWindowKeys(1, from: DateTime(2026, 8, 15));
      expect(keys, ['08-15']);
    });

    test('covers today plus the next N-1 days', () {
      final keys = LedgerRepository.birthdayWindowKeys(5, from: DateTime(2026, 8, 15));
      expect(keys, ['08-15', '08-16', '08-17', '08-18', '08-19']);
    });

    test('rolls over a month boundary', () {
      final keys = LedgerRepository.birthdayWindowKeys(4, from: DateTime(2026, 8, 30));
      expect(keys, ['08-30', '08-31', '09-01', '09-02']);
    });

    test('rolls over the year boundary without producing a bogus 12-32', () {
      final keys = LedgerRepository.birthdayWindowKeys(5, from: DateTime(2026, 12, 30));
      expect(keys, ['12-30', '12-31', '01-01', '01-02', '01-03']);
    });

    test('includes 02-29 in a leap year', () {
      final keys = LedgerRepository.birthdayWindowKeys(3, from: DateTime(2028, 2, 28));
      expect(keys, ['02-28', '02-29', '03-01']);
    });

    test('skips 02-29 in a common year', () {
      final keys = LedgerRepository.birthdayWindowKeys(3, from: DateTime(2026, 2, 28));
      expect(keys, ['02-28', '03-01', '03-02']);
    });

    test('clamps to the 1-10 range the settings stepper allows', () {
      // Firestore's whereIn caps at 30 values; clamping here keeps the query
      // legal even if a stored value is out of range.
      expect(LedgerRepository.birthdayWindowKeys(0, from: DateTime(2026, 8, 15)), ['08-15']);
      expect(LedgerRepository.birthdayWindowKeys(99, from: DateTime(2026, 8, 15)).length, 10);
    });
  });
}
