import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:warmmemo/data/firebase/auth_service.dart';
import 'package:warmmemo/data/models/cyber_skill.dart';
import 'package:warmmemo/data/models/draft_models.dart';
import 'package:warmmemo/data/services/cyber_skill_storage_service.dart';
import 'package:warmmemo/data/services/notification_service.dart';
import 'package:warmmemo/data/services/payment_service.dart';
import 'package:warmmemo/data/services/reminder_service.dart';
import 'package:warmmemo/data/services/token_wallet_service.dart';

void main() {
  group('Coverage boost: CyberSkillStorageService', () {
    test(
      'save existing skill keeps createdAt, advances version, limits fields',
      () async {
        final db = FakeFirebaseFirestore();
        final service = CyberSkillStorageService(firestore: db);
        final ref = db
            .collection('users')
            .doc('u1')
            .collection('cyberSkills')
            .doc('skill-1');
        await ref.set({
          'version': 'v000009',
          'createdAt': '2026-03-01T00:00:00Z',
        });

        final saved = await service.saveSkill(
          uid: 'u1',
          existingId: 'skill-1',
          templateType: TemplateType.warmmemoDaily,
          profile: CyberSkillProfile(
            name: 'N' * 120,
            company: 'WarmMemo',
            level: 'P6',
            role: 'PM',
          ),
          analysis: const CyberSkillAnalysis(
            catchPhrases: <String>[],
            frequentWords: <String>[],
            toneTraits: <String>['a', 'b', 'c', 'd', 'e', 'f'],
            decisionPriorities: <String>['1', '2', '3', '4', '5', '6'],
            interpersonalPatterns: <String>[],
            workMethods: <String>['m1', 'm2', 'm3', 'm4', 'm5', 'm6'],
            boundaries: <String>['b1', 'b2', 'b3', 'b4', 'b5', 'b6'],
            sentenceStyle: 'short',
            sourceStats: <String, int>{'messages': 1},
          ),
          markdown: 'M' * 22000,
        );

        expect(saved.id, 'skill-1');
        expect(saved.version, 'v000010');
        expect(saved.createdAt, DateTime.parse('2026-03-01T00:00:00Z').toUtc());
        expect(saved.profileName.length, 80);
        expect(saved.markdown.length, 20000);
        expect((saved.analysisSummary['toneTraits'] as List).length, 5);
      },
    );

    test('invalid version/date fallback and delete path works', () async {
      final db = FakeFirebaseFirestore();
      final service = CyberSkillStorageService(firestore: db);
      final ref = db
          .collection('users')
          .doc('u2')
          .collection('cyberSkills')
          .doc('skill-x');
      await ref.set({'version': 'oops', 'createdAt': 'not-a-date'});

      final saved = await service.saveSkill(
        uid: 'u2',
        existingId: 'skill-x',
        templateType: TemplateType.colleagueWork,
        profile: const CyberSkillProfile(name: 'A'),
        analysis: const CyberSkillAnalysis(
          catchPhrases: <String>[],
          frequentWords: <String>[],
          toneTraits: <String>[],
          decisionPriorities: <String>[],
          interpersonalPatterns: <String>[],
          workMethods: <String>[],
          boundaries: <String>[],
          sentenceStyle: '',
          sourceStats: <String, int>{},
        ),
        markdown: '# md',
      );
      expect(saved.version, 'v000001');

      await service.deleteSkill(uid: 'u2', skillId: 'skill-x');
      expect((await ref.get()).exists, isFalse);
    });
  });

  group('Coverage boost: TokenWalletService', () {
    test('balance stream parses num and getBalance fallback', () async {
      final db = FakeFirebaseFirestore();
      final service = TokenWalletService(firestore: db);
      await db.collection('users').doc('u1').set({'tokenBalance': 2.7});
      expect(await service.balanceStream('u1').first, 2);
      expect(await service.getBalance('u-none'), 0);
      expect(TokenWalletService.starterTokens, 5);
      expect(TokenWalletService.definitions.length, greaterThan(3));
    });

    test('maps firebase and unknown consume failures', () async {
      final db = FakeFirebaseFirestore();
      Future<TokenConsumeResult> consumeWithError(Object error) async {
        final service = TokenWalletService(
          firestore: db,
          transactionRunner: <T>(_) async => throw error,
        );
        return service.consume(
          uid: 'u3',
          type: AdvancedServiceType.memorialPreview,
        );
      }

      final denied = await consumeWithError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(denied.ok, isFalse);
      expect(denied.errorCode, 'permission-denied');
      expect(denied.message, contains('權限不足'));

      final unavailable = await consumeWithError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(unavailable.message, contains('暫時不可用'));

      final timeout = await consumeWithError(
        FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded'),
      );
      expect(timeout.message, contains('連線逾時'));

      final unknownFirebase = await consumeWithError(
        FirebaseException(plugin: 'cloud_firestore', code: 'internal'),
      );
      expect(unknownFirebase.message, contains('點數扣除失敗'));

      final unknown = await consumeWithError(StateError('boom'));
      expect(unknown.errorCode, 'unknown');
      expect(unknown.message, contains('點數扣除失敗'));
    });
  });

  group('Coverage boost: ReminderService', () {
    test('returns empty result when no pending notifications', () async {
      final db = FakeFirebaseFirestore();
      final notificationService = NotificationService(firestore: db);
      final reminder = ReminderService(
        firestore: db,
        notificationService: notificationService,
      );
      final result = await reminder.pushReminders(channel: 'line', limit: 1);
      expect(result.notifications, 0);
      expect(result.users, isEmpty);
      expect(result.channel, 'line');
    });

    test('uses provided limit when fetching pending', () async {
      final db = FakeFirebaseFirestore();
      final notificationService = NotificationService(firestore: db);
      for (var i = 0; i < 4; i++) {
        await notificationService.logEvent(
          NotificationEvent(
            userId: 'u$i',
            channel: 'email',
            status: 'pending',
            occurredAt: DateTime(2026, 1, 1, 8, i),
          ),
        );
      }
      final reminder = ReminderService(
        firestore: db,
        notificationService: notificationService,
      );
      final result = await reminder.pushReminders(channel: 'sms', limit: 2);
      expect(result.notifications, 2);
    });
  });

  group('Coverage boost: PaymentService', () {
    test('hosted mode branches: missing/invalid/success', () async {
      final missing = PaymentService(
        useHostedPaymentLinks: true,
        paymentLink120000: '',
      );
      expect(
        () => missing.createInvoice(
          email: 'a@test.com',
          name: 'A',
          amountCents: 120000,
          description: 'd',
          provider: PaymentProvider.stripe,
        ),
        throwsA(isA<StateError>()),
      );

      final invalid = PaymentService(
        useHostedPaymentLinks: true,
        paymentLink120000: 'javascript:alert(1)',
      );
      expect(
        () => invalid.createInvoice(
          email: 'a@test.com',
          name: 'A',
          amountCents: 120000,
          description: 'd',
          provider: PaymentProvider.stripe,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('格式錯誤'),
          ),
        ),
      );

      final ok = PaymentService(
        useHostedPaymentLinks: true,
        paymentLink120000: 'https://buy.stripe.com/test_120000',
      );
      final result = await ok.createInvoice(
        email: 'a@test.com',
        name: 'A',
        amountCents: 120000,
        description: 'd',
        provider: PaymentProvider.stripe,
      );
      expect(result.provider, PaymentProvider.stripe);
      expect(result.checkoutUrl, contains('https://buy.stripe.com'));
      expect(result.invoiceId, startsWith('manual_'));
      expect(ok.useHostedPaymentLinks, isTrue);
      expect(ok.hostedCheckoutUrlForAmount(22000000), isNull);
    });

    test('uses authService id token path for invoice and linepay', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'u1@test.com'),
        signedIn: true,
      );
      final authService = AuthService(
        auth: auth,
        ensureUserProfile: (_) async {},
      );
      final service = PaymentService(
        authService: authService,
        client: MockClient((request) async {
          final authHeader = request.headers['authorization'] ?? '';
          expect(authHeader.startsWith('Bearer '), isTrue);
          if (request.url.path.endsWith('createInvoice')) {
            return http.Response(
              '{"invoiceId":"i1","checkoutUrl":"https://pay.example.com/i1","provider":"stripe"}',
              200,
            );
          }
          return http.Response(
            '{"invoiceId":"tx1","checkoutUrl":"https://pay.example.com/tx1"}',
            200,
          );
        }),
      );
      final invoice = await service.createInvoice(
        email: 'u1@test.com',
        name: 'U1',
        amountCents: 120000,
        description: 'desc',
        provider: PaymentProvider.stripe,
      );
      final line = await service.createLinePayCheckout(
        amount: 120000,
        orderId: 'o-1',
        description: 'line',
      );
      expect(invoice.provider, PaymentProvider.stripe);
      expect(line.provider, PaymentProvider.linepay);
    });

    test('linepay catches xhr-like error and validates payload/url', () async {
      final xhrService = PaymentService(
        idTokenProvider: () async => 't',
        client: MockClient((_) async {
          throw Exception('XMLHttpRequest error');
        }),
      );
      expect(
        () => xhrService.createLinePayCheckout(
          amount: 120000,
          orderId: 'o-2',
          description: 'line',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('XMLHttpRequest error'),
          ),
        ),
      );

      final missing = PaymentService(
        idTokenProvider: () async => 't',
        client: MockClient((_) async {
          return http.Response('{"invoiceId":"tx_only"}', 200);
        }),
      );
      expect(
        () => missing.createLinePayCheckout(
          amount: 120000,
          orderId: 'o-3',
          description: 'line',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'm',
            contains('完整 LINE Pay'),
          ),
        ),
      );

      final invalidUrl = PaymentService(
        idTokenProvider: () async => 't',
        client: MockClient((_) async {
          return http.Response(
            '{"invoiceId":"tx2","checkoutUrl":"javascript:alert(1)"}',
            200,
          );
        }),
      );
      expect(
        () => invalidUrl.createLinePayCheckout(
          amount: 120000,
          orderId: 'o-4',
          description: 'line',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'm',
            contains('checkoutUrl 無效'),
          ),
        ),
      );
    });
  });
}
