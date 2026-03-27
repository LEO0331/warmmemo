import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/purchase.dart';

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
