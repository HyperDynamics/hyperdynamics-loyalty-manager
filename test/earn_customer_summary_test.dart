import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/features/earn/customer_summary.dart';
import 'package:loyalty_manager/models/customer.dart';

void main() {
  group('customerLookupFor', () {
    test('idle below ten digits, regardless of what the stream says', () {
      expect(customerLookupFor(phoneLength: 0, lookingUp: false, customerExists: false), CustomerLookup.idle);
      expect(customerLookupFor(phoneLength: 9, lookingUp: true, customerExists: true), CustomerLookup.idle);
    });

    test('checking while the lookup is in flight', () {
      expect(customerLookupFor(phoneLength: 10, lookingUp: true, customerExists: false), CustomerLookup.checking);
    });

    test('found vs new once the lookup settles', () {
      expect(customerLookupFor(phoneLength: 10, lookingUp: false, customerExists: true), CustomerLookup.found);
      expect(customerLookupFor(phoneLength: 10, lookingUp: false, customerExists: false), CustomerLookup.newCustomer);
    });
  });

  group('onFileDisplayName', () {
    test('returns a real stored name', () {
      expect(onFileDisplayName(const Customer(phone: '9', name: 'arul', balance: 0)), 'arul');
    });

    test("filters out Customer.fromMap's 'customer' fallback", () {
      // A record saved with no name reads back as the literal 'customer';
      // echoing that would look like we knew them by name.
      expect(onFileDisplayName(const Customer(phone: '9', name: 'customer', balance: 0)), isNull);
      expect(onFileDisplayName(Customer.fromMap('9', const {})), isNull);
    });

    test('treats blank and whitespace-only names as absent, and trims', () {
      expect(onFileDisplayName(const Customer(phone: '9', name: '', balance: 0)), isNull);
      expect(onFileDisplayName(const Customer(phone: '9', name: '   ', balance: 0)), isNull);
      expect(onFileDisplayName(const Customer(phone: '9', name: '  arul  ', balance: 0)), 'arul');
    });

    test('null customer has no name', () {
      expect(onFileDisplayName(null), isNull);
    });
  });
}
