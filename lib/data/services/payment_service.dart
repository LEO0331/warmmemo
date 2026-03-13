import 'dart:convert';

import 'package:http/http.dart' as http;


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

  Future<PaymentResult> createInvoice({
    required String email,
    required String name,
    required int amountCents,
    required String description,
    required PaymentProvider provider,
    String currency = 'usd',
  }) async {
    switch (provider) {
      case PaymentProvider.stripe:
        return _createStripeInvoice(
          email: email,
          name: name,
          amountCents: amountCents,
          description: description,
          currency: currency,
        );
      case PaymentProvider.ecpay:
        return _createEcpayInvoice(
          email: email,
          name: name,
          amountCents: amountCents,
          description: description,
        );
    }
  }

  String get _stripeSecretKey => const String.fromEnvironment('STRIPE_SECRET_KEY');

  Future<PaymentResult> _createStripeInvoice({
    required String email,
    required String name,
    required int amountCents,
    required String description,
    required String currency,
  }) async {
    if (_stripeSecretKey.isEmpty) {
      throw UnsupportedError('STRIPE_SECRET_KEY is not configured.');
    }

    final customer = await _post(
      'https://api.stripe.com/v1/customers',
      {
        'email': email,
        'name': name,
        'description': 'WarmMemo client ($email)',
      },
    );
    final customerId = customer['id'] as String? ?? '';
    if (customerId.isEmpty) {
      throw StateError('Unable to create Stripe customer.');
    }

    await _post(
      'https://api.stripe.com/v1/invoiceitems',
      {
        'customer': customerId,
        'unit_amount': amountCents.toString(),
        'currency': currency,
        'quantity': '1',
        'description': description,
      },
    );

    final invoice = await _post(
      'https://api.stripe.com/v1/invoices',
      {
        'customer': customerId,
        'collection_method': 'send_invoice',
        'auto_advance': 'false',
        'description': description,
        'metadata[user_email]': email,
      },
    );

    final invoiceId = invoice['id'] as String? ?? '';
    if (invoiceId.isEmpty) {
      throw StateError('Unable to create Stripe invoice.');
    }

    final finalized = await _post(
      'https://api.stripe.com/v1/invoices/$invoiceId/finalize',
      <String, String>{},
    );

    final url = finalized['hosted_invoice_url'] as String? ??
        finalized['invoice_pdf'] as String? ??
        '';
    if (url.isEmpty) {
      throw StateError('Stripe invoice did not return a URL.');
    }

    return PaymentResult(
      provider: PaymentProvider.stripe,
      invoiceId: invoiceId,
      checkoutUrl: url,
    );
  }

  Future<PaymentResult> _createEcpayInvoice({
    required String email,
    required String name,
    required int amountCents,
    required String description,
  }) {
    throw UnsupportedError(
      '綠界發票尚未實作。請串接綠界後台憑證，或重新指定 Stripe。',
    );
  }

  Future<Map<String, dynamic>> _post(String url, Map<String, String> body) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode >= 400) {
      throw StateError('Stripe API error: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
