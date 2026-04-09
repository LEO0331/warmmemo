import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    String? existingId,
  }) async {
    final now = DateTime.now().toUtc();
    final ref = existingId == null
        ? _skills(uid).doc()
        : _skills(uid).doc(existingId);
    final current = await ref.get();
    final createdAt = _resolveCreatedAt(current.data(), fallback: now);
    final nextVersion = _nextVersion(current.data()?['version'] as String?);
    final summary = _buildAnalysisSummary(analysis);
    final payload = SavedCyberSkill(
      id: ref.id,
      templateType: templateType,
      profileName: _limit(profile.name, 80),
      profileIdentity: _limit(profile.identityLine, 160),
      analysisSummary: summary,
      markdown: _limit(markdown, 20000),
      version: nextVersion,
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

  DateTime _resolveCreatedAt(
    Map<String, dynamic>? currentData, {
    required DateTime fallback,
  }) {
    final raw = currentData?['createdAt'];
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
    }
    return fallback;
  }

  String _nextVersion(String? raw) {
    final fallback = 'v000001';
    if (raw == null || raw.isEmpty) return fallback;
    final matched = RegExp(r'^v(\d{6})$').firstMatch(raw.trim());
    if (matched == null) return fallback;
    final current = int.tryParse(matched.group(1)!);
    if (current == null || current >= 999999) return fallback;
    final next = current + 1;
    final version = 'v${next.toString().padLeft(6, '0')}';
    if (kDebugMode) {
      debugPrint('CyberSkillStorageService version advanced: $raw -> $version');
    }
    return version;
  }

  String _limit(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }
}
