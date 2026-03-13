import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple wrapper for storing the single memorial and obituary drafts.
class DraftStorage {
  DraftStorage._(this._prefs);

  static DraftStorage? _instance;

  final SharedPreferences _prefs;

  static Future<DraftStorage> get instance async {
    return _instance ??= DraftStorage._(await SharedPreferences.getInstance());
  }

  static const _memorialKey = 'draft_memorial';
  static const _obituaryKey = 'draft_obituary';

  MemorialDraft? loadMemorialDraft() {
    final raw = _prefs.getString(_memorialKey);
    if (raw == null) return null;
    return MemorialDraft.fromJson(jsonDecode(raw));
  }

  ObituaryDraft? loadObituaryDraft() {
    final raw = _prefs.getString(_obituaryKey);
    if (raw == null) return null;
    return ObituaryDraft.fromJson(jsonDecode(raw));
  }

  Future<void> saveMemorialDraft(MemorialDraft draft) async {
    final serialized = jsonEncode(draft.toJson());
    await _prefs.setString(_memorialKey, serialized);
  }

  Future<void> saveObituaryDraft(ObituaryDraft draft) async {
    final serialized = jsonEncode(draft.toJson());
    await _prefs.setString(_obituaryKey, serialized);
  }
}

class MemorialDraft {
  MemorialDraft({
    this.name,
    this.nickname,
    this.motto,
    this.bio,
    this.highlights,
    this.willNote,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String? name;
  final String? nickname;
  final String? motto;
  final String? bio;
  final String? highlights;
  final String? willNote;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'name': name,
        'nickname': nickname,
        'motto': motto,
        'bio': bio,
        'highlights': highlights,
        'willNote': willNote,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MemorialDraft.fromJson(Map<String, dynamic> map) => MemorialDraft(
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
  ObituaryDraft({
    this.deceasedName,
    this.relationship,
    this.location,
    this.serviceDate,
    this.tone,
    this.customNote,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String? deceasedName;
  final String? relationship;
  final String? location;
  final String? serviceDate;
  final String? tone;
  final String? customNote;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'deceasedName': deceasedName,
        'relationship': relationship,
        'location': location,
        'serviceDate': serviceDate,
        'tone': tone,
        'customNote': customNote,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ObituaryDraft.fromJson(Map<String, dynamic> map) => ObituaryDraft(
        deceasedName: map['deceasedName'] as String?,
        relationship: map['relationship'] as String?,
        location: map['location'] as String?,
        serviceDate: map['serviceDate'] as String?,
        tone: map['tone'] as String?,
        customNote: map['customNote'] as String?,
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      );
}
