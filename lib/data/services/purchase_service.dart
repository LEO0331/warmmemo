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
    'awaiting_checkout': {'awaiting_checkout', 'checkout_created', 'cancelled', 'expired'},
    'checkout_created': {'checkout_created', 'paid', 'failed', 'cancelled', 'expired'},
    'paid': {'paid'},
    'failed': {'failed', 'checkout_created'},
    'cancelled': {'cancelled', 'checkout_created'},
    'expired': {'expired', 'checkout_created'},
  };

  static bool canChangeCaseStatus({required String from, required String to}) {
    return _caseTransitions[from]?.contains(to) ?? false;
  }

  static bool canChangePaymentStatus({required String from, required String to}) {
    return _paymentTransitions[from]?.contains(to) ?? false;
  }
}

class PurchaseService {
  PurchaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final PurchaseService instance = PurchaseService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<Purchase> createOrder({
    required String uid,
    required Purchase purchase,
  }) async {
    final doc = await _users.doc(uid).collection('orders').add(
          purchase.copyWith(userId: uid).toMap(),
        );
    return purchase.copyWith(
      id: doc.id,
      userId: uid,
      docPath: doc.path,
    );
  }

  Stream<List<Purchase>> userOrders(String uid) {
    return _users
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Purchase.fromMap(doc.data(), id: doc.id, docPath: doc.reference.path))
            .toList());
  }

  Stream<List<Purchase>> adminOrders() {
    return _firestore.collectionGroup('orders').snapshots().map(
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
        .map((doc) => Purchase.fromMap(
              doc.data(),
              id: doc.id,
              userId: doc.reference.parent.parent?.id,
              docPath: doc.reference.path,
            ))
        .toList();
    final nextCursor =
        snapshot.docs.isNotEmpty ? snapshot.docs.last.reference.path : null;
    return (items: items, cursor: nextCursor);
  }

  Future<void> updateOrder({
    required String uid,
    required Purchase purchase,
  }) async {
    if (purchase.id == null) return;
    final docPath = purchase.docPath;
    if (docPath != null && docPath.isNotEmpty) {
      await _firestore.doc(docPath).set(purchase.toMap(), SetOptions(merge: true));
      return;
    }
    await _users.doc(uid).collection('orders').doc(purchase.id).set(
      purchase.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<int> adminBatchUpdate({
    required List<Purchase> purchases,
    String? caseStatus,
    String? paymentStatus,
    String? actor,
  }) async {
    if (purchases.isEmpty) return 0;
    var updatedCount = 0;
    for (final order in purchases) {
      final uid = order.userId;
      if (uid == null || uid.isEmpty) continue;
      var next = order;
      final changes = <String>[];
      if (caseStatus != null && caseStatus != order.status) {
        if (!OrderWorkflow.canChangeCaseStatus(from: order.status, to: caseStatus)) {
          continue;
        }
        next = next.copyWith(status: caseStatus);
        changes.add('status ${order.status} -> $caseStatus');
      }
      final currentPayment = order.paymentStatus ?? 'checkout_created';
      if (paymentStatus != null && paymentStatus != order.paymentStatus) {
        if (!OrderWorkflow.canChangePaymentStatus(from: currentPayment, to: paymentStatus)) {
          continue;
        }
        next = next.copyWith(
          paymentStatus: paymentStatus,
          paidAt: paymentStatus == 'paid' ? DateTime.now() : next.paidAt,
        );
        changes.add('payment ${order.paymentStatus ?? '-'} -> $paymentStatus');
      }
      if (changes.isEmpty) continue;
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
    return updatedCount;
  }
}
