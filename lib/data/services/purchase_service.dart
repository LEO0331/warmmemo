import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/purchase.dart';

class OrderWorkflow {
  static const List<String> caseStatuses = ['pending', 'received', 'complete'];
  static const List<String> paymentStatuses = [
    'awaiting_checkout',
    'checkout_created',
    'paid',
    'failed',
    'cancelled',
    'expired',
  ];

  static const Map<String, Set<String>> _caseTransitions = {
    'pending': {'pending', 'received'},
    'received': {'received', 'complete'},
    'complete': {'complete'},
  };

  static const Map<String, Set<String>> _paymentTransitions = {
    'awaiting_checkout': {
      'awaiting_checkout',
      'checkout_created',
      'cancelled',
      'expired',
    },
    'checkout_created': {
      'checkout_created',
      'paid',
      'failed',
      'cancelled',
      'expired',
    },
    'paid': {'paid'},
    'failed': {'failed', 'checkout_created'},
    'cancelled': {'cancelled', 'checkout_created'},
    'expired': {'expired', 'checkout_created'},
  };

  static bool canChangeCaseStatus({required String from, required String to}) {
    return _caseTransitions[from]?.contains(to) ?? false;
  }

  static bool canChangePaymentStatus({
    required String from,
    required String to,
  }) {
    return _paymentTransitions[from]?.contains(to) ?? false;
  }

  static Map<String, Set<String>> get caseTransitionGraph => {
    for (final entry in _caseTransitions.entries)
      entry.key: Set<String>.from(entry.value),
  };

  static Map<String, Set<String>> get paymentTransitionGraph => {
    for (final entry in _paymentTransitions.entries)
      entry.key: Set<String>.from(entry.value),
  };

  static bool canMarkComplete(Purchase order) {
    final paid = order.paymentStatus == 'paid';
    final deliveredDone = order.deliverySchedule.any(
      (item) => item.code == 'delivered' && item.status == 'done',
    );
    return paid && deliveredDone;
  }

  static void assertTransitionAllowed({
    required Purchase previous,
    required Purchase next,
  }) {
    final fromCase = previous.status;
    final toCase = next.status;
    if (!canChangeCaseStatus(from: fromCase, to: toCase)) {
      throw StateError('workflow-invalid-transition:status:$fromCase->$toCase');
    }

    final fromPayment = previous.paymentStatus ?? 'checkout_created';
    final toPayment = next.paymentStatus ?? 'checkout_created';
    if (!canChangePaymentStatus(from: fromPayment, to: toPayment)) {
      throw StateError(
        'workflow-invalid-transition:payment:$fromPayment->$toPayment',
      );
    }

    if (toCase == 'complete' && !canMarkComplete(next)) {
      throw StateError(
        'workflow-invalid-transition:complete_requires_paid_and_delivered',
      );
    }
  }
}

class BatchUpdateSkip {
  BatchUpdateSkip({
    required this.orderId,
    required this.planName,
    required this.userId,
    required this.reason,
  });

  final String orderId;
  final String planName;
  final String userId;
  final String reason;
}

class BatchUpdateReport {
  BatchUpdateReport({
    required this.selectedCount,
    required this.updatedCount,
    required this.skipped,
  });

  final int selectedCount;
  final int updatedCount;
  final List<BatchUpdateSkip> skipped;

  int get skippedCount => skipped.length;
}

class PurchaseService {
  PurchaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final PurchaseService instance = PurchaseService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<Purchase> createOrder({
    required String uid,
    required Purchase purchase,
  }) async {
    final normalized = purchase
        .copyWith(
          userId: uid,
          schemaVersion: Purchase.currentSchemaVersion,
        )
        .normalizedForStorage();
    final doc = await _users
        .doc(uid)
        .collection('orders')
        .add(normalized.toMap());
    return normalized.copyWith(id: doc.id, userId: uid, docPath: doc.path);
  }

