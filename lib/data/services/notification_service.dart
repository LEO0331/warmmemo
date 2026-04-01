import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/draft_models.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final NotificationService instance = NotificationService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<NotificationEvent>> timeline({int limit = 50}) {
    return _notifications
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationEvent.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Stream<int> pendingCount() {
    return _notifications
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<List<NotificationEvent>> fetchHistory({int limit = 500}) async {
    final snapshot = await _notifications
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => NotificationEvent.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<NotificationEvent>> fetchPending({int limit = 200}) async {
    final snapshot = await _notifications
        .where('status', isEqualTo: 'pending')
        .limit(limit)
        .get();
    final items = snapshot.docs
        .map((doc) => NotificationEvent.fromMap(doc.data(), id: doc.id))
        .toList();
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return items;
  }

  Future<List<NotificationEvent>> fetchForUser(String userId, {int limit = 100}) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .get();
    final items = snapshot.docs
        .map((doc) => NotificationEvent.fromMap(doc.data(), id: doc.id))
        .toList();
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return items;
  }

  Stream<List<NotificationEvent>> streamForUser(String userId, {int limit = 12}) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
            .map((doc) => NotificationEvent.fromMap(doc.data(), id: doc.id))
            .toList();
          items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          return items;
        });
  }

  Future<void> logEvent(NotificationEvent event) {
    return _notifications.add(event.toMap());
  }

  Future<void> markRead(String notificationId) {
    return _notifications.doc(notificationId).set(
      {
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
