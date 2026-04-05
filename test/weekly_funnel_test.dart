import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/purchase.dart';
import 'package:warmmemo/features/admin/models/weekly_funnel.dart';

void main() {
  group('buildWeeklyFunnelSnapshot', () {
    test('aggregates proposal/approved/assigned/delivered by week', () {
      final now = DateTime(2026, 4, 5);
      final order1 = Purchase(
        planName: 'A',
        priceLabel: 'NT\$ 1',
        priceAmount: 1,
        status: 'received',
        createdAt: DateTime(2026, 3, 31),
        proposal: OrderProposal(note: 'n1', submittedAt: DateTime(2026, 4, 1)),
        vendorAssignment: VendorAssignment(vendorId: 'v1'),
        deliverySchedule: [
          DeliveryMilestone(
            code: 'delivered',
            label: '已交付',
            status: 'done',
            updatedAt: DateTime(2026, 4, 3),
          ),
        ],
      );
      final order2 = Purchase(
        planName: 'B',
        priceLabel: 'NT\$ 1',
        priceAmount: 1,
        status: 'pending',
        createdAt: DateTime(2026, 3, 26),
        proposal: OrderProposal(note: 'n2', submittedAt: DateTime(2026, 3, 27)),
      );

      final snapshot = buildWeeklyFunnelSnapshot(
        [order1, order2],
        now: now,
        weeks: 2,
      );
      expect(snapshot.buckets.length, 2);
      expect(snapshot.maxCount, greaterThanOrEqualTo(1));

      final week1 = snapshot.buckets[0];
      final week2 = snapshot.buckets[1];

      expect(week1.proposal, 1);
      expect(week1.approved, 0);
      expect(week1.assigned, 0);
      expect(week1.delivered, 0);

      expect(week2.proposal, 1);
      expect(week2.approved, 1);
      expect(week2.assigned, 1);
      expect(week2.delivered, 1);
    });

    test('returns baseline maxCount when empty', () {
      final snapshot = buildWeeklyFunnelSnapshot(
        const [],
        now: DateTime(2026, 4, 5),
      );
      expect(snapshot.buckets.length, 8);
      expect(snapshot.maxCount, 1);
    });
  });
}
