import 'dart:convert';

enum TemplateType {
  warmmemoDaily,
  colleagueWork;

  String get wireValue => switch (this) {
    TemplateType.warmmemoDaily => 'warmmemoDaily',
    TemplateType.colleagueWork => 'colleagueWork',
  };

  String get displayLabel => switch (this) {
    TemplateType.warmmemoDaily => '日常模式',
    TemplateType.colleagueWork => '工作模式',
  };

  static TemplateType fromWire(String? value) {
    switch (value) {
      case 'colleagueWork':
        return TemplateType.colleagueWork;
      case 'warmmemoDaily':
      default:
        return TemplateType.warmmemoDaily;
    }
  }
}

class CyberSkillProfile {
  const CyberSkillProfile({
    required this.name,
    this.company,
    this.level,
    this.role,
    this.relationshipToUser,
    this.familyRole,
    this.lifeStage,
    this.residenceCity,
    this.occupation,
    this.gender,
    this.mbti,
    this.personaTags = const <String>[],
    this.cultureTags = const <String>[],
    this.personalValues = const <String>[],
    this.hobbies = const <String>[],
    this.signatureMemory,
    this.impression,
  });

  final String name;
  final String? company;
  final String? level;
  final String? role;
  final String? relationshipToUser;
  final String? familyRole;
  final String? lifeStage;
  final String? residenceCity;
  final String? occupation;
  final String? gender;
  final String? mbti;
  final List<String> personaTags;
  final List<String> cultureTags;
  final List<String> personalValues;
  final List<String> hobbies;
  final String? signatureMemory;
  final String? impression;

  String get workIdentityLine {
    final parts = <String>[
      if (_safe(company) != null) _safe(company)!,
      if (_safe(level) != null) _safe(level)!,
      if (_safe(role) != null) _safe(role)!,
    ];
    return parts.isEmpty ? '同事' : parts.join(' ');
  }

  String get warmIdentityLine {
    final parts = <String>[
      if (_safe(relationshipToUser) != null) _safe(relationshipToUser)!,
      if (_safe(familyRole) != null) _safe(familyRole)!,
      if (_safe(lifeStage) != null) _safe(lifeStage)!,
    ];
    return parts.isEmpty ? '家人般的陪伴者' : parts.join('，');
  }

  List<String> get personalContextLines => <String>[
    if (_safe(residenceCity) != null) '生活地：${_safe(residenceCity)!}',
    if (_safe(occupation) != null) '日常角色：${_safe(occupation)!}',
    if (personalValues.isNotEmpty) '重視價值：${personalValues.join('、')}',
    if (hobbies.isNotEmpty) '生活喜好：${hobbies.join('、')}',
    if (_safe(signatureMemory) != null) '代表記憶：${_safe(signatureMemory)!}',
  ];

  String get identityLine => workIdentityLine;

  Map<String, Object?> toMap() => {
    'name': name,
    'company': company,
    'level': level,
    'role': role,
    'relationshipToUser': relationshipToUser,
    'familyRole': familyRole,
    'lifeStage': lifeStage,
    'residenceCity': residenceCity,
    'occupation': occupation,
    'gender': gender,
    'mbti': mbti,
    'personaTags': personaTags,
    'cultureTags': cultureTags,
    'personalValues': personalValues,
    'hobbies': hobbies,
    'signatureMemory': signatureMemory,
    'impression': impression,
  };

  factory CyberSkillProfile.fromMap(Map<String, dynamic> map) {
    final name = _sanitizeText(map['name'] as String?, maxLength: 80);
    if (name.isEmpty) {
      throw const FormatException('profile.name 是必填欄位。');
    }
    return CyberSkillProfile(
      name: name,
      company: _safe(_sanitizeText(map['company'] as String?, maxLength: 80)),
      level: _safe(_sanitizeText(map['level'] as String?, maxLength: 40)),
      role: _safe(_sanitizeText(map['role'] as String?, maxLength: 80)),
      relationshipToUser: _safe(
        _sanitizeText(map['relationshipToUser'] as String?, maxLength: 80),
      ),
      familyRole: _safe(
        _sanitizeText(map['familyRole'] as String?, maxLength: 80),
      ),
      lifeStage: _safe(
        _sanitizeText(map['lifeStage'] as String?, maxLength: 80),
      ),
      residenceCity: _safe(
        _sanitizeText(map['residenceCity'] as String?, maxLength: 80),
      ),
      occupation: _safe(
        _sanitizeText(map['occupation'] as String?, maxLength: 80),
      ),
      gender: _safe(_sanitizeText(map['gender'] as String?, maxLength: 20)),
      mbti: _safe(_sanitizeText(map['mbti'] as String?, maxLength: 16)),
      personaTags: _stringList(map['personaTags']),
      cultureTags: _stringList(map['cultureTags']),
      personalValues: _stringList(map['personalValues']),
      hobbies: _stringList(map['hobbies']),
      signatureMemory: _safe(
        _sanitizeText(map['signatureMemory'] as String?, maxLength: 280),
      ),
      impression: _safe(
        _sanitizeText(map['impression'] as String?, maxLength: 280),
      ),
    );
  }
}

