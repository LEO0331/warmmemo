import 'dart:developer' as developer;

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
        .copyWith(userId: uid, schemaVersion: Purchase.currentSchemaVersion)
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
    return snapshot.docs
        .map(
          (doc) => Purchase.fromMap(
            doc.data(),
            id: doc.id,
            docPath: doc.reference.path,
          ),
        )
        .toList();
  }

  Stream<List<Purchase>> adminOrders() {
    return _firestore
        .collectionGroup('orders')
        .snapshots()
        .map((snapshot) => _readAdminOrders(snapshot));
  }

  List<Purchase> _readAdminOrders(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = <Purchase>[];
    var invalidCount = 0;
    for (final doc in snapshot.docs) {
      final order = _readAdminOrder(doc, doc.data());
      if (order == null) {
        invalidCount++;
      } else {
        items.add(order);
      }
    }
    if (invalidCount > 0) {
      developer.log(
        'Skipped $invalidCount malformed order documents.',
        name: 'PurchaseService',
      );
    }
    return items;
  }

  Purchase? _readAdminOrder(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
  ) {
    try {
      return Purchase.fromMap(
        data,
        id: doc.id,
        userId: doc.reference.parent.parent?.id,
        docPath: doc.reference.path,
      );
    } on TypeError {
      return null;
    } on UnsupportedError {
      return null; // Firestore can store non-finite numbers that cannot become ints.
    }
  }

  Future<({List<Purchase> items, String? cursor})> adminOrdersPage({
    int limit = 5,
    String? startAfterDocPath,
  }) async {
    final snapshot = await _firestore.collectionGroup('orders').get();
    final items = _readAdminOrders(snapshot);
    items.sort((a, b) {
      final byCreatedAt = b.createdAt.compareTo(a.createdAt);
      if (byCreatedAt != 0) {
        return byCreatedAt;
      }
      return (b.docPath ?? '').compareTo(a.docPath ?? '');
    });
    final startIndex = startAfterDocPath == null
        ? 0
        : _findAdminOrdersStartIndex(
            items,
            cursor: _decodeAdminOrdersCursor(startAfterDocPath),
          );
    final pageItems = items.skip(startIndex).take(limit).toList();
    await _backfillSchemaIfNeeded(pageItems);
    final nextCursor = pageItems.isNotEmpty
        ? _encodeAdminOrdersCursor(
            createdAtIso: pageItems.last.createdAt.toIso8601String(),
            docPath: pageItems.last.docPath ?? '',
          )
        : null;
    return (items: pageItems, cursor: nextCursor);
  }

  String _encodeAdminOrdersCursor({
    required String createdAtIso,
    required String docPath,
  }) {
    return '$createdAtIso|$docPath';
  }

  ({String createdAtIso, String docPath}) _decodeAdminOrdersCursor(String raw) {
    final pivot = raw.indexOf('|');
    if (pivot <= 0 || pivot >= raw.length - 1) {
      throw ArgumentError(
        'Invalid admin orders cursor. Expected "<createdAt>|<docPath>".',
      );
    }
    return (
      createdAtIso: raw.substring(0, pivot),
      docPath: raw.substring(pivot + 1),
    );
  }

  int _findAdminOrdersStartIndex(
    List<Purchase> items, {
    required ({String createdAtIso, String docPath}) cursor,
  }) {
    final cursorIndex = items.indexWhere(
      (item) =>
          item.createdAt.toIso8601String() == cursor.createdAtIso &&
          (item.docPath ?? '') == cursor.docPath,
    );
    if (cursorIndex == -1) {
      throw ArgumentError('Admin orders cursor did not match any record.');
    }
    return cursorIndex + 1;
  }

  Future<void> _backfillSchemaIfNeeded(List<Purchase> items) async {
    for (final order in items.where((order) => order.needsSchemaMigration)) {
      final ref = _firestore.doc(order.docPath!);
      try {
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          final data = snapshot.data();
          if (data == null) return;
          final current = _readAdminOrder(snapshot, data);
          if (current == null || !current.needsSchemaMigration) return;
          final normalized = current.normalizedForStorage();
          transaction.update(ref, {
            'schemaVersion': normalized.schemaVersion,
            'priceAmount': normalized.priceAmount,
          });
        });
      } on FirebaseException catch (error) {
        developer.log(
          'Order schema backfill failed (${error.code}).',
          name: 'PurchaseService',
        );
      }
    }
  }

  Future<void> updateOrderProposal({
    required String uid,
    required Purchase purchase,
  }) async {
    if (purchase.id == null) return;
    final proposal = purchase.proposal;
    await _orderRef(uid, purchase).update({
      'proposal': proposal == null || proposal.isEmpty
          ? null
          : proposal.toMap(),
    });
  }

  Future<void> updateOrderCheckout({
    required String uid,
    required Purchase purchase,
  }) async {
    if (purchase.id == null) return;
    await _orderRef(uid, purchase).update({
      'paymentProvider': purchase.paymentProvider,
      'paymentStatus': purchase.paymentStatus,
      'invoiceId': purchase.invoiceId,
      'checkoutUrl': purchase.checkoutUrl,
      'paymentCurrency': purchase.paymentCurrency,
    });
  }

  DocumentReference<Map<String, dynamic>> _orderRef(
    String uid,
    Purchase order,
  ) {
    final path = order.docPath;
    return path != null && path.isNotEmpty
        ? _firestore.doc(path)
        : _users.doc(uid).collection('orders').doc(order.id);
  }

  Future<void> updateOrder({
    required String uid,
    required Purchase purchase,
    String? mutationId,
  }) async {
    if (purchase.id == null) return;
    final targetRef = _orderRef(uid, purchase);

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
