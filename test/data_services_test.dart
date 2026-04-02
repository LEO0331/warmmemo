import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:warmmemo/data/firebase/auth_service.dart';
import 'package:warmmemo/data/firebase/draft_service.dart';
import 'package:warmmemo/data/models/draft_models.dart';
import 'package:warmmemo/data/models/purchase.dart';
import 'package:warmmemo/data/models/admin_models.dart';
import 'package:warmmemo/data/services/notification_service.dart';
import 'package:warmmemo/data/services/payment_service.dart';
import 'package:warmmemo/data/services/purchase_service.dart';
import 'package:warmmemo/data/services/reminder_service.dart';
import 'package:warmmemo/data/services/token_wallet_service.dart';
import 'package:warmmemo/data/services/user_profile_service.dart';
import 'package:warmmemo/data/services/user_role_service.dart';

void main() {
  group('PaymentService', () {
    test('maps missing key names by amount', () {
      final service = PaymentService();
      expect(service.missingHostedLinkKeyForAmount(120000), 'STRIPE_PAYMENT_LINK_120000');
      expect(service.missingHostedLinkKeyForAmount(15000000), 'STRIPE_PAYMENT_LINK_150000');
      expect(service.missingHostedLinkKeyForAmount(220000), 'STRIPE_PAYMENT_LINK_220000');
      expect(service.missingHostedLinkKeyForAmount(1), 'STRIPE_PAYMENT_LINK_<PLAN_AMOUNT>');
    });

    test('returns null hosted url when no dart-define provided', () {
      final service = PaymentService();
      expect(service.hostedCheckoutUrlForAmount(120000), isNull);
      expect(service.hostedCheckoutUrlForAmount(150000), isNull);
      expect(service.hostedCheckoutUrlForAmount(220000), isNull);
    });

    test('createInvoice throws when id token is missing in backend mode', () async {
      final service = PaymentService(
        idTokenProvider: () async => null,
      );
      expect(
        () => service.createInvoice(
          email: 'a@test.com',
          name: 'A',
          amountCents: 120000,
          description: 'desc',
          provider: PaymentProvider.stripe,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createInvoice maps backend error payload', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer token');
          return http.Response('{"code":"quota-exceeded","error":"daily limit"}', 429);
        }),
      );
      expect(
        () => service.createInvoice(
          email: 'a@test.com',
          name: 'A',
          amountCents: 120000,
          description: 'desc',
          provider: PaymentProvider.stripe,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('quota-exceeded'),
          ),
        ),
      );
    });

    test('createInvoice validates backend success payload', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          return http.Response('{"invoiceId":"a"}', 200);
        }),
      );
      expect(
        () => service.createInvoice(
          email: 'a@test.com',
          name: 'A',
          amountCents: 120000,
          description: 'desc',
          provider: PaymentProvider.stripe,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createInvoice returns parsed payment result', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          return http.Response(
            '{"invoiceId":"inv_123","checkoutUrl":"https://example.com/checkout","provider":"ecpay"}',
            200,
          );
        }),
      );
      final result = await service.createInvoice(
        email: 'a@test.com',
        name: 'A',
        amountCents: 120000,
        description: 'desc',
        provider: PaymentProvider.stripe,
      );
      expect(result.invoiceId, 'inv_123');
      expect(result.checkoutUrl, 'https://example.com/checkout');
      expect(result.provider, PaymentProvider.ecpay);
    });

    test('createInvoice maps unknown provider back to stripe', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          return http.Response(
            '{"invoiceId":"inv_456","checkoutUrl":"https://example.com/checkout","provider":"mystery"}',
            200,
          );
        }),
      );
      final result = await service.createInvoice(
        email: 'a@test.com',
        name: 'A',
        amountCents: 120000,
        description: 'desc',
        provider: PaymentProvider.stripe,
      );
      expect(result.provider, PaymentProvider.stripe);
    });

    test('createInvoice rejects invalid checkout url from backend', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          return http.Response(
            '{"invoiceId":"inv_789","checkoutUrl":"javascript:alert(1)","provider":"stripe"}',
            200,
          );
        }),
      );
      expect(
        () => service.createInvoice(
          email: 'a@test.com',
          name: 'A',
          amountCents: 120000,
          description: 'desc',
          provider: PaymentProvider.stripe,
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('checkoutUrl 無效'))),
      );
    });

    test('createLinePayCheckout throws when id token is missing', () async {
      final service = PaymentService(idTokenProvider: () async => null);
      expect(
        () => service.createLinePayCheckout(
          amount: 120000,
          orderId: 'order-1',
          description: 'line pay',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createLinePayCheckout maps backend http error', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          return http.Response('{"code":"linepay-error","error":"bad request"}', 400);
        }),
      );
      expect(
        () => service.createLinePayCheckout(
          amount: 120000,
          orderId: 'order-2',
          description: 'line pay',
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('linepay-error'))),
      );
    });

    test('createLinePayCheckout returns parsed result', () async {
      final service = PaymentService(
        idTokenProvider: () async => 'token',
        client: MockClient((request) async {
          return http.Response(
            '{"invoiceId":"tx123","checkoutUrl":"https://pay.example.com"}',
            200,
          );
        }),
      );
      final result = await service.createLinePayCheckout(
        amount: 120000,
        orderId: 'order-3',
        description: 'line pay',
      );
      expect(result.provider, PaymentProvider.linepay);
      expect(result.invoiceId, 'tx123');
      expect(result.checkoutUrl, 'https://pay.example.com');
    });
  });

  group('Firestore-backed services', () {
    test('PurchaseService can create and update nested user order', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);

      final created = await purchaseService.createOrder(
        uid: 'userA',
        purchase: Purchase(
          planName: '城市極簡告別',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'pending',
          paymentStatus: 'checkout_created',
        ),
      );
      expect(created.id, isNotNull);
      expect(created.docPath, contains('users/userA/orders/'));

      final updated = created.copyWith(status: 'received');
      await purchaseService.updateOrder(uid: 'userA', purchase: updated);

      final doc = await db.doc(updated.docPath!).get();
      expect(doc.data()?['status'], 'received');
    });

    test('PurchaseService userOrders stream and paging APIs work', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);

      await purchaseService.createOrder(
        uid: 'u1',
        purchase: Purchase(
          planName: 'A',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'pending',
          createdAt: DateTime(2026, 3, 1),
        ),
      );
      await purchaseService.createOrder(
        uid: 'u1',
        purchase: Purchase(
          planName: 'B',
          priceLabel: 'NT\$ 150,000',
          priceAmount: 150000,
          status: 'pending',
          createdAt: DateTime(2026, 3, 2),
        ),
      );
      await purchaseService.createOrder(
        uid: 'u2',
        purchase: Purchase(
          planName: 'C',
          priceLabel: 'NT\$ 220,000',
          priceAmount: 220000,
          status: 'pending',
          createdAt: DateTime(2026, 3, 3),
        ),
      );

      final userOrders = await purchaseService.userOrders('u1').first;
      expect(userOrders.length, 2);
      expect(userOrders.first.planName, 'B');

      final adminOrders = await purchaseService.adminOrders().first;
      expect(adminOrders.length, 3);
      expect(adminOrders.any((o) => o.userId == 'u1'), isTrue);
      expect(adminOrders.any((o) => o.userId == 'u2'), isTrue);
    });

    test('PurchaseService updateOrder falls back to users/{uid}/orders/{id}', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);
      final ref = db.collection('users').doc('u9').collection('orders').doc('o1');
      await ref.set({
        'planName': 'X',
        'priceLabel': 'NT\$ 120,000',
        'priceAmount': 120000,
        'status': 'pending',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });

      await purchaseService.updateOrder(
        uid: 'u9',
        purchase: Purchase(
          id: 'o1',
          userId: 'u9',
          planName: 'X',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'complete',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final doc = await ref.get();
      expect(doc.data()?['status'], 'complete');
    });

    test('PurchaseService adminOrdersPage returns items and cursor', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);

      await purchaseService.createOrder(
        uid: 'u-page',
        purchase: Purchase(
          planName: 'PageA',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'pending',
        ),
      );
      await purchaseService.createOrder(
        uid: 'u-page',
        purchase: Purchase(
          planName: 'PageB',
          priceLabel: 'NT\$ 150,000',
          priceAmount: 150000,
          status: 'pending',
        ),
      );

      final page = await purchaseService.adminOrdersPage(limit: 1);
      expect(page.items, isNotEmpty);
      expect(page.cursor, isNotNull);
      expect(page.items.first.userId, 'u-page');
    });

    test('PurchaseService updateOrder returns early when id is null', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);
      await purchaseService.updateOrder(
        uid: 'u1',
        purchase: Purchase(
          planName: 'NoId',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'pending',
        ),
      );
      final docs = await db.collection('users').doc('u1').collection('orders').get();
      expect(docs.docs, isEmpty);
    });

    test('PurchaseService batch update returns skipped reasons and updates', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);

      final ok = await purchaseService.createOrder(
        uid: 'u1',
        purchase: Purchase(
          planName: 'OK',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'pending',
          paymentStatus: 'checkout_created',
        ),
      );
      final noChange = await purchaseService.createOrder(
        uid: 'u1',
        purchase: Purchase(
          planName: 'NoChange',
          priceLabel: 'NT\$ 120,000',
          priceAmount: 120000,
          status: 'complete',
          paymentStatus: 'paid',
        ),
      );

      final report = await purchaseService.adminBatchUpdate(
        purchases: [
          ok,
          noChange,
          Purchase(
            id: 'missing',
            planName: 'MissingUid',
            priceLabel: 'NT\$ 120,000',
            priceAmount: 120000,
            status: 'pending',
          ),
        ],
        caseStatus: 'received',
        paymentStatus: 'paid',
        actor: 'tester',
      );
      expect(report.selectedCount, 3);
      expect(report.updatedCount, 1);
      expect(report.skippedCount, 2);
      expect(report.skipped.any((s) => s.reason.contains('缺少 userId')), isTrue);
      expect(report.skipped.any((s) => s.reason.contains('案件狀態不可')), isTrue);
      final updatedDoc = await db.doc(ok.docPath!).get();
      expect(updatedDoc.data()?['status'], 'received');
      expect(updatedDoc.data()?['paymentStatus'], 'paid');
    });

    test('PurchaseService batch update handles empty selection', () async {
      final db = FakeFirebaseFirestore();
      final purchaseService = PurchaseService(firestore: db);
      final report = await purchaseService.adminBatchUpdate(purchases: const []);
      expect(report.selectedCount, 0);
      expect(report.updatedCount, 0);
      expect(report.skippedCount, 0);
    });

    test('OrderWorkflow transitions enforce allowed states', () {
      expect(
        OrderWorkflow.canChangeCaseStatus(from: 'pending', to: 'received'),
        isTrue,
      );
      expect(
        OrderWorkflow.canChangeCaseStatus(from: 'pending', to: 'complete'),
        isFalse,
      );
      expect(
        OrderWorkflow.canChangePaymentStatus(from: 'failed', to: 'checkout_created'),
        isTrue,
      );
      expect(
        OrderWorkflow.canChangePaymentStatus(from: 'paid', to: 'checkout_created'),
        isFalse,
      );
    });

    test('NotificationService and ReminderService create reminder once per user', () async {
      final db = FakeFirebaseFirestore();
      final notificationService = NotificationService(firestore: db);
      final reminderService = ReminderService(
        firestore: db,
        notificationService: notificationService,
      );

      final now = DateTime(2026, 3, 27, 10, 0);
      await notificationService.logEvent(
        NotificationEvent(
          userId: 'u1',
          channel: 'email',
          status: 'pending',
          occurredAt: now,
          tone: 'warm',
          draftType: 'memorial',
        ),
      );
      await notificationService.logEvent(
        NotificationEvent(
          userId: 'u1',
          channel: 'line',
          status: 'pending',
          occurredAt: now.add(const Duration(minutes: 1)),
          tone: 'warm',
          draftType: 'memorial',
        ),
      );
      await notificationService.logEvent(
        NotificationEvent(
          userId: 'u2',
          channel: 'sms',
          status: 'pending',
          occurredAt: now.add(const Duration(minutes: 2)),
          tone: 'formal',
          draftType: 'obituary',
        ),
      );

      final result = await reminderService.pushReminders(channel: 'email');
      expect(result.notifications, 2);
      expect(result.users.toSet(), {'u1', 'u2'});

      final reminders = await db
          .collection('notifications')
          .where('status', isEqualTo: 'reminder')
          .get();
      expect(reminders.docs.length, 2);

      final u1Stats = await db.collection('users').doc('u1').collection('meta').doc('stats').get();
      expect(u1Stats.exists, isTrue);
    });

    test('NotificationService query methods return expected records', () async {
      final db = FakeFirebaseFirestore();
      final service = NotificationService(firestore: db);

      await service.logEvent(
        NotificationEvent(
          userId: 'u1',
          channel: 'email',
          status: 'pending',
          occurredAt: DateTime(2026, 3, 1, 8, 0),
        ),
      );
      await service.logEvent(
        NotificationEvent(
          userId: 'u1',
          channel: 'line',
          status: 'delivered',
          occurredAt: DateTime(2026, 3, 1, 9, 0),
        ),
      );
      await service.logEvent(
        NotificationEvent(
          userId: 'u2',
          channel: 'sms',
          status: 'pending',
          occurredAt: DateTime(2026, 3, 1, 10, 0),
        ),
      );

      final history = await service.fetchHistory(limit: 10);
      expect(history.length, 3);

      final pending = await service.fetchPending(limit: 10);
      expect(pending.length, 2);
      expect(await service.pendingCount().first, 2);

      final forUser = await service.fetchForUser('u1', limit: 10);
      expect(forUser.length, 2);

      final timeline = await service.timeline(limit: 2).first;
      expect(timeline.length, 2);
      expect(timeline.first.id, isNotNull);
      final streamForUser = await service.streamForUser('u2', limit: 2).first;
      expect(streamForUser.length, 1);
      expect(streamForUser.first.userId, 'u2');
      expect(streamForUser.first.id, isNotNull);
    });

    test('NotificationService markRead updates status', () async {
      final db = FakeFirebaseFirestore();
      final service = NotificationService(firestore: db);
      await service.logEvent(
        NotificationEvent(
          userId: 'u1',
          channel: 'email',
          status: 'pending',
          occurredAt: DateTime(2026, 3, 2),
        ),
      );
      final before = await db.collection('notifications').get();
      final id = before.docs.first.id;
      await service.markRead(id);
      final after = await db.collection('notifications').doc(id).get();
      expect(after.data()?['status'], 'read');
      expect(after.data()?['readAt'], isNotNull);
    });

    test('FirebaseDraftService saves and reads drafts/stats/summaries', () async {
      final db = FakeFirebaseFirestore();
      final draftService = FirebaseDraftService(firestore: db);

      await draftService.saveMemorial(
        'u1',
        MemorialDraft(name: '王小明', bio: '測試內容'),
      );
      await draftService.saveObituary(
        'u1',
        ObituaryDraft(deceasedName: '王大明', tone: 'warm'),
      );
      await draftService.incrementStats('u1', readDelta: 2, clickDelta: 1);

      final memorial = await draftService.loadMemorial('u1');
      final obituary = await draftService.loadObituary('u1');
      final stats = await draftService.loadStats('u1');
      expect(memorial?.name, '王小明');
      expect(obituary?.deceasedName, '王大明');
      expect(stats.readCount, 2);
      expect(stats.clickCount, 1);

      await db.collection('users').doc('u1').collection('meta').doc('stats').set(
        {'lastReminderAt': '2026-03-20T10:20:30.000Z'},
        SetOptions(merge: true),
      );
      final summaries = await draftService.fetchUserSummaries(limit: 10);
      expect(summaries.length, 1);
      expect(summaries.first.userId, 'u1');
      expect(summaries.first.lastReminderAt, isNotNull);
    });

    test('FirebaseDraftService admin overview/metrics/notifications work', () async {
      final db = FakeFirebaseFirestore();
      final draftService = FirebaseDraftService(firestore: db);

      await db.collection('users').doc('u1').set({'updatedAt': Timestamp.now()});
      await db.collection('users').doc('u2').set({'updatedAt': Timestamp.now()});
      await db.collection('users').doc('u1').collection('meta').doc('stats').set({
        'readCount': 5,
        'clickCount': 2,
      });
      await db.collection('users').doc('u2').collection('meta').doc('stats').set({
        'readCount': 3,
        'clickCount': 4,
      });

      final overview = await draftService.adminOverview().first;
      expect(overview.length, 2);

      final metrics = await draftService.adminMetricsStream().first;
      expect(metrics.totalUsers, 2);
      expect(metrics.totalReads, 8);
      expect(metrics.totalClicks, 6);

      await draftService.logNotificationEvent(
        NotificationEvent(
          userId: 'u1',
          channel: 'email',
          status: 'pending',
          occurredAt: DateTime(2026, 3, 27, 12, 0),
          tone: 'warm',
          draftType: 'memorial',
        ),
      );

      final history = await draftService.fetchNotificationHistory(limit: 10);
      expect(history.length, 1);
      final timeline = await draftService.notificationTimeline(limit: 10).first;
      expect(timeline.length, 1);
      expect(timeline.first.userId, 'u1');
    });

    test('FirebaseDraftService handles empty stats update and missing drafts', () async {
      final db = FakeFirebaseFirestore();
      final draftService = FirebaseDraftService(firestore: db);

      expect(await draftService.loadMemorial('none'), isNull);
      expect(await draftService.loadObituary('none'), isNull);

      await draftService.incrementStats('u1');
      final statsDoc = await db.collection('users').doc('u1').collection('meta').doc('stats').get();
      expect(statsDoc.exists, isFalse);
    });

    test('UserRoleService can ensure and verify admin doc', () async {
      final db = FakeFirebaseFirestore();
      final roleService = UserRoleService(firestore: db);

      expect(await roleService.adminDocExists('adminUid'), isFalse);
      await roleService.ensureAdminDoc('adminUid');
      expect(await roleService.adminDocExists('adminUid'), isTrue);
    });

    test('UserRoleService roleStream defaults to user', () async {
      final db = FakeFirebaseFirestore();
      final roleService = UserRoleService(firestore: db);
      expect(await roleService.roleStream('u1').first, 'user');
      await db.collection('users').doc('u1').set({'role': 'admin'});
      expect(await roleService.roleStream('u1').first, 'admin');
    });

    test('UserRoleService ensureUserProfile initializes role and email', () async {
      final db = FakeFirebaseFirestore();
      final roleService = UserRoleService(firestore: db);
      final user = MockUser(uid: 'u100', email: 'u100@test.com');
      await roleService.ensureUserProfile(user);
      final doc = await db.collection('users').doc('u100').get();
      expect(doc.data()?['role'], 'user');
      expect(doc.data()?['email'], 'u100@test.com');
      expect(doc.data()?['updatedAt'], isNotNull);
    });

    test('AuthService signIn/signUp delegates and ensures profile', () async {
      var ensuredCount = 0;
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u200', email: 'u200@test.com'),
      );
      final service = AuthService(
        auth: auth,
        ensureUserProfile: (_) async {
          ensuredCount++;
        },
      );
      await service.signIn(email: 'u200@test.com', password: '123456');
      await service.signUp(email: 'u200@test.com', password: '123456');
      expect(ensuredCount, 1);
      expect(service.currentUser, isNotNull);
      expect(service.isEmailPasswordUser(service.currentUser!), isTrue);
      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('AuthService isAdmin returns false when no current user', () async {
      final auth = MockFirebaseAuth(signedIn: false);
      final service = AuthService(
        auth: auth,
        ensureUserProfile: (_) async {},
      );
      expect(await service.isAdmin, isFalse);
    });

    test('AuthService isAdmin reflects id token admin claim', () async {
      final adminAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'admin1', customClaim: {'admin': true}),
        signedIn: true,
      );
      final adminService = AuthService(
        auth: adminAuth,
        ensureUserProfile: (_) async {},
      );
      expect(await adminService.isAdmin, isTrue);

      final userAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user1', customClaim: {'admin': false}),
        signedIn: true,
      );
      final userService = AuthService(
        auth: userAuth,
        ensureUserProfile: (_) async {},
      );
      expect(await userService.isAdmin, isFalse);
    });

    test('AuthService signUp does not fail when ensure profile throws', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u-throw', email: 'u-throw@test.com'),
      );
      final service = AuthService(
        auth: auth,
        ensureUserProfile: (_) async {
          throw Exception('permission-denied');
        },
      );
      final credential = await service.signUp(
        email: 'u-throw@test.com',
        password: '123456',
      );
      expect(credential.user, isNotNull);
      expect(service.currentUser, isNotNull);
    });

    test('AuthService authStateChanges stream emits signed in user', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u-stream', email: 'u-stream@test.com'),
        signedIn: true,
      );
      final service = AuthService(
        auth: auth,
        ensureUserProfile: (_) async {},
      );
      final user = await service.authStateChanges.firstWhere((u) => u != null);
      expect(user?.uid, 'u-stream');
    });

    test('TokenWalletService consumes token and writes token log', () async {
      final db = FakeFirebaseFirestore();
      final service = TokenWalletService(firestore: db);
      await db.collection('users').doc('u-token').set({'tokenBalance': 3});

      final result = await service.consume(
        uid: 'u-token',
        type: AdvancedServiceType.obituaryGenerate,
        note: 'test run',
      );

      expect(result.ok, isTrue);
      expect(result.balanceAfter, 2);
      expect(await service.getBalance('u-token'), 2);

      final logs = await db.collection('users').doc('u-token').collection('tokenLogs').get();
      expect(logs.docs.length, 1);
      expect(logs.docs.first.data()['type'], 'consume');
      expect(logs.docs.first.data()['service'], AdvancedServiceType.obituaryGenerate.name);
    });

    test('TokenWalletService consume fails when balance is insufficient', () async {
      final db = FakeFirebaseFirestore();
      final service = TokenWalletService(firestore: db);
      await db.collection('users').doc('u-token-low').set({'tokenBalance': 0});

      final result = await service.consume(
        uid: 'u-token-low',
        type: AdvancedServiceType.memorialPreview,
      );

      expect(result.ok, isFalse);
      expect(result.balanceAfter, 0);
      expect(result.message, contains('點數不足'));
      final logs = await db.collection('users').doc('u-token-low').collection('tokenLogs').get();
      expect(logs.docs, isEmpty);
    });

    test('TokenWalletService balance stream defaults to zero', () async {
      final db = FakeFirebaseFirestore();
      final service = TokenWalletService(firestore: db);
      expect(await service.balanceStream('u-none').first, 0);
    });

    test('UserProfileService onboarding methods update profile correctly', () async {
      final db = FakeFirebaseFirestore();
      final service = UserProfileService(firestore: db);
      const uid = 'u-profile';

      await service.setSelectedService(uid, 'memorial');
      await service.markOnboardingStep(uid, UserProfileService.onboardingStepFirstDraft);
      // Re-marking an existing step should not duplicate it.
      await service.markOnboardingStep(uid, UserProfileService.onboardingStepFirstDraft);

      final profile = await service.getProfile(uid);
      expect(
        service.completedStepsCount(profile),
        2,
      );
      final steps = (profile?['onboardingSteps'] as List<dynamic>).whereType<String>().toList();
      expect(
        steps.where((s) => s == UserProfileService.onboardingStepFirstDraft).length,
        1,
      );
    });

    test('UserProfileService profile stream emits null then value', () async {
      final db = FakeFirebaseFirestore();
      final service = UserProfileService(firestore: db);
      const uid = 'u-stream';

      expect(await service.profileStream(uid).first, isNull);

      await db.collection('users').doc(uid).set({'role': 'user'});
      final next = await service.profileStream(uid).first;
      expect(next?['role'], 'user');
    });

    test('UserProfileService submits top up request with pending status', () async {
      final db = FakeFirebaseFirestore();
      final service = UserProfileService(firestore: db);

      await service.submitTopUpRequest(
        uid: 'u-topup',
        requestedTokens: 20,
        note: '  need more for family  ',
      );

      final docs = await db.collection('users').doc('u-topup').collection('topupRequests').get();
      expect(docs.docs.length, 1);
      final data = docs.docs.first.data();
      expect(data['requestedTokens'], 20);
      expect(data['status'], 'pending');
      expect(data['note'], 'need more for family');
      expect(data['createdAt'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });

    test('UserProfileService completed steps ignores unknown values', () {
      final service = UserProfileService(firestore: FakeFirebaseFirestore());
      final profile = {
        'onboardingSteps': [
          UserProfileService.onboardingStepSelectService,
          'unknown-step',
          123,
        ],
      };
      expect(service.completedStepsCount(profile), 1);
      expect(service.completedStepsCount(null), 0);
    });

    test('UserComplianceSnapshot serializes summary fields', () {
      final snapshot = UserComplianceSnapshot(
        userId: 'u1',
        memorialDraft: MemorialDraft(name: '王小明'),
        obituaryDraft: ObituaryDraft(deceasedName: '王大明'),
        stats: DraftStats(readCount: 9, clickCount: 4),
        lastReminderAt: DateTime.parse('2026-03-01T10:00:00.000Z'),
      );
      final map = snapshot.toMap();
      expect(map['userId'], 'u1');
      expect(map['readCount'], 9);
      expect(map['clickCount'], 4);
      expect(map['lastReminderAt'], '2026-03-01T10:00:00.000Z');
      expect(map['memorialDraft'], isNotNull);
      expect(map['obituaryDraft'], isNotNull);
    });
  });
}
