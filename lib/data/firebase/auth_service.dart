import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show debugPrint;

import '../services/user_role_service.dart';

/// A thin wrapper around Firebase Authentication.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    Future<void> Function(User user)? ensureUserProfile,
    bool Function()? isWeb,
    String? persistenceMode,
    Future<void> Function(Persistence persistence)? setPersistence,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _ensureUserProfile =
            ensureUserProfile ?? UserRoleService.instance.ensureUserProfile,
        _isWeb = isWeb ?? (() => kIsWeb),
        _persistenceMode = persistenceMode,
        _setPersistence = setPersistence;

  static final AuthService instance = AuthService();

  final FirebaseAuth _auth;
  final Future<void> Function(User user) _ensureUserProfile;
  final bool Function() _isWeb;
  final String? _persistenceMode;
  final Future<void> Function(Persistence persistence)? _setPersistence;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> configurePersistence() async {
    if (!_isWeb()) return;
    // Default to SESSION so shared/public devices won't keep previous user signed in
    // after the browser tab/window is closed.
    // Override with: --dart-define=WARMEMO_AUTH_PERSISTENCE=LOCAL
    const configured = String.fromEnvironment(
      'WARMEMO_AUTH_PERSISTENCE',
      defaultValue: 'SESSION',
    );
    final mode = _persistenceMode ?? configured;
    final normalized = mode.trim().toUpperCase();
    final persistence =
        normalized == 'SESSION' ? Persistence.SESSION : Persistence.LOCAL;
    await (_setPersistence?.call(persistence) ?? _auth.setPersistence(persistence));
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

  Future<UserCredential> signIn({required String email, required String password}) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      try {
        await _ensureUserProfile(user);
      } catch (error) {
        // Keep account creation successful; app shell will retry profile bootstrap later.
        debugPrint('ensureUserProfile(signUp) skipped: $error');
      }
    }
    return credential;
  }

  Future<void> signOut() => _auth.signOut();
}
