import 'package:cloud_firestore/cloud_firestore.dart';

class InputAnalyticsService {
  InputAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final InputAnalyticsService instance = InputAnalyticsService();

  final FirebaseFirestore _firestore;

  Future<void> trackFieldError({
    required String uid,
    required String screen,
    required String field,
    required String errorCode,
    String? message,
  }) async {
    if (uid.trim().isEmpty) return;
    final eventKey =
        '${_safeKey(screen)}__${_safeKey(field)}__${_safeKey(errorCode)}';
    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('inputValidationAnalytics');
    await docRef.set({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastEvent': {
        'screen': screen,
        'field': field,
        'errorCode': errorCode,
        'message': message,
        'occurredAt': FieldValue.serverTimestamp(),
      },
      'counters.$eventKey': FieldValue.increment(1),
      'dailyCounters.$dayKey.$eventKey': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  String _safeKey(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'unknown';
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }
}
