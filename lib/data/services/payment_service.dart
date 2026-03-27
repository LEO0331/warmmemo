import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../firebase/auth_service.dart';

enum PaymentProvider {
  stripe,
  ecpay,
}

class PaymentResult {
  const PaymentResult({
    required this.provider,
    required this.invoiceId,
    required this.checkoutUrl,
  });

  final PaymentProvider provider;
  final String invoiceId;
  final String checkoutUrl;
}

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final http.Client _client = http.Client();

  static const _defaultBackend =
      'https://asia-east1-warmmemo-1a485.cloudfunctions.net';
  static const _backendHost =
      String.fromEnvironment('WARMEMO_PAYMENT_BACKEND_URL', defaultValue: _defaultBackend);
  static const _functionName =
      String.fromEnvironment('WARMEMO_PAYMENT_FUNCTION', defaultValue: 'createInvoice');
  static const _useHostedPaymentLinks =
      bool.fromEnvironment('WARMEMO_USE_HOSTED_PAYMENT_LINKS', defaultValue: false);
  static const _paymentLink120000 =
      String.fromEnvironment('STRIPE_PAYMENT_LINK_120000', defaultValue: '');
  static const _paymentLink150000 =
      String.fromEnvironment('STRIPE_PAYMENT_LINK_150000', defaultValue: '');
  static const _paymentLink220000 =
      String.fromEnvironment('STRIPE_PAYMENT_LINK_220000', defaultValue: '');

  Future<PaymentResult> createInvoice({
    required String email,
    required String name,
    required int amountCents,
    required String description,
    required PaymentProvider provider,
    String currency = 'twd',
  }) async {
    if (_useHostedPaymentLinks) {
      final url = _resolveHostedPaymentLink(amountCents: amountCents);
      if (url == null) {
        throw StateError('尚未設定此方案的 Stripe Payment Link。');
      }
      final hosted = Uri.tryParse(url);
      if (hosted == null || !(hosted.isScheme('https') || hosted.isScheme('http'))) {
        throw StateError('Payment Link 格式錯誤，請確認以 https:// 開頭。');
      }
      return PaymentResult(
        provider: PaymentProvider.stripe,
        invoiceId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        checkoutUrl: url,
      );
    }

    final user = AuthService.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      throw StateError('使用者尚未驗證，無法建立付款資訊。');
    }

    final response = await _client
        .post(
          Uri.parse('$_backendHost/$_functionName'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $idToken',
          },
          body: jsonEncode({
            'email': email,
            'name': name,
            'amountCents': amountCents,
            'description': description,
            'currency': currency,
            'provider': provider.name,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) {
      String backendCode = 'unknown';
      String backendError = response.body;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        backendCode = body['code'] as String? ?? backendCode;
        backendError = body['error'] as String? ?? backendError;
      } catch (_) {
        // Keep default code when backend body is not JSON.
      }
      throw StateError(
        '建立付款資訊失敗（$backendCode，HTTP ${response.statusCode}）：$backendError',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final invoiceId = body['invoiceId'] as String?;
    final checkoutUrl = body['checkoutUrl'] as String?;
    final providerName = body['provider'] as String?;

    if (invoiceId == null || checkoutUrl == null || providerName == null) {
      throw StateError('後端未回傳完整付款資訊。');
    }
    final parsed = Uri.tryParse(checkoutUrl);
    if (parsed == null || !(parsed.isScheme('https') || parsed.isScheme('http'))) {
      throw StateError('後端回傳的 checkoutUrl 無效：$checkoutUrl');
    }

    final providerValue = PaymentProvider.values.firstWhere(
      (item) => item.name == providerName,
      orElse: () => PaymentProvider.stripe,
    );

    return PaymentResult(
      provider: providerValue,
      invoiceId: invoiceId,
      checkoutUrl: checkoutUrl,
    );
  }

  String? _resolveHostedPaymentLink({required int amountCents}) {
    // 目前專案方案以整數金額（分）對應固定 Payment Link
    switch (amountCents) {
      case 120000:
        return _paymentLink120000.isEmpty ? null : _paymentLink120000;
      case 150000:
        return _paymentLink150000.isEmpty ? null : _paymentLink150000;
      case 220000:
        return _paymentLink220000.isEmpty ? null : _paymentLink220000;
      default:
        return null;
    }
  }
}
