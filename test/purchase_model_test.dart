import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/purchase.dart';

class _TimestampLike {
  _TimestampLike(this.value);
  final DateTime value;
  DateTime toDate() => value;
}

class _ThrowingTimestampLike {
  DateTime toDate() => throw StateError('bad timestamp');
}

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

    test('fromMap handles timestamp-like value and throwing value', () {
      final fromLike = VerificationLog.fromMap({
        'actor': 'a',
        'actedAt': _TimestampLike(DateTime.parse('2026-04-01T00:00:00.000')),
        'summary': 'ok',
      });
      expect(fromLike.actedAt, DateTime.parse('2026-04-01T00:00:00.000'));

      final before = DateTime.now();
      final fromThrowing = VerificationLog.fromMap({
        'actor': 'a',
        'actedAt': _ThrowingTimestampLike(),
        'summary': 'fallback',
      });
      final after = DateTime.now();
      expect(fromThrowing.actedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(fromThrowing.actedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
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

    test('proposal/vendor/material/milestone models cover empty and map paths', () {
      final emptyProposal = OrderProposal(vendorPreference: '  ', materialChoice: null, schedulePreference: '', note: ' ');
      expect(emptyProposal.isEmpty, isTrue);
      final proposal = OrderProposal(
        vendorPreference: 'A',
        materialChoice: 'Granite',
        schedulePreference: 'next week',
        note: 'note',
        submittedAt: DateTime.parse('2026-04-02T00:00:00.000'),
      );
      expect(proposal.isEmpty, isFalse);
      final rebuiltProposal = OrderProposal.fromMap(proposal.toMap());
      expect(rebuiltProposal.vendorPreference, 'A');
      expect(rebuiltProposal.submittedAt, DateTime.parse('2026-04-02T00:00:00.000'));

      final emptyVendor = VendorAssignment(vendorId: ' ', vendorName: '', contactName: null, contactPhone: '  ', region: '');
      expect(emptyVendor.isEmpty, isTrue);
      final vendor = VendorAssignment(
        vendorId: 'v1',
        vendorName: '供應商A',
        contactName: '王',
        contactPhone: '0912',
        region: '台北',
      );
      expect(vendor.isEmpty, isFalse);
      expect(VendorAssignment.fromMap(vendor.toMap()).vendorName, '供應商A');

      final emptyMaterial = MaterialSelection(code: '', label: ' ', tier: null, priceBand: '', grossMarginBand: '  ');
      expect(emptyMaterial.isEmpty, isTrue);
      final material = MaterialSelection(
        code: 'granite_black',
        label: '黑花崗',
        tier: 'Premium',
        priceBand: 'NT\$ 60,000+',
        grossMarginBand: '20%-30%',
      );
      expect(material.isEmpty, isFalse);
      expect(MaterialSelection.fromMap(material.toMap()).code, 'granite_black');

      final milestone = DeliveryMilestone(
        code: 'design_confirmed',
        label: '設計確認',
        status: 'done',
        targetDate: DateTime.parse('2026-04-03T00:00:00.000'),
        note: 'ok',
        updatedAt: DateTime.parse('2026-04-03T08:00:00.000'),
      );
      final copied = milestone.copyWith(status: 'pending');
      expect(copied.status, 'pending');
      expect(copied.code, 'design_confirmed');
      final rebuiltMilestone = DeliveryMilestone.fromMap(milestone.toMap());
      expect(rebuiltMilestone.label, '設計確認');
      final defaultMilestone = DeliveryMilestone.fromMap({});
      expect(defaultMilestone.status, 'pending');
      expect(defaultDeliveryMilestones().map((m) => m.code), ['design_confirmed', 'in_production', 'delivered']);
    });

    test('toMap omits empty proposal/vendor/material but keeps non-empty', () {
      final withEmpty = Purchase(
        planName: '方案A',
        priceLabel: 'NT\$ 100,000',
        priceAmount: 100000,
        status: 'pending',
        proposal: OrderProposal(note: '  '),
        vendorAssignment: VendorAssignment(vendorName: ' '),
        materialSelection: MaterialSelection(code: ' '),
      );
      final emptyMap = withEmpty.toMap();
      expect(emptyMap['proposal'], isNull);
      expect(emptyMap['vendorAssignment'], isNull);
      expect(emptyMap['materialSelection'], isNull);

      final withValues = withEmpty.copyWith(
        proposal: OrderProposal(note: 'needs quote'),
        vendorAssignment: VendorAssignment(vendorName: '供應商A'),
        materialSelection: MaterialSelection(code: 'granite_black'),
      );
      final valueMap = withValues.toMap();
      expect(valueMap['proposal'], isA<Map<String, Object?>>());
      expect(valueMap['vendorAssignment'], isA<Map<String, Object?>>());
      expect(valueMap['materialSelection'], isA<Map<String, Object?>>());
    });

    test('fromMap parses nested maps/date variants and fallback branches', () {
      final parsed = Purchase.fromMap({
        'planName': '方案B',
        'priceLabel': 'N/A',
        'status': 'pending',
        'createdAt': DateTime.parse('2026-04-01T00:00:00.000'),
        'proposal': {
          'vendorPreference': 'A',
          'submittedAt': DateTime.parse('2026-04-01T09:00:00.000').toIso8601String(),
        },
        'vendorAssignment': {
          'vendorId': 'v1',
          'vendorName': '供應商A',
        },
        'materialSelection': {
          'code': 'granite_black',
          'tier': 'Premium',
        },
        'deliverySchedule': [
          {
            'code': 'design_confirmed',
            'label': '設計確認',
            'targetDate': DateTime.parse('2026-04-05T00:00:00.000').toIso8601String(),
          },
        ],
      });
      expect(parsed.createdAt, DateTime.parse('2026-04-01T00:00:00.000'));
      expect(parsed.priceAmount, 0);
      expect(parsed.proposal?.vendorPreference, 'A');
      expect(parsed.vendorAssignment?.vendorId, 'v1');
      expect(parsed.materialSelection?.code, 'granite_black');
      expect(parsed.deliverySchedule.length, 1);
      expect(parsed.deliverySchedule.first.code, 'design_confirmed');

      final nullNested = Purchase.fromMap({
        'planName': '方案C',
        'priceLabel': 'NT\$ ???',
        'proposal': 'bad',
        'vendorAssignment': 'bad',
        'materialSelection': 123,
        'deliverySchedule': const [],
      });
      expect(nullNested.proposal, isNull);
      expect(nullNested.vendorAssignment, isNull);
      expect(nullNested.materialSelection, isNull);
      expect(nullNested.priceAmount, 0);
    });

    test('priceAmount fallback handles null label', () {
      final rebuilt = Purchase.fromMap({
        'planName': '測試方案',
      });
      expect(rebuilt.priceAmount, 0);
    });
  });
}
