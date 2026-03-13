import 'package:cloud_firestore/cloud_firestore.dart';

class MemorialDraft {
  MemorialDraft(
      {this.name,
      this.nickname,
      this.motto,
      this.bio,
      this.highlights,
      this.willNote,
      DateTime? updatedAt})
      : updatedAt = updatedAt ?? DateTime.now();

  final String? name;
  final String? nickname;
  final String? motto;
  final String? bio;
  final String? highlights;
  final String? willNote;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'name': name,
        'nickname': nickname,
        'motto': motto,
        'bio': bio,
        'highlights': highlights,
        'willNote': willNote,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory MemorialDraft.fromMap(Map<String, dynamic> map) => MemorialDraft(
        name: map['name'] as String?,
        nickname: map['nickname'] as String?,
        motto: map['motto'] as String?,
        bio: map['bio'] as String?,
        highlights: map['highlights'] as String?,
        willNote: map['willNote'] as String?,
        updatedAt: _parseDate(map['updatedAt']),
      );
}

class ObituaryDraft {
  ObituaryDraft(
      {this.deceasedName,
      this.relationship,
      this.location,
      this.serviceDate,
      this.tone,
      this.customNote,
      DateTime? updatedAt})
      : updatedAt = updatedAt ?? DateTime.now();

  final String? deceasedName;
  final String? relationship;
  final String? location;
  final String? serviceDate;
  final String? tone;
  final String? customNote;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'deceasedName': deceasedName,
        'relationship': relationship,
        'location': location,
        'serviceDate': serviceDate,
        'tone': tone,
        'customNote': customNote,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ObituaryDraft.fromMap(Map<String, dynamic> map) => ObituaryDraft(
        deceasedName: map['deceasedName'] as String?,
        relationship: map['relationship'] as String?,
        location: map['location'] as String?,
        serviceDate: map['serviceDate'] as String?,
        tone: map['tone'] as String?,
        customNote: map['customNote'] as String?,
        updatedAt: _parseDate(map['updatedAt']),
      );
}

class DraftStats {
  DraftStats({required this.readCount, required this.clickCount});

  final int readCount;
  final int clickCount;

  Map<String, Object?> toMap() => {
        'readCount': readCount,
        'clickCount': clickCount,
      };

  factory DraftStats.fromMap(Map<String, dynamic> map) => DraftStats(
        readCount: map['readCount'] as int? ?? 0,
        clickCount: map['clickCount'] as int? ?? 0,
      );
}

class DraftMetrics {
  DraftMetrics({required this.totalUsers, required this.totalReads, required this.totalClicks});

  final int totalUsers;
  final int totalReads;
  final int totalClicks;
}

class NotificationEvent {
  NotificationEvent({
    required this.userId,
    required this.channel,
    required this.status,
    required this.occurredAt,
    this.tone,
    this.draftType,
  });

  final String userId;
  final String channel;
  final String status;
  final DateTime occurredAt;
  final String? tone;
  final String? draftType;

  Map<String, Object?> toMap() => {
        'userId': userId,
        'channel': channel,
        'status': status,
        'occurredAt': Timestamp.fromDate(occurredAt),
        'tone': tone,
        'draftType': draftType,
      };

  factory NotificationEvent.fromMap(Map<String, dynamic> map) => NotificationEvent(
        userId: map['userId'] as String? ?? 'unknown',
        channel: map['channel'] as String? ?? 'email',
        status: map['status'] as String? ?? 'pending',
        occurredAt: _parseDate(map['occurredAt']),
        tone: map['tone'] as String?,
        draftType: map['draftType'] as String?,
      );
}

DateTime _parseDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}