class RawMessage {
  const RawMessage({
    required this.sender,
    required this.content,
    this.timestamp,
  });

  final String sender;
  final String content;
  final String? timestamp;

  Map<String, Object?> toMap() => {
    'sender': sender,
    'content': content,
    'timestamp': timestamp,
  };

  factory RawMessage.fromMap(Map<String, dynamic> map) {
    final sender = _sanitizeText(map['sender'] as String?, maxLength: 80);
    final content = _sanitizeText(map['content'] as String?, maxLength: 4000);
    if (content.isEmpty) {
      throw const FormatException('materials.messages[].content 不可為空。');
    }
    return RawMessage(
      sender: sender.isEmpty ? 'unknown' : sender,
      content: content,
      timestamp: _safe(
        _sanitizeText(map['timestamp'] as String?, maxLength: 64),
      ),
    );
  }
}

class RawDocument {
  const RawDocument({required this.title, required this.content, this.source});

  final String title;
  final String content;
  final String? source;

  Map<String, Object?> toMap() => {
    'title': title,
    'content': content,
    'source': source,
  };

  factory RawDocument.fromMap(Map<String, dynamic> map) {
    final content = _sanitizeText(map['content'] as String?, maxLength: 12000);
    if (content.isEmpty) {
      throw const FormatException('materials.documents[].content 不可為空。');
    }
    final title = _sanitizeText(map['title'] as String?, maxLength: 120);
    return RawDocument(
      title: title.isEmpty ? '未命名文件' : title,
      content: content,
      source: _safe(_sanitizeText(map['source'] as String?, maxLength: 120)),
    );
  }
}

class RawEmail {
  const RawEmail({
    required this.from,
    required this.subject,
    required this.body,
    this.date,
  });

  final String from;
  final String subject;
  final String body;
  final String? date;

  Map<String, Object?> toMap() => {
    'from': from,
    'subject': subject,
    'body': body,
    'date': date,
  };

  factory RawEmail.fromMap(Map<String, dynamic> map) {
    final body = _sanitizeText(map['body'] as String?, maxLength: 8000);
    if (body.isEmpty) {
      throw const FormatException('materials.emails[].body 不可為空。');
    }
    final from = _sanitizeText(map['from'] as String?, maxLength: 120);
    final subject = _sanitizeText(map['subject'] as String?, maxLength: 200);
    return RawEmail(
      from: from.isEmpty ? 'unknown' : from,
      subject: subject.isEmpty ? '(無主旨)' : subject,
      body: body,
      date: _safe(_sanitizeText(map['date'] as String?, maxLength: 64)),
    );
  }
}

class CyberSkillInputV1 {
  const CyberSkillInputV1({
    required this.profile,
    this.messages = const <RawMessage>[],
    this.documents = const <RawDocument>[],
    this.emails = const <RawEmail>[],
  });

  final CyberSkillProfile profile;
  final List<RawMessage> messages;
  final List<RawDocument> documents;
  final List<RawEmail> emails;

  bool get hasMaterials =>
      messages.isNotEmpty || documents.isNotEmpty || emails.isNotEmpty;

  List<String> get allTexts => [
    ...messages.map((e) => e.content),
    ...documents.map((e) => e.content),
    ...emails.map((e) => '${e.subject}\n${e.body}'),
  ];

  Map<String, Object?> toMap() => {
    'profile': profile.toMap(),
    'materials': {
      'messages': messages.map((m) => m.toMap()).toList(),
      'documents': documents.map((d) => d.toMap()).toList(),
      'emails': emails.map((e) => e.toMap()).toList(),
    },
  };

  static CyberSkillInputV1 fromJsonString(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      throw const FormatException('請先貼上標準化 JSON。');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 根節點必須是 Object。');
    }
    return fromMap(decoded);
  }

  static CyberSkillInputV1 fromMap(Map<String, dynamic> map) {
    final profileRaw = map['profile'];
    if (profileRaw is! Map) {
      throw const FormatException('缺少 profile 物件。');
    }
    final profile = CyberSkillProfile.fromMap(
      profileRaw.cast<String, dynamic>(),
    );

    final materialsRaw = map['materials'];
    if (materialsRaw is! Map) {
      throw const FormatException('缺少 materials 物件。');
    }
    final materials = materialsRaw.cast<String, dynamic>();

    final messages = _mapList(
      materials['messages'],
      (item) => RawMessage.fromMap(item),
    );
    final documents = _mapList(
      materials['documents'],
      (item) => RawDocument.fromMap(item),
    );
    final emails = _mapList(
      materials['emails'],
      (item) => RawEmail.fromMap(item),
    );

    final input = CyberSkillInputV1(
      profile: profile,
      messages: messages,
      documents: documents,
      emails: emails,
    );
    if (!input.hasMaterials) {
      throw const FormatException(
        'materials.messages / materials.documents / materials.emails 至少需要一項有資料。',
      );
    }
    return input;
  }
}

