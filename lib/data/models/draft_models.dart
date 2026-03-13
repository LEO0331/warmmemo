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
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MemorialDraft.fromMap(Map<String, dynamic> map) => MemorialDraft(
        name: map['name'] as String?,
        nickname: map['nickname'] as String?,
        motto: map['motto'] as String?,
        bio: map['bio'] as String?,
        highlights: map['highlights'] as String?,
        willNote: map['willNote'] as String?,
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
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
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ObituaryDraft.fromMap(Map<String, dynamic> map) => ObituaryDraft(
        deceasedName: map['deceasedName'] as String?,
        relationship: map['relationship'] as String?,
        location: map['location'] as String?,
        serviceDate: map['serviceDate'] as String?,
        tone: map['tone'] as String?,
        customNote: map['customNote'] as String?,
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
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
