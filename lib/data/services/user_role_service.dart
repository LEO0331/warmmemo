import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRoleService {
  UserRoleService._();

  static final UserRoleService instance = UserRoleService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<void> ensureUserProfile(User user) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    final currentRole = snapshot.data()?['role'] as String?;
    final payload = {
      if (user.email != null) 'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      if (currentRole == null) 'role': 'user',
    };
    if (payload.isEmpty) return;
    await doc.set(payload, SetOptions(merge: true));
  }

  Stream<String> roleStream(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return (data?['role'] as String?) ?? 'user';
    });
  }
}