class CyberSkillAnalysis {
  const CyberSkillAnalysis({
    required this.catchPhrases,
    required this.frequentWords,
    required this.toneTraits,
    required this.decisionPriorities,
    required this.interpersonalPatterns,
    required this.workMethods,
    required this.boundaries,
    required this.sentenceStyle,
    required this.sourceStats,
  });

  final List<String> catchPhrases;
  final List<String> frequentWords;
  final List<String> toneTraits;
  final List<String> decisionPriorities;
  final List<String> interpersonalPatterns;
  final List<String> workMethods;
  final List<String> boundaries;
  final String sentenceStyle;
  final Map<String, int> sourceStats;

  Map<String, Object?> toMap() => {
    'catchPhrases': catchPhrases,
    'frequentWords': frequentWords,
    'toneTraits': toneTraits,
    'decisionPriorities': decisionPriorities,
    'interpersonalPatterns': interpersonalPatterns,
    'workMethods': workMethods,
    'boundaries': boundaries,
    'sentenceStyle': sentenceStyle,
    'sourceStats': sourceStats,
  };

  factory CyberSkillAnalysis.fromMap(Map<String, dynamic> map) {
    final sourceRaw = map['sourceStats'];
    final sourceStats = <String, int>{};
    if (sourceRaw is Map) {
      for (final entry in sourceRaw.entries) {
        final value = entry.value;
        if (entry.key is String && value is num) {
          sourceStats[entry.key as String] = value.toInt();
        }
      }
    }
    return CyberSkillAnalysis(
      catchPhrases: _stringList(map['catchPhrases']),
      frequentWords: _stringList(map['frequentWords']),
      toneTraits: _stringList(map['toneTraits']),
      decisionPriorities: _stringList(map['decisionPriorities']),
      interpersonalPatterns: _stringList(map['interpersonalPatterns']),
      workMethods: _stringList(map['workMethods']),
      boundaries: _stringList(map['boundaries']),
      sentenceStyle: (map['sentenceStyle'] as String? ?? '').trim(),
      sourceStats: sourceStats,
    );
  }
}

class SavedCyberSkill {
  const SavedCyberSkill({
    required this.id,
    required this.templateType,
    required this.profileName,
    required this.profileIdentity,
    required this.analysisSummary,
    required this.markdown,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TemplateType templateType;
  final String profileName;
  final String profileIdentity;
  final Map<String, dynamic> analysisSummary;
  final String markdown;
  final String version;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'templateType': templateType.wireValue,
    'profileName': profileName,
    'profileIdentity': profileIdentity,
    'analysisSummary': analysisSummary,
    'markdown': markdown,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedCyberSkill.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final summaryRaw = map['analysisSummary'];
    return SavedCyberSkill(
      id: id,
      templateType: TemplateType.fromWire(map['templateType'] as String?),
      profileName: (map['profileName'] as String? ?? '').trim(),
      profileIdentity: (map['profileIdentity'] as String? ?? '').trim(),
      analysisSummary: summaryRaw is Map<String, dynamic>
          ? summaryRaw
          : <String, dynamic>{},
      markdown: (map['markdown'] as String? ?? '').trim(),
      version: (map['version'] as String? ?? 'v1').trim(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }
}

List<T> _mapList<T>(
  Object? raw,
  T Function(Map<String, dynamic> item) converter,
) {
  if (raw == null) return <T>[];
  if (raw is! List) {
    throw const FormatException('materials 內的欄位需為陣列。');
  }
  final items = <T>[];
  for (final item in raw) {
    if (item is! Map) {
      throw const FormatException('materials 陣列元素需為 object。');
    }
    items.add(converter(item.cast<String, dynamic>()));
  }
  return items;
}

List<String> _stringList(Object? raw) {
  if (raw == null) return const <String>[];
  if (raw is! List) return const <String>[];
  return raw
      .whereType<String>()
      .map((e) => _sanitizeText(e, maxLength: 80))
      .where((e) => e.isNotEmpty)
      .take(20)
      .toList(growable: false);
}

String? _safe(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed;
}

DateTime _parseDate(Object? raw) {
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

String _sanitizeText(String? raw, {required int maxLength}) {
  if (raw == null) return '';
  var value = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  value = value.replaceAll('```', "'''");
  value = value.replaceAll(
    RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'),
    '',
  );
  value = value.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  if (value.length > maxLength) {
    value = value.substring(0, maxLength);
  }
  return value;
}
