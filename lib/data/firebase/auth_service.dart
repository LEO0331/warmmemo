import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_role_service.dart';

/// A thin wrapper around Firebase Authentication.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool isEmailPasswordUser(User user) {
    if (user.providerData.isEmpty) return true;
    return user.providerData.any((provider) => provider.providerId == 'password');
  }

  Future<bool> get isAdmin async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.claims?['admin'] == true;
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password).then((credential) {
      final user = credential.user;
      if (user != null) {
        UserRoleService.instance.ensureUserProfile(user);
      }
      return credential;
    });
  }

  Future<UserCredential> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password).then((credential) {
      final user = credential.user;
      if (user != null) {
        UserRoleService.instance.ensureUserProfile(user);
      }
      return credential;
    });
  }

  Future<void> signOut() => _auth.signOut();
}
