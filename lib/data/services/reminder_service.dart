import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/draft_models.dart';
import 'notification_service.dart';

class ReminderResult {
  const ReminderResult({
    required this.users,
    required this.notifications,
    required this.channel,
  });

  final List<String> users;
  final int notifications;
  final String channel;
}

class ReminderService {
  ReminderService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService.instance;

  static final ReminderService instance = ReminderService();

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  Future<ReminderResult> pushReminders({
    required String channel,
    int limit = 80,
  }) async {
    final pending = await _notificationService.fetchPending(limit: limit);
    final now = DateTime.now();
    final userIds = <String>{};
    final batch = _firestore.batch();

    for (final event in pending) {
      if (userIds.contains(event.userId)) continue;
      userIds.add(event.userId);
      final reminderDoc = _firestore.collection('notifications').doc();
      final reminder = NotificationEvent(
        userId: event.userId,
        channel: channel,
        status: 'reminder',
        occurredAt: now,
        tone: event.tone,
        draftType: event.draftType,
      );
      batch.set(reminderDoc, reminder.toMap());
      final metaDoc = _firestore
          .collection('users')
          .doc(event.userId)
          .collection('meta')
          .doc('stats');
      batch.set(metaDoc, {'lastReminderAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    }

    if (userIds.isEmpty) {
      return ReminderResult(users: const [], notifications: 0, channel: channel);
    }

    await batch.commit();
    return ReminderResult(
      users: userIds.toList(),
      notifications: userIds.length,
      channel: channel,
    );
  }
}
