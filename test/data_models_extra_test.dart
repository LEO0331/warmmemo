import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/admin_models.dart';
import 'package:warmmemo/data/models/draft_models.dart';
import 'package:warmmemo/data/models/material_catalog.dart';
import 'package:warmmemo/data/models/vendor.dart';

void main() {
  group('data/models - draft models', () {
    test('MemorialDraft toMap/fromMap with timestamp fields', () {
      final draft = MemorialDraft(
        name: '王小明',
        bio: '測試',
        slug: 'abc',
        isPublished: true,
        qrEnabled: true,
        publicUpdatedAt: DateTime(2026, 4, 1, 10, 30),
      );
      final map = draft.toMap();
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['publicUpdatedAt'], isA<Timestamp>());

      final rebuilt = MemorialDraft.fromMap({
        ...map,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 1)),
      });
      expect(rebuilt.name, '王小明');
      expect(rebuilt.slug, 'abc');
      expect(rebuilt.isPublished, isTrue);
    });

    test(
      'PublicMemorialProfile/ObituaryDraft/NotificationEvent round trip',
      () {
        final profile = PublicMemorialProfile(
          slug: 'm1',
          ownerUid: 'u1',
          name: 'name',
          obituaryServiceDate: '2026-04-01',
        );
        final profileMap = profile.toMap();
        final rebuiltProfile = PublicMemorialProfile.fromMap({
          ...profileMap,
          'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 1)),
        });
        expect(rebuiltProfile.slug, 'm1');

        final obituary = ObituaryDraft(
          deceasedName: '張大明',
          serviceDate: '2026-04-05',
        );
        final rebuiltObituary = ObituaryDraft.fromMap({
          ...obituary.toMap(),
          'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 2)),
        });
        expect(rebuiltObituary.deceasedName, '張大明');

        final event = NotificationEvent(
          id: 'n1',
          userId: 'u1',
          channel: 'email',
          status: 'pending',
          occurredAt: DateTime(2026, 4, 5),
          tone: 'warm',
          draftType: 'memorial',
        );
        final rebuiltEvent = NotificationEvent.fromMap(event.toMap(), id: 'n1');
        expect(rebuiltEvent.id, 'n1');
        expect(rebuiltEvent.userId, 'u1');
        expect(rebuiltEvent.channel, 'email');
      },
    );

    test('DraftStats toMap/fromMap and date parser fallback branches', () {
      final stats = DraftStats(readCount: 9, clickCount: 4);
      final statsMap = stats.toMap();
      expect(statsMap['readCount'], 9);
      expect(statsMap['clickCount'], 4);
      final rebuiltStats = DraftStats.fromMap(statsMap);
      expect(rebuiltStats.readCount, 9);
      expect(rebuiltStats.clickCount, 4);

      final fromStringDate = NotificationEvent.fromMap({
        'userId': 'u2',
        'channel': 'line',
        'status': 'sent',
        'occurredAt': '2026-04-03T10:00:00.000',
      });
      expect(fromStringDate.occurredAt, DateTime.parse('2026-04-03T10:00:00.000'));

      final before = DateTime.now();
      final fromInvalidDate = NotificationEvent.fromMap({
        'occurredAt': 12345,
      });
      final after = DateTime.now();
      expect(fromInvalidDate.occurredAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(fromInvalidDate.occurredAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(fromInvalidDate.userId, 'unknown');
      expect(fromInvalidDate.channel, 'email');
      expect(fromInvalidDate.status, 'pending');
    });
  });

  group('data/models - admin/vendor/material', () {
    test('UserComplianceSnapshot toMap includes stats and reminder time', () {
      final snapshot = UserComplianceSnapshot(
        userId: 'u1',
        memorialDraft: MemorialDraft(name: 'A'),
        obituaryDraft: ObituaryDraft(deceasedName: 'B'),
        stats: DraftStats(readCount: 3, clickCount: 2),
        lastReminderAt: DateTime(2026, 4, 5),
      );
      final map = snapshot.toMap();
      expect(map['userId'], 'u1');
      expect(map['readCount'], 3);
      expect(map['clickCount'], 2);
      expect(map['lastReminderAt'], isA<String>());
      expect(map['memorialDraft'], isA<Map<String, Object?>>());
      expect(map['obituaryDraft'], isA<Map<String, Object?>>());
    });

    test('Vendor toMap/fromMap/copyWith', () {
      final vendor = Vendor(
        id: 'v1',
        name: '供應商A',
        contactName: '王先生',
        contactPhone: '0912345678',
        serviceRegion: '台北',
      );
      final map = vendor.toMap();
      expect(map['nameLower'], '供應商a');

      final rebuilt = Vendor.fromMap({
        ...map,
        'updatedAt': DateTime(2026, 4, 1).toIso8601String(),
      }, id: 'v1');
      expect(rebuilt.id, 'v1');
      expect(rebuilt.name, '供應商A');

      final updated = rebuilt.copyWith(isActive: false);
      expect(updated.isActive, isFalse);
      expect(updated.name, rebuilt.name);

      final preserved = rebuilt.copyWith();
      expect(preserved.isActive, rebuilt.isActive);
    });

    test('material catalog has expected options and tiers', () {
      expect(kMaterialOptionsV1.length, greaterThanOrEqualTo(6));
      final tiers = kMaterialOptionsV1.map((m) => m.tier).toSet();
      expect(tiers.contains('Basic'), isTrue);
      expect(tiers.contains('Standard'), isTrue);
      expect(tiers.contains('Premium'), isTrue);
      expect(kMaterialOptionsV1.any((m) => m.code == 'granite_black'), isTrue);
    });
  });
}
