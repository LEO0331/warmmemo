import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'token_wallet_service.dart';

class UserRoleService {
  UserRoleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final UserRoleService instance = UserRoleService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<void> ensureUserProfile(User user) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    final currentRole = snapshot.data()?['role'] as String?;
    final currentTokens = (snapshot.data()?['tokenBalance'] as num?)?.toInt();
    final bootstrapPayload = {
      if (user.email != null) 'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      if (currentRole == null) 'role': 'user',
      if (currentTokens == null) 'tokenBalance': TokenWalletService.starterTokens,
      if (currentTokens == null) 'tokenGrantedAt': FieldValue.serverTimestamp(),
      if (currentTokens == null) 'tokenUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (bootstrapPayload.isNotEmpty) {
      await doc.set(bootstrapPayload, SetOptions(merge: true));
    }

    final onboardingPayload = {
      if (snapshot.data()?['onboardingSteps'] == null) 'onboardingSteps': <String>[],
      if (snapshot.data()?['onboardingSelectedService'] == null) 'onboardingSelectedService': null,
      if (snapshot.data()?['onboardingUpdatedAt'] == null)
        'onboardingUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (onboardingPayload.isNotEmpty) {
      await doc.set(onboardingPayload, SetOptions(merge: true));
    }
  }

  Stream<String> roleStream(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return (data?['role'] as String?) ?? 'user';
    });
  }

  Future<void> ensureAdminDoc(String uid) async {
    final doc = _firestore.collection('admins').doc(uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;
    await doc.set(
      {'updatedAt': FieldValue.serverTimestamp()},
    );
  }

  Future<bool> adminDocExists(String uid) async {
    final snapshot = await _firestore.collection('admins').doc(uid).get();
    return snapshot.exists;
  }
}
