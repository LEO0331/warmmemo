import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/draft_models.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<NotificationEvent>> timeline({int limit = 50}) {
    return _notifications
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationEvent.fromMap(doc.data())).toList());
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
    return snapshot.docs.map((doc) => NotificationEvent.fromMap(doc.data())).toList();
  }

  Future<List<NotificationEvent>> fetchPending({int limit = 200}) async {
    final snapshot = await _notifications
        .where('status', isEqualTo: 'pending')
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => NotificationEvent.fromMap(doc.data())).toList();
  }

  Future<List<NotificationEvent>> fetchForUser(String userId, {int limit = 100}) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => NotificationEvent.fromMap(doc.data())).toList();
  }

  Stream<List<NotificationEvent>> streamForUser(String userId, {int limit = 12}) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationEvent.fromMap(doc.data())).toList());
  }

  Future<void> logEvent(NotificationEvent event) {
    return _notifications.add(event.toMap());
  }
}
