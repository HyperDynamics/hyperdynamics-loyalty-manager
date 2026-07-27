import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Plain `/payment/confirm` URLs (no `#`) — Razorpay's callback_url and the
/// emailed login link both assume path-based routing.
void configureUrlStrategy() => usePathUrlStrategy();
