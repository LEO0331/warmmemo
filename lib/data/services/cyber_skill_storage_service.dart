import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cyber_skill.dart';

class CyberSkillStorageService {
  CyberSkillStorageService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final CyberSkillStorageService instance = CyberSkillStorageService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _skills(String uid) =>
      _firestore.collection('users').doc(uid).collection('cyberSkills');

  Stream<List<SavedCyberSkill>> watchSkills(String uid) {
    return _skills(uid).snapshots().map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => SavedCyberSkill.fromMap(doc.data(), id: doc.id))
          .toList();
      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries;
    });
  }

  Future<SavedCyberSkill> saveSkill({
    required String uid,
    required TemplateType templateType,
    required CyberSkillProfile profile,
    required CyberSkillAnalysis analysis,
    required String markdown,
    String version = 'v1',
    String? existingId,
  }) async {
    final now = DateTime.now();
    final ref = existingId == null
        ? _skills(uid).doc()
        : _skills(uid).doc(existingId);
    final createdAt = await _resolveCreatedAt(ref, fallback: now);
    final summary = _buildAnalysisSummary(analysis);
    final payload = SavedCyberSkill(
      id: ref.id,
      templateType: templateType,
      profileName: profile.name,
      profileIdentity: profile.identityLine,
      analysisSummary: summary,
      markdown: markdown,
      version: version,
      createdAt: createdAt,
      updatedAt: now,
    );
    await ref.set(payload.toMap(), SetOptions(merge: true));
    return payload;
  }

  Future<void> deleteSkill({
    required String uid,
    required String skillId,
  }) async {
    await _skills(uid).doc(skillId).delete();
  }

  Map<String, dynamic> _buildAnalysisSummary(CyberSkillAnalysis analysis) {
    return <String, dynamic>{
      'toneTraits': analysis.toneTraits.take(5).toList(),
      'decisionPriorities': analysis.decisionPriorities.take(5).toList(),
      'workMethods': analysis.workMethods.take(5).toList(),
      'boundaries': analysis.boundaries.take(5).toList(),
      'sourceStats': analysis.sourceStats,
    };
  }

  Future<DateTime> _resolveCreatedAt(
    DocumentReference<Map<String, dynamic>> ref, {
    required DateTime fallback,
  }) async {
    if (!(await ref.get()).exists) return fallback;
    final current = await ref.get();
    final raw = current.data()?['createdAt'];
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return fallback;
  }
}
