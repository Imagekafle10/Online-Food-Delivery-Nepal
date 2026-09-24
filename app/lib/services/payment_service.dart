import '../config/api_config.dart';
import 'api_client.dart';

/// Result of POST /api/payments/initiate — shape varies by method
/// (src/controllers/payment.controller.ts + payment.service.ts):
///  - cod: settles immediately, no redirect needed
///  - esewa: { formUrl, formFields } — POST those fields to formUrl (WebView)
///  - khalti: { paymentUrl } — open in WebView / browser
class PaymentInitiationResult {
  final String method;
  final String? formUrl;
  final Map<String, dynamic>? formFields;
  final String? paymentUrl;
  final Map<String, dynamic> raw;

  PaymentInitiationResult({
    required this.method,
    this.formUrl,
    this.formFields,
    this.paymentUrl,
    required this.raw,
  });

  factory PaymentInitiationResult.fromJson(String method, Map<String, dynamic> json) =>
      PaymentInitiationResult(
        method: method,
        formUrl: json['formUrl']?.toString(),
        formFields: json['formFields'] as Map<String, dynamic>?,
        paymentUrl: json['paymentUrl']?.toString(),
        raw: json,
      );
}

class PaymentService {
  final ApiClient _api = ApiClient.instance;

  Future<PaymentInitiationResult> initiate({
    required String referenceType, // 'order' | 'room_booking'
    required int referenceId,
    required String method, // 'esewa' | 'khalti' | 'cod'
  }) async {
    final data = await _api.post(ApiConfig.paymentInitiate, body: {
      'reference_type': referenceType,
      'reference_id': referenceId,
      'method': method,
    });
    return PaymentInitiationResult.fromJson(method, data as Map<String, dynamic>);
  }
}
