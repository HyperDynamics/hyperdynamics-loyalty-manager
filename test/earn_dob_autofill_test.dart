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
}
