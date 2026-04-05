import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/firebase/draft_service.dart';
import 'package:warmmemo/data/models/draft_models.dart';

void main() {
  group('FirebaseDraftService extra coverage', () {
    test('publish/load public memorial and slug availability', () async {
      final db = FakeFirebaseFirestore();
      final service = FirebaseDraftService(firestore: db);

      final draft = MemorialDraft(
        name: '王小明',
        slug: 'My-Slug',
        isPublished: true,
        qrEnabled: true,
      );
      final profile = await service.publishMemorial('u1', draft);
      expect(profile.slug, 'my-slug');

      final loaded = await service.loadPublicMemorialBySlug('my-slug');
      expect(loaded, isNotNull);
      expect(loaded!.ownerUid, 'u1');

      expect(await service.isMemorialSlugAvailable('my-slug'), isFalse);
      expect(
        await service.isMemorialSlugAvailable('my-slug', excludingUid: 'u1'),
        isTrue,
      );
      expect(await service.isMemorialSlugAvailable(''), isFalse);
    });

    test('publishMemorial throws when slug missing', () async {
      final db = FakeFirebaseFirestore();
      final service = FirebaseDraftService(firestore: db);
      expect(
        () => service.publishMemorial('u1', MemorialDraft(name: 'x', slug: '')),
        throwsArgumentError,
      );
    });

    test('unpublish respects owner and normalized slug', () async {
      final db = FakeFirebaseFirestore();
      final service = FirebaseDraftService(firestore: db);

      await db.collection('public_memorials').doc('slug1').set({
        'slug': 'slug1',
        'ownerUid': 'ownerA',
      });

      await service.unpublishMemorial('otherUser', 'SLUG1');
      expect(
        (await db.collection('public_memorials').doc('slug1').get()).exists,
        isTrue,
      );

      await service.unpublishMemorial('ownerA', 'SLUG1');
      expect(
        (await db.collection('public_memorials').doc('slug1').get()).exists,
        isFalse,
      );
    });

    test(
      'fetchUserSummaries parses timestamp reminder and defaults stats',
      () async {
        final db = FakeFirebaseFirestore();
        final service = FirebaseDraftService(firestore: db);

        await db.collection('users').doc('u1').set({'email': 'u1@test.com'});
        await db
            .collection('users')
            .doc('u1')
            .collection('meta')
            .doc('stats')
            .set({
              'readCount': 1,
              'clickCount': 2,
              'lastReminderAt': Timestamp.fromDate(DateTime(2026, 4, 4)),
            });
        await db.collection('users').doc('u2').set({'email': 'u2@test.com'});

        final summaries = await service.fetchUserSummaries(limit: 10);
        expect(summaries.length, 2);
        final u1 = summaries.firstWhere((s) => s.userId == 'u1');
        final u2 = summaries.firstWhere((s) => s.userId == 'u2');
        expect(u1.lastReminderAt, isNotNull);
        expect(u1.stats.readCount, 1);
        expect(u1.stats.clickCount, 2);
        expect(u2.stats.readCount, 0);
        expect(u2.stats.clickCount, 0);
      },
    );

    test('adminMetricsStream ignores non-stats meta docs', () async {
      final db = FakeFirebaseFirestore();
      final service = FirebaseDraftService(firestore: db);

      await db
          .collection('users')
          .doc('u1')
          .collection('meta')
          .doc('stats')
          .set({'readCount': 2, 'clickCount': 3});
      await db
          .collection('users')
          .doc('u1')
          .collection('meta')
          .doc('other')
          .set({'readCount': 1000, 'clickCount': 1000});

      final metrics = await service.adminMetricsStream().first;
      expect(metrics.totalUsers, 1);
      expect(metrics.totalReads, 2);
      expect(metrics.totalClicks, 3);
    });
  });
}
