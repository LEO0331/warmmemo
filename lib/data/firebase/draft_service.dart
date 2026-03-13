import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_models.dart';
import '../models/draft_models.dart';

class FirebaseDraftService {
  FirebaseDraftService._();

  static final FirebaseDraftService instance = FirebaseDraftService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  DocumentReference<Map<String, dynamic>> _memorialDoc(String uid) =>
      _users.doc(uid).collection('drafts').doc('memorial');

  DocumentReference<Map<String, dynamic>> _obituaryDoc(String uid) =>
      _users.doc(uid).collection('drafts').doc('obituary');

  DocumentReference<Map<String, dynamic>> _statsDoc(String uid) =>
      _users.doc(uid).collection('meta').doc('stats');

  Future<MemorialDraft?> loadMemorial(String uid) async {
    final snapshot = await _memorialDoc(uid).get();
    if (!snapshot.exists) return null;
    return MemorialDraft.fromMap(snapshot.data()!);
  }

  Future<void> saveMemorial(String uid, MemorialDraft draft) {
    return _memorialDoc(uid)
        .set(draft.toMap(), SetOptions(merge: true))
        .then((_) => _touchUserDoc(uid));
  }

  Future<ObituaryDraft?> loadObituary(String uid) async {
    final snapshot = await _obituaryDoc(uid).get();
    if (!snapshot.exists) return null;
    return ObituaryDraft.fromMap(snapshot.data()!);
  }

  Future<void> saveObituary(String uid, ObituaryDraft draft) {
    return _obituaryDoc(uid)
        .set(draft.toMap(), SetOptions(merge: true))
        .then((_) => _touchUserDoc(uid));
  }

  Future<DraftStats> loadStats(String uid) async {
    final snapshot = await _statsDoc(uid).get();
    if (!snapshot.exists) return DraftStats(readCount: 0, clickCount: 0);
    return DraftStats.fromMap(snapshot.data()!);
  }

  Future<void> incrementStats(String uid,
      {int readDelta = 0, int clickDelta = 0}) {
    final data = <String, Object>{};
    if (readDelta != 0) data['readCount'] = FieldValue.increment(readDelta);
    if (clickDelta != 0) data['clickCount'] = FieldValue.increment(clickDelta);
    if (data.isEmpty) return Future.value();
    return _statsDoc(uid).set(data, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> adminOverview() {
    return _users.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => {
              'uid': doc.id,
              'updatedAt': doc.data()['updatedAt'] as Timestamp?,
              'drafts': doc.data()['drafts'],
            })
        .toList());
  }

  Future<List<NotificationEvent>> fetchNotificationHistory({int limit = 500}) async {
    final snapshot = await _notifications
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => NotificationEvent.fromMap(doc.data()))
        .toList();
  }

  Stream<DraftMetrics> adminMetricsStream() {
    return _firestore.collectionGroup('stats').snapshots().map((snapshot) {
      final userIds = <String>{};
      var totalReads = 0;
      var totalClicks = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        userIds.add(doc.reference.parent.parent?.id ?? 'unknown');
        totalReads += data['readCount'] as int? ?? 0;
        totalClicks += data['clickCount'] as int? ?? 0;
      }

      return DraftMetrics(
        totalUsers: userIds.length,
        totalReads: totalReads,
        totalClicks: totalClicks,
      );
    });
  }

  Stream<List<NotificationEvent>> notificationTimeline({int limit = 20}) {
    return _notifications
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationEvent.fromMap(doc.data()))
            .toList());
  }

  Future<void> logNotificationEvent(NotificationEvent event) {
    return _notifications.add(event.toMap());
  }

  Future<void> _touchUserDoc(String uid) {
    return _users.doc(uid).set(
          {'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
  }

  Future<List<UserComplianceSnapshot>> fetchUserSummaries({int limit = 120}) async {
    final snapshot = await _users.limit(limit).get();
    final summaries = await Future.wait(snapshot.docs.map((doc) async {
      final drafts = doc.reference.collection('drafts');
      final memorialSnapshot = await drafts.doc('memorial').get();
      final obituarySnapshot = await drafts.doc('obituary').get();
      final statsSnapshot = await doc.reference.collection('meta').doc('stats').get();

      final memorial = memorialSnapshot.exists ? MemorialDraft.fromMap(memorialSnapshot.data()!) : null;
      final obituary = obituarySnapshot.exists ? ObituaryDraft.fromMap(obituarySnapshot.data()!) : null;
      final stats = statsSnapshot.exists
          ? DraftStats.fromMap(statsSnapshot.data()!)
          : DraftStats(readCount: 0, clickCount: 0);

      return UserComplianceSnapshot(
        userId: doc.id,
        memorialDraft: memorial,
        obituaryDraft: obituary,
        stats: stats,
        lastReminderAt: _parseTimestamp(statsSnapshot.data()?['lastReminderAt']),
      );
    }));
    return summaries;
  }

  DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
