import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/purchase.dart';
import 'package:warmmemo/data/services/payment_service.dart';

void main() {
  Purchase order({
    String? id = 'order_42',
    String provider = 'stripe',
    String invoiceId = 'hosted_order_42',
    int amount = 120000,
  }) => Purchase(
    id: id,
    planName: '城市極簡告別',
    priceLabel: 'NT\$ 120,000',
    priceAmount: amount,
    status: 'pending',
    paymentProvider: provider,
    invoiceId: invoiceId,
    checkoutUrl: 'https://buy.stripe.com/previous',
  );

  final paymentService = PaymentService(
    paymentLink120000: 'https://buy.stripe.com/configured?locale=zh-TW',
  );

  test('admin uses configured Stripe link and the actual order ID', () {
    final uri = paymentService.hostedCheckoutResendUri(order());
    expect(
      uri,
      Uri.parse(
        'https://buy.stripe.com/configured?locale=zh-TW&client_reference_id=order_42',
      ),
    );
  });

  test('admin leaves legacy and unsupported orders for manual handling', () {
    for (final unsupported in [
      order(id: null),
      order(provider: 'linepay'),
      order(invoiceId: 'in_legacy'),
      order(invoiceId: 'hosted_order_17'),
      order(amount: 1),
    ]) {
      expect(paymentService.hostedCheckoutResendUri(unsupported), isNull);
    }
    expect(
      PaymentService(paymentLink120000: '').hostedCheckoutResendUri(order()),
      isNull,
    );
  });
}
