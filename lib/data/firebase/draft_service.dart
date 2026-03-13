import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/draft_models.dart';

class FirebaseDraftService {
  FirebaseDraftService._();

  static final FirebaseDraftService instance = FirebaseDraftService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

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

  Future<void> _touchUserDoc(String uid) {
    return _users.doc(uid).set(
          {'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
  }
}
