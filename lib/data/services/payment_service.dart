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

  Future<PaymentResult> createInvoice({
    required String email,
    required String name,
    required int amountCents,
    required String description,
    required PaymentProvider provider,
    String currency = 'twd',
  }) async {
    final user = AuthService.instance.currentUser;
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      throw StateError('使用者尚未驗證，無法建立發票。');
    }

    final response = await _client.post(
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
    );

    if (response.statusCode >= 400) {
      throw StateError(
        '建立發票失敗：${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final invoiceId = body['invoiceId'] as String?;
    final checkoutUrl = body['checkoutUrl'] as String?;
    final providerName = body['provider'] as String?;

    if (invoiceId == null || checkoutUrl == null || providerName == null) {
      throw StateError('後端未回傳完整發票資訊。');
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
}
