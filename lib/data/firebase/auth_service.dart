import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/user_role_service.dart';

/// A thin wrapper around Firebase Authentication.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    Future<void> Function(User user)? ensureUserProfile,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _ensureUserProfile = ensureUserProfile ?? UserRoleService.instance.ensureUserProfile;

  static final AuthService instance = AuthService();

  final FirebaseAuth _auth;
  final Future<void> Function(User user) _ensureUserProfile;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> configurePersistence() async {
    if (!kIsWeb) return;
    // Default to SESSION so shared/public devices won't keep previous user signed in
    // after the browser tab/window is closed.
    // Override with: --dart-define=WARMEMO_AUTH_PERSISTENCE=LOCAL
    const mode = String.fromEnvironment(
      'WARMEMO_AUTH_PERSISTENCE',
      defaultValue: 'SESSION',
    );
    final normalized = mode.trim().toUpperCase();
    final persistence =
        normalized == 'SESSION' ? Persistence.SESSION : Persistence.LOCAL;
    await _auth.setPersistence(persistence);
  }

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
        _ensureUserProfile(user);
      }
      return credential;
    });
  }

  Future<UserCredential> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password).then((credential) {
      final user = credential.user;
      if (user != null) {
        _ensureUserProfile(user);
      }
      return credential;
    });
  }

  Future<void> signOut() => _auth.signOut();
}
