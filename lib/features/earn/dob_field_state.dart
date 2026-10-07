/// What the Earn screen's date-of-birth row should say for the number that is
/// currently typed in.
///
/// Pulled out of the widget as a pure function so the decision table can be
/// unit-tested without a Firestore stream or a pumped widget.
enum DobFieldState {
  /// Fewer than 10 digits typed — nothing to look up yet.
  idle,

  /// 10 digits typed, the customer doc hasn't come back yet.
  checking,

  /// No customer doc for this number: they're new, so ask for a birthday.
  newCustomer,

  /// Customer exists but has no `dob` stored: ask for one.
  missingOnFile,

  /// Customer exists and already has a birthday — show it, don't re-ask.
  onFile,

  /// The operator picked a date by hand this session; it wins over `onFile`
  /// so an explicit correction is always what gets sent.
  picked,
}

DobFieldState dobFieldStateFor({
  required int phoneLength,
  required bool lookingUp,
  required bool customerExists,
  required bool hasOnFileDob,
  required bool hasPickedDob,
}) {
  if (hasPickedDob) return DobFieldState.picked;
  if (phoneLength < 10) return DobFieldState.idle;
  if (lookingUp) return DobFieldState.checking;
  if (!customerExists) return DobFieldState.newCustomer;
  return hasOnFileDob ? DobFieldState.onFile : DobFieldState.missingOnFile;
}

/// Placeholder copy for each state. `onFile`/`picked` render the real date
/// instead, so they have no placeholder of their own.
String dobPlaceholderFor(DobFieldState state) => switch (state) {
      DobFieldState.idle => 'helps power birthday rewards',
      DobFieldState.checking => 'checking…',
      DobFieldState.newCustomer => 'new customer — add their birthday',
      DobFieldState.missingOnFile => 'no birthday on file — add one',
      DobFieldState.onFile || DobFieldState.picked => '',
    };
