import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/widgets/app_button.dart';

void main() {
  testWidgets('AppButton fires onPressed when enabled, not when disabled', (tester) async {
    var tapped = false;

    Future<void> pump(VoidCallback? onPressed) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(label: 'credit points', onPressed: onPressed),
            ),
          ),
        );

    await pump(() => tapped = true);
    await tester.tap(find.text('credit points'));
    expect(tapped, isTrue);

    tapped = false;
    await pump(null);
    await tester.tap(find.text('credit points'));
    expect(tapped, isFalse);
  });
}
