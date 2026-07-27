import 'package:intl/intl.dart';

final _inrFormat = NumberFormat.decimalPattern('en_IN');

/// Strips everything but digits — every phone/amount input in the app is
/// digits-only, matching the prototype's `this.digits()`.
String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

/// First 5 digits + `XXXXX`, e.g. `9876543210` -> `98765XXXXX`.
/// Matches the prototype's `this.mask()` — used anywhere a phone number is
/// displayed, per the spec's privacy requirement.
String maskPhone(String phone) {
  final d = digitsOnly(phone);
  if (d.length < 5) return d;
  return '${d.substring(0, 5)}XXXXX';
}

/// `₹1,23,456` (Indian digit grouping), matching the prototype's `this.inr()`.
String formatInr(num amount) => '₹${_inrFormat.format(amount)}';

/// Points earned for a bill amount at the business's configured ratio
/// (₹[ratio] spent = 1 point), floored — matches the prototype's `this.pts()`.
int pointsForAmount(num amount, num ratio) {
  if (ratio <= 0) return 0;
  return (amount / ratio).floor();
}

final _timeFormat = DateFormat('h:mm a');
final _dateFormat = DateFormat('MMM d');

/// `today · 2:14 pm` / `yesterday · 7:30 pm` / `mar 12 · 3:00 pm`, matching
/// the prototype's mock activity timestamps.
String relativeTimeLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final diffDays = today.difference(that).inDays;

  final day = diffDays == 0 ? 'today' : (diffDays == 1 ? 'yesterday' : _dateFormat.format(dt));
  return '${day.toLowerCase()} · ${_timeFormat.format(dt).toLowerCase()}';
}
