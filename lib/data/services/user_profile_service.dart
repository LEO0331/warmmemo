import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static final UserProfileService instance = UserProfileService();

  static const onboardingStepSelectService = 'select_service';
  static const onboardingStepFirstDraft = 'first_draft';
  static const onboardingStepTokenSeen = 'token_seen';
  static const onboardingTotalSteps = 3;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _topupRequests(String uid) =>
      _userDoc(uid).collection('topupRequests');

  Stream<Map<String, dynamic>?> profileStream(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) => snapshot.data());
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return snapshot.data();
  }

  Future<void> setSelectedService(String uid, String service) {
    return _userDoc(uid).set(
      {
        'onboardingSelectedService': service,
        'onboardingUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ).then((_) => markOnboardingStep(uid, onboardingStepSelectService));
  }

  Future<void> markOnboardingStep(String uid, String step) async {
    final docRef = _userDoc(uid);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      final currentSteps = (snapshot.data()?['onboardingSteps'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();
      if (!currentSteps.contains(step)) {
        currentSteps.add(step);
      }
      tx.set(
        docRef,
        {
          'onboardingSteps': currentSteps,
          'onboardingUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  int completedStepsCount(Map<String, dynamic>? profile) {
    final steps =
        (profile?['onboardingSteps'] as List<dynamic>? ?? const []).whereType<String>().toSet();
    var count = 0;
    if (steps.contains(onboardingStepSelectService)) count++;
    if (steps.contains(onboardingStepFirstDraft)) count++;
    if (steps.contains(onboardingStepTokenSeen)) count++;
    return count;
  }

  Future<void> submitTopUpRequest({
    required String uid,
    required int requestedTokens,
    String? note,
  }) {
    return _topupRequests(uid).add(
      {
        'requestedTokens': requestedTokens,
        'note': (note ?? '').trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
