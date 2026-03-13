import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/purchase.dart';

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<void> createOrder({
    required String uid,
    required Purchase purchase,
  }) async {
    await _users.doc(uid).collection('orders').add(
          purchase.copyWith(userId: uid).toMap(),
        );
  }

  Stream<List<Purchase>> userOrders(String uid) {
    return _users
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Purchase.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Stream<List<Purchase>> adminOrders() {
    return _firestore.collectionGroup('orders').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final userId = doc.reference.parent.parent?.id;
        return Purchase.fromMap(doc.data(), id: doc.id, userId: userId);
      }).toList(),
    );
  }

  Future<({List<Purchase> items, String? cursor})> adminOrdersPage({
    int limit = 20,
    String? startAfterCreatedAt,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfterCreatedAt != null) {
      query = query.startAfter([startAfterCreatedAt]);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => Purchase.fromMap(doc.data(),
            id: doc.id, userId: doc.reference.parent.parent?.id))
        .toList();
    final nextCursor =
        snapshot.docs.isNotEmpty ? snapshot.docs.last.data()['createdAt'] as String? : null;
    return (items: items, cursor: nextCursor);
  }

  Future<void> updateOrder({
    required String uid,
    required Purchase purchase,
  }) async {
    if (purchase.id == null) return;
    await _users.doc(uid).collection('orders').doc(purchase.id).set(
          purchase.toMap(),
          SetOptions(merge: true),
        );
  }
}
