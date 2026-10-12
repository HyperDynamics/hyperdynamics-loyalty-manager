import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/features/earn/earn_screen.dart';
import 'package:loyalty_manager/models/customer.dart';
import 'package:loyalty_manager/providers/business_providers.dart';
import 'package:loyalty_manager/providers/ledger_providers.dart';

const _phone = '9876543210';

/// Pumps the Earn screen with the customer lookup for [_phone] stubbed out.
/// `currentBusinessProvider` yields null — the screen falls back to its
/// defaults (ratio 10, bill number required), which is enough for this flow.
Future<void> _pumpEarn(WidgetTester tester, Customer? customer) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentBusinessProvider.overrideWith((ref) => Stream.value(null)),
        customerWatchProvider(_phone).overrideWith((ref) => Stream.value(customer)),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: EarnScreen()))),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _typePhone(WidgetTester tester, String digits) async {
  await tester.enterText(find.byType(TextField).first, digits);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('auto-fills the stored birthday once the number is recognised', (tester) async {
    await _pumpEarn(
      tester,
      const Customer(phone: _phone, name: 'arul', balance: 120, dob: '1990-04-17'),
    );

    // Before the number is complete there is nothing to show.
    expect(find.text('17 Apr 1990'), findsNothing);
    expect(find.text('helps power birthday rewards'), findsOneWidget);

    await _typePhone(tester, _phone);

    // The stored birthday is now displayed without anyone being asked for it.
    expect(find.text('17 Apr 1990'), findsOneWidget);
    expect(find.text('date of birth · on file'), findsOneWidget);
    expect(find.text('change'), findsOneWidget);
    // And the operator is not prompted to supply one.
    expect(find.text('no birthday on file — add one'), findsNothing);
    expect(find.text('new customer — add their birthday'), findsNothing);
  });

  testWidgets('asks for a birthday when the known customer has none', (tester) async {
    await _pumpEarn(tester, const Customer(phone: _phone, name: 'arul', balance: 120));
    await _typePhone(tester, _phone);

    expect(find.text('no birthday on file — add one'), findsOneWidget);
    expect(find.text('date of birth · on file'), findsNothing);
  });

  testWidgets('asks for a birthday when the number is unknown', (tester) async {
    await _pumpEarn(tester, null);
    await _typePhone(tester, _phone);

    expect(find.text('new customer — add their birthday'), findsOneWidget);
  });

  testWidgets('a stored birthday is dropped again if the number is edited', (tester) async {
    await _pumpEarn(
      tester,
      const Customer(phone: _phone, name: 'arul', balance: 120, dob: '1990-04-17'),
    );
    await _typePhone(tester, _phone);
    expect(find.text('17 Apr 1990'), findsOneWidget);

    // Backspace one digit: the number no longer identifies that customer.
    await _typePhone(tester, '987654321');
    expect(find.text('17 Apr 1990'), findsNothing);
  });

  testWidgets('shows a returning customer their name and point balance', (tester) async {
    await _pumpEarn(
      tester,
      const Customer(phone: _phone, name: 'arul', balance: 1240, dob: '1990-04-17'),
    );

    // Nothing claimed before the number is complete.
    expect(find.text('arul'), findsNothing);
    expect(find.text('1240 pts'), findsNothing);

    await _typePhone(tester, _phone);

    // Twice on purpose: once in the summary strip, once as the name field's
    // placeholder — so the till sees who it is whichever it looks at.
    expect(find.text('arul'), findsNWidgets(2));
    expect(find.text('1240 pts'), findsOneWidget);
    expect(find.text('current balance'), findsOneWidget);
    // The name is offered as the field's placeholder, not filled in, so
    // earnCredit omits `name` and the server keeps what it already has.
    expect(find.text('customer name · on file'), findsOneWidget);
  });

  testWidgets('announces an unknown number as a new customer', (tester) async {
    await _pumpEarn(tester, null);
    await _typePhone(tester, _phone);

    expect(find.text('new customer'), findsOneWidget);
    expect(find.text("they'll be created when you post this earn"), findsOneWidget);
    expect(find.text('current balance'), findsNothing);
  });

  testWidgets('falls back to the masked number when the record has no name', (tester) async {
    // Customer.fromMap stores the literal 'customer' for a nameless record;
    // showing that back would read as a real name.
    await _pumpEarn(tester, const Customer(phone: _phone, name: 'customer', balance: 80));
    await _typePhone(tester, _phone);

    expect(find.text('customer'), findsNothing);
    expect(find.text('80 pts'), findsOneWidget);
    expect(find.text('customer name · on file'), findsNothing);
  });

  testWidgets('a long name is ellipsised rather than wrapping the strip', (tester) async {
    await _pumpEarn(
      tester,
      const Customer(
        phone: _phone,
        name: 'a very long customer name that would otherwise wrap the row',
        balance: 55,
      ),
    );
    await _typePhone(tester, _phone);

    final strip = tester.widget<Text>(
      find.text('a very long customer name that would otherwise wrap the row').first,
    );
    expect(strip.maxLines, 1);
    expect(strip.overflow, TextOverflow.ellipsis);
    expect(find.text('55 pts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
