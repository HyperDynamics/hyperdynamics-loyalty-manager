import '../../models/customer.dart';

/// What the Earn screen knows about the number currently typed in.
///
/// Pure, so the decision table is unit-testable without a Firestore stream.
enum CustomerLookup {
  /// Fewer than 10 digits — nothing to look up yet.
  idle,

  /// 10 digits typed, the customer doc hasn't come back.
  checking,

  /// No customer doc: they'll be created when this earn is posted.
  newCustomer,

  /// Existing customer — show who they are and what they hold.
  found,
}

CustomerLookup customerLookupFor({
  required int phoneLength,
  required bool lookingUp,
  required bool customerExists,
}) {
  if (phoneLength < 10) return CustomerLookup.idle;
  if (lookingUp) return CustomerLookup.checking;
  return customerExists ? CustomerLookup.found : CustomerLookup.newCustomer;
}

/// The customer's real name, or null when we don't actually have one.
///
/// `Customer.fromMap` falls back to the literal string `'customer'` when the
/// record has no name, so that placeholder has to be filtered out here —
/// echoing it back would read as though we knew them by name when we don't.
String? onFileDisplayName(Customer? customer) {
  final name = customer?.name.trim();
  if (name == null || name.isEmpty || name == 'customer') return null;
  return name;
}
