import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_webview_screen.dart';

/// External redirect to Razorpay's hosted checkout (never embedded, per
/// spec) — a full-page browser redirect on web, an in-app browser on
/// mobile so we can catch the callback URL without app-link config.
Future<void> launchPaymentCheckout(
  BuildContext context, {
  required String checkoutUrl,
  required String referenceId,
}) async {
  if (kIsWeb) {
    await launchUrl(Uri.parse(checkoutUrl), webOnlyWindowName: '_self');
    return;
  }

  final resultUrl = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(builder: (_) => PaymentWebViewScreen(checkoutUrl: checkoutUrl)),
  );
  if (!context.mounted) return;

  final parsed = resultUrl != null ? Uri.tryParse(resultUrl) : null;
  final ref = parsed?.queryParameters['ref'] ??
      parsed?.queryParameters['razorpay_payment_link_reference_id'] ??
      referenceId;
  context.go('/payment/confirm?ref=$ref');
}
