import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_colors.dart';

/// Mobile-only: hosts Razorpay's real checkout page in an in-app browser
/// (the payment UI itself is Razorpay's, not embedded/re-implemented — this
/// just avoids needing universal-links/app-links config to catch the
/// redirect back into the app). Pops with the callback URL once navigation
/// reaches our `/payment/confirm` route.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (url.contains('/payment/confirm')) {
              Navigator.of(context).pop(url);
              return;
            }
            setState(() => _loading = true);
          },
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.ink900,
        title: const Text('complete payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(color: AppColors.mint400, minHeight: 2),
        ],
      ),
    );
  }
}
