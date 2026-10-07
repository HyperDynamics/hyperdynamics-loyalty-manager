import 'package:flutter_test/flutter_test.dart';
import 'package:loyalty_manager/features/earn/dob_field_state.dart';

/// Convenience wrapper so each case reads as the situation it describes.
DobFieldState stateFor({
  int phoneLength = 10,
  bool lookingUp = false,
  bool customerExists = false,
  bool hasOnFileDob = false,
  bool hasPickedDob = false,
}) =>
    dobFieldStateFor(
      phoneLength: phoneLength,
      lookingUp: lookingUp,
      customerExists: customerExists,
      hasOnFileDob: hasOnFileDob,
      hasPickedDob: hasPickedDob,
    );

void main() {
  group('dobFieldStateFor', () {
    test('stays idle until the number is 10 digits', () {
      expect(stateFor(phoneLength: 0), DobFieldState.idle);
      expect(stateFor(phoneLength: 9), DobFieldState.idle);
    });

    test('shows checking while the customer doc is in flight', () {
      expect(stateFor(lookingUp: true), DobFieldState.checking);
    });

    test('asks for a birthday when the number is new', () {
      expect(stateFor(customerExists: false), DobFieldState.newCustomer);
    });

    test('asks for a birthday when the customer exists but has none stored', () {
      expect(
        stateFor(customerExists: true, hasOnFileDob: false),
        DobFieldState.missingOnFile,
      );
    });

    test('shows the stored birthday instead of re-asking', () {
      expect(
        stateFor(customerExists: true, hasOnFileDob: true),
        DobFieldState.onFile,
      );
    });

    test('a hand-picked date wins over the stored one', () {
      expect(
        stateFor(customerExists: true, hasOnFileDob: true, hasPickedDob: true),
        DobFieldState.picked,
      );
    });

    test('a hand-picked date survives an incomplete number and a pending lookup', () {
      // The operator picked a date; neither a half-typed number nor an
      // in-flight lookup should blank it out from under them.
      expect(stateFor(phoneLength: 4, hasPickedDob: true), DobFieldState.picked);
      expect(stateFor(lookingUp: true, hasPickedDob: true), DobFieldState.picked);
    });
  });

  group('dobPlaceholderFor', () {
    test('prompts for input in exactly the two states with no birthday', () {
      expect(dobPlaceholderFor(DobFieldState.newCustomer), 'new customer — add their birthday');
      expect(dobPlaceholderFor(DobFieldState.missingOnFile), 'no birthday on file — add one');
    });

    test('states that render a real date carry no placeholder', () {
      expect(dobPlaceholderFor(DobFieldState.onFile), isEmpty);
      expect(dobPlaceholderFor(DobFieldState.picked), isEmpty);
    });

    test('every state has copy defined', () {
      for (final s in DobFieldState.values) {
        expect(() => dobPlaceholderFor(s), returnsNormally);
      }
    });
  });
}
