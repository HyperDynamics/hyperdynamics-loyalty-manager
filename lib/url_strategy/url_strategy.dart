// Conditional-import shim so `package:flutter_web_plugins` (and its
// `dart:ui_web` usage) is only ever part of the *web* compilation unit.
// Importing it directly from main.dart and guarding the call with a
// runtime `kIsWeb` check is not enough — the non-web target still has to
// compile the import, which breaks the iOS/Android build.
export 'url_strategy_stub.dart' if (dart.library.js_interop) 'url_strategy_web.dart';
