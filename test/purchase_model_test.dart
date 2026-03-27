import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/purchase.dart';

void main() {
  group('VerificationLog', () {
    test('toMap/fromMap round trip', () {
      final log = VerificationLog(
        actor: 'admin@test.com',
        actedAt: DateTime.parse('2026-03-27T12:00:00.000'),
        summary: 'status pending -> complete',
        fromStatus: 'pending',
        toStatus: 'complete',
        fromPaymentStatus: 'checkout_created',
        toPaymentStatus: 'paid',
        note: 'manual verified',
        paymentIntentId: 'pi_123',
      );

      final rebuilt = VerificationLog.fromMap(log.toMap());
      expect(rebuilt.actor, log.actor);
      expect(rebuilt.summary, log.summary);
      expect(rebuilt.toStatus, 'complete');
      expect(rebuilt.toPaymentStatus, 'paid');
      expect(rebuilt.paymentIntentId, 'pi_123');
    });
  });

  group('Purchase', () {
    test('toMap/fromMap keeps payment and verification fields', () {
      final purchase = Purchase(
        id: 'order_1',
        userId: 'uid_1',
        docPath: 'users/uid_1/orders/order_1',
        planName: '城市極簡告別',
        priceLabel: 'NT\$ 120,000',
        priceAmount: 120000,
        status: 'pending',
        createdAt: DateTime.parse('2026-03-27T00:00:00.000'),
        paymentProvider: 'stripe',
        paymentStatus: 'checkout_created',
        invoiceId: 'manual_123',
        checkoutUrl: 'https://example.com/pay',
        paymentCurrency: 'twd',
        paidAt: DateTime.parse('2026-03-27T01:00:00.000'),
        paymentIntentId: 'pi_abc',
        verifiedBy: 'admin@test.com',
        verifiedAt: DateTime.parse('2026-03-27T02:00:00.000'),
        verificationNote: 'verified',
        verificationLogs: [
          VerificationLog(
            actor: 'admin@test.com',
            actedAt: DateTime.parse('2026-03-27T02:00:00.000'),
            summary: 'payment checkout_created -> paid',
            toPaymentStatus: 'paid',
          ),
        ],
      );

      final map = purchase.toMap();
      final rebuilt = Purchase.fromMap(map, id: purchase.id, userId: purchase.userId, docPath: purchase.docPath);

      expect(rebuilt.planName, purchase.planName);
      expect(rebuilt.priceAmount, 120000);
      expect(rebuilt.paymentProvider, 'stripe');
      expect(rebuilt.paymentStatus, 'checkout_created');
      expect(rebuilt.invoiceId, 'manual_123');
      expect(rebuilt.checkoutUrl, 'https://example.com/pay');
      expect(rebuilt.paymentIntentId, 'pi_abc');
      expect(rebuilt.verifiedBy, 'admin@test.com');
      expect(rebuilt.verificationLogs.length, 1);
      expect(rebuilt.verificationLogs.first.toPaymentStatus, 'paid');
    });

    test('fallback parses priceAmount from priceLabel when missing', () {
      final rebuilt = Purchase.fromMap({
        'planName': '測試方案',
        'priceLabel': 'NT\$ 220,000',
        'status': 'pending',
      });

      expect(rebuilt.priceAmount, 220000);
    });

    test('copyWith updates selected fields only', () {
      final original = Purchase(
        planName: '方案A',
        priceLabel: 'NT\$ 100,000',
        priceAmount: 100000,
        status: 'pending',
      );

      final updated = original.copyWith(
        status: 'complete',
        paymentStatus: 'paid',
        paymentIntentId: 'pi_new',
      );

      expect(updated.planName, '方案A');
      expect(updated.status, 'complete');
      expect(updated.paymentStatus, 'paid');
      expect(updated.paymentIntentId, 'pi_new');
      expect(updated.priceAmount, 100000);
    });
  });
}
