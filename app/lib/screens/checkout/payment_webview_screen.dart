import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

/// Result of a payment attempt, decided by inspecting the redirect the
/// gateway sends back to `env.clientUrl + /payment/result` (see
/// src/controllers/payment.controller.ts#esewaSuccess / khaltiCallback on
/// the backend, which always redirects there with `?status=success|failed`).
enum PaymentOutcome { success, failed, cancelled }

/// Hosts the eSewa/Khalti checkout page in a WebView and reports back once
/// the gateway redirects to `/payment/result`.
///
/// - eSewa (v2 ePay) requires a signed HTML form POSTed to `formUrl` — a
///   plain link/GET won't work, so we build that form ourselves and load it
///   with `loadHtmlString`, auto-submitting on page load.
/// - Khalti already gives us a direct `paymentUrl` to open with a GET.
class PaymentWebViewScreen extends StatefulWidget {
  final PaymentInitiationResult payment;
  const PaymentWebViewScreen({super.key, required this.payment});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          if (request.url.contains('/payment/result')) {
            _handleResult(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _load();
  }

  void _load() {
    final p = widget.payment;
    if (p.method == 'esewa' && p.formUrl != null && p.formFields != null) {
      _controller
          .loadHtmlString(_esewaAutoSubmitHtml(p.formUrl!, p.formFields!));
    } else if (p.paymentUrl != null) {
      _controller.loadRequest(Uri.parse(p.paymentUrl!));
    } else {
      // Nothing usable to show (e.g. backend didn't return a URL) — bail out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_resolved) {
          _resolved = true;
          Navigator.of(context).pop(PaymentOutcome.failed);
        }
      });
    }
  }

  void _handleResult(String url) {
    if (_resolved) return;
    _resolved = true;
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];
    final outcome =
        status == 'success' ? PaymentOutcome.success : PaymentOutcome.failed;
    Navigator.of(context).pop(outcome);
  }

  String _esewaAutoSubmitHtml(String formUrl, Map<String, dynamic> fields) {
    final inputs = fields.entries
        .map((e) =>
            '<input type="hidden" name="${_escape(e.key)}" value="${_escape(e.value.toString())}">')
        .join();
    return '''
<!DOCTYPE html>
<html>
  <body onload="document.forms[0].submit()">
    <form action="${_escape(formUrl)}" method="POST">
      $inputs
    </form>
  </body>
</html>
''';
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && !_resolved) {
          _resolved = true;
          Navigator.of(context).pop(PaymentOutcome.cancelled);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.payment.method == 'esewa' ? 'eSewa' : 'Khalti'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (!_resolved) {
                _resolved = true;
                Navigator.of(context).pop(PaymentOutcome.cancelled);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}
