import 'draft_models.dart';

class UserComplianceSnapshot {
  UserComplianceSnapshot({
    required this.userId,
    this.memorialDraft,
    this.obituaryDraft,
    required this.stats,
    this.lastReminderAt,
  });

  final String userId;
  final MemorialDraft? memorialDraft;
  final ObituaryDraft? obituaryDraft;
  final DraftStats stats;
  final DateTime? lastReminderAt;

  Map<String, Object?> toMap() => {
        'userId': userId,
        'memorialDraft': memorialDraft?.toMap(),
        'obituaryDraft': obituaryDraft?.toMap(),
        'readCount': stats.readCount,
        'clickCount': stats.clickCount,
        'lastReminderAt': lastReminderAt?.toIso8601String(),
      };
}