  Stream<List<Purchase>> userOrders(String uid) {
    return _users
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Purchase.fromMap(
                  doc.data(),
                  id: doc.id,
                  docPath: doc.reference.path,
                ),
              )
              .toList(),
        );
  }

  Future<List<Purchase>> fetchUserOrders(String uid, {int? limit}) async {
    Query<Map<String, dynamic>> query = _users
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map(
          (doc) => Purchase.fromMap(
            doc.data(),
            id: doc.id,
            docPath: doc.reference.path,
          ),
        )
        .toList();
    await _backfillSchemaIfNeeded(
      snapshot.docs.map((doc) => doc.reference).toList(),
      items,
    );
    return items;
  }

  Stream<List<Purchase>> adminOrders() {
    return _firestore
        .collectionGroup('orders')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final userId = doc.reference.parent.parent?.id;
            return Purchase.fromMap(
              doc.data(),
              id: doc.id,
              userId: userId,
              docPath: doc.reference.path,
            );
          }).toList(),
        );
  }

  Future<({List<Purchase> items, String? cursor})> adminOrdersPage({
    int limit = 5,
    String? startAfterDocPath,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('orders')
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfterDocPath != null) {
      query = query.startAfter([startAfterDocPath]);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map(
          (doc) => Purchase.fromMap(
            doc.data(),
            id: doc.id,
            userId: doc.reference.parent.parent?.id,
            docPath: doc.reference.path,
          ),
        )
        .toList();
    await _backfillSchemaIfNeeded(
      snapshot.docs.map((doc) => doc.reference).toList(),
      items,
    );
    final nextCursor = snapshot.docs.isNotEmpty
        ? snapshot.docs.last.reference.path
        : null;
    return (items: items, cursor: nextCursor);
  }

  Future<void> _backfillSchemaIfNeeded(
    List<DocumentReference<Map<String, dynamic>>> refs,
    List<Purchase> items,
  ) async {
    if (refs.isEmpty || items.isEmpty) return;
    final batch = _firestore.batch();
    var writes = 0;
    final count = refs.length < items.length ? refs.length : items.length;
    for (var i = 0; i < count; i++) {
      final order = items[i];
      if (!order.needsSchemaMigration) continue;
      batch.set(refs[i], order.normalizedForStorage().toMap(), SetOptions(merge: true));
      writes += 1;
    }
    if (writes == 0) return;
    await batch.commit();
  }

  Future<void> updateOrder({
    required String uid,
    required Purchase purchase,
    String? mutationId,
  }) async {
    if (purchase.id == null) return;
    final targetRef =
        (purchase.docPath != null && purchase.docPath!.isNotEmpty)
        ? _firestore.doc(purchase.docPath!)
        : _users.doc(uid).collection('orders').doc(purchase.id);

    final previousSnapshot = await targetRef.get();
    if (previousSnapshot.exists) {
      final previousData = previousSnapshot.data();
      if (previousData != null) {
        final previous = Purchase.fromMap(
          previousData,
          id: purchase.id,
          userId: uid,
          docPath: targetRef.path,
        );
        OrderWorkflow.assertTransitionAllowed(
          previous: previous,
          next: purchase,
        );
      }
    }

    final normalized = purchase
        .copyWith(schemaVersion: Purchase.currentSchemaVersion)
        .normalizedForStorage();
    final payload = normalized.toMap();
    if (mutationId != null && mutationId.isNotEmpty) {
      payload['clientMutationId'] = mutationId;
      payload['clientUpdatedAt'] = DateTime.now().toIso8601String();
    }
    await targetRef.set(payload, SetOptions(merge: true));
  }

  Future<BatchUpdateReport> adminBatchUpdate({
    required List<Purchase> purchases,
    String? caseStatus,
    String? paymentStatus,
    String? actor,
  }) async {
    if (purchases.isEmpty) {
      return BatchUpdateReport(
        selectedCount: 0,
        updatedCount: 0,
        skipped: const [],
      );
    }
    var updatedCount = 0;
    final skipped = <BatchUpdateSkip>[];
    for (final order in purchases) {
      final uid = order.userId;
      if (uid == null || uid.isEmpty) {
        skipped.add(
          BatchUpdateSkip(
            orderId: order.id ?? '-',
            planName: order.planName,
            userId: '-',
            reason: '缺少 userId',
          ),
        );
        continue;
      }
      var next = order;
      final changes = <String>[];
      if (caseStatus != null && caseStatus != order.status) {
        if (!OrderWorkflow.canChangeCaseStatus(
          from: order.status,
          to: caseStatus,
        )) {
          skipped.add(
            BatchUpdateSkip(
              orderId: order.id ?? '-',
              planName: order.planName,
              userId: uid,
              reason: '案件狀態不可由 ${order.status} 轉為 $caseStatus',
            ),
          );
          continue;
        }
        next = next.copyWith(status: caseStatus);
        changes.add('status ${order.status} -> $caseStatus');
      }
      final currentPayment = order.paymentStatus ?? 'checkout_created';
      if (paymentStatus != null && paymentStatus != order.paymentStatus) {
        if (!OrderWorkflow.canChangePaymentStatus(
          from: currentPayment,
          to: paymentStatus,
        )) {
          skipped.add(
            BatchUpdateSkip(
              orderId: order.id ?? '-',
              planName: order.planName,
              userId: uid,
              reason: '付款狀態不可由 $currentPayment 轉為 $paymentStatus',
            ),
          );
          continue;
        }
        next = next.copyWith(
          paymentStatus: paymentStatus,
          paidAt: paymentStatus == 'paid' ? DateTime.now() : next.paidAt,
        );
        changes.add('payment ${order.paymentStatus ?? '-'} -> $paymentStatus');
      }
      if (changes.isEmpty) {
        skipped.add(
          BatchUpdateSkip(
            orderId: order.id ?? '-',
            planName: order.planName,
            userId: uid,
            reason: '沒有可更新的欄位',
          ),
        );
        continue;
      }
      if (next.status == 'complete' && !OrderWorkflow.canMarkComplete(next)) {
        skipped.add(
          BatchUpdateSkip(
            orderId: order.id ?? '-',
            planName: order.planName,
            userId: uid,
            reason: 'complete 需要 payment=paid 且已交付里程碑為 done',
          ),
        );
        continue;
      }
      final now = DateTime.now();
      final editor = (actor == null || actor.isEmpty) ? 'admin' : actor;
      final log = VerificationLog(
        actor: editor,
        actedAt: now,
        summary: 'batch: ${changes.join(' | ')}',
        fromStatus: order.status,
        toStatus: next.status,
        fromPaymentStatus: order.paymentStatus,
        toPaymentStatus: next.paymentStatus,
      );
      next = next.copyWith(
        verifiedBy: editor,
        verifiedAt: now,
        verificationLogs: [...order.verificationLogs, log],
      );
      await updateOrder(uid: uid, purchase: next);
      updatedCount++;
    }
    return BatchUpdateReport(
      selectedCount: purchases.length,
      updatedCount: updatedCount,
      skipped: skipped,
    );
  }
}
