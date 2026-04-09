import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/cyber_skill.dart';

void main() {
  group('TemplateType', () {
    test('wire value and fallback mapping', () {
      expect(TemplateType.warmmemoDaily.wireValue, 'warmmemoDaily');
      expect(TemplateType.colleagueWork.wireValue, 'colleagueWork');
      expect(
        TemplateType.fromWire('colleagueWork'),
        TemplateType.colleagueWork,
      );
      expect(TemplateType.fromWire('unknown'), TemplateType.warmmemoDaily);
      expect(TemplateType.fromWire(null), TemplateType.warmmemoDaily);
    });
  });

  group('CyberSkillInputV1 parsing', () {
    test('fromJsonString validates root object and required objects', () {
      expect(
        () => CyberSkillInputV1.fromJsonString(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => CyberSkillInputV1.fromJsonString('[]'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => CyberSkillInputV1.fromJsonString('{"profile":{"name":"A"}}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => CyberSkillInputV1.fromJsonString(
          '{"profile":{"name":"A"},"materials":{"messages":[],"documents":[],"emails":[]}}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap validates materials list shape and item object type', () {
      expect(
        () => CyberSkillInputV1.fromMap(<String, dynamic>{
          'profile': <String, dynamic>{'name': 'A'},
          'materials': <String, dynamic>{'messages': 'bad'},
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => CyberSkillInputV1.fromMap(<String, dynamic>{
          'profile': <String, dynamic>{'name': 'A'},
          'materials': <String, dynamic>{
            'messages': <Object>['bad'],
            'documents': <Object>[],
            'emails': <Object>[],
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'sanitizes content strips control chars fences truncates and limits lists',
      () {
        final long = List<String>.filled(5000, 'x').join();
        final input = CyberSkillInputV1.fromMap(<String, dynamic>{
          'profile': <String, dynamic>{
            'name': '  A\u0007```name  ',
            'company': 'C',
            'level': 'L',
            'role': 'R',
            'impression':
                'test\u0000```${List<String>.filled(500, 'y').join()}',
            'personaTags': List<String>.generate(30, (i) => ' t$i '),
          },
          'materials': <String, dynamic>{
            'messages': <Map<String, dynamic>>[
              <String, dynamic>{
                'sender': '  s ',
                'content': 'abc\u0001```def\n\n\nline2$long',
                'timestamp': ' 2026-01-01 ',
              },
            ],
            'documents': <Map<String, dynamic>>[
              <String, dynamic>{'title': '', 'content': 'doc'},
            ],
            'emails': <Map<String, dynamic>>[
              <String, dynamic>{'from': '', 'subject': '', 'body': 'mail'},
            ],
          },
        });

        expect(input.profile.name.contains('```'), isFalse);
        expect(input.profile.name.contains("'''"), isTrue);
        expect(input.profile.personaTags.length, 20);
        expect(input.messages.single.content.length <= 4000, isTrue);
        expect(input.messages.single.content.contains('\u0001'), isFalse);
        expect(input.messages.single.content.contains("'''"), isTrue);
        expect(input.documents.single.title, '未命名文件');
        expect(input.emails.single.from, 'unknown');
        expect(input.emails.single.subject, '(無主旨)');
      },
    );

    test('throws for empty mandatory content fields', () {
      expect(
        () => RawMessage.fromMap(<String, dynamic>{'content': '   '}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RawDocument.fromMap(<String, dynamic>{'content': '   '}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RawEmail.fromMap(<String, dynamic>{'body': '   '}),
        throwsA(isA<FormatException>()),
      );
    });

    test('supports missing materials lists and exposes allTexts/toMap', () {
      final input = CyberSkillInputV1.fromMap(<String, dynamic>{
        'profile': <String, dynamic>{
          'name': '小安',
          'relationshipToUser': '我的媽媽',
          'familyRole': '家庭核心照顧者',
          'lifeStage': '退休後',
          'residenceCity': '台北',
          'occupation': '國小老師',
          'company': 'WarmMemo',
          'level': 'P6',
          'role': 'PM',
          'gender': '女',
          'mbti': 'INFJ',
          'personaTags': <String>['溫和'],
          'cultureTags': <String>['務實'],
          'personalValues': <String>['重視承諾'],
          'hobbies': <String>['散步'],
          'signatureMemory': '週末一起去市場買菜',
          'impression': '清楚溝通',
        },
        'materials': <String, dynamic>{
          'messages': <Map<String, dynamic>>[
            <String, dynamic>{
              'sender': '小安',
              'content': '先說結論',
              'timestamp': '2026-01-01',
            },
          ],
        },
      });

      expect(input.documents, isEmpty);
      expect(input.emails, isEmpty);
      expect(input.allTexts, hasLength(1));
      expect(input.profile.warmIdentityLine, contains('我的媽媽'));
      expect(input.profile.personalContextLines, isNotEmpty);

      final map = input.toMap();
      expect(map['profile'], isA<Map<String, Object?>>());
      final materials = map['materials'] as Map<String, Object?>;
      expect(materials['messages'], isA<List<Object?>>());
      expect(materials['documents'], isA<List<Object?>>());
      expect(materials['emails'], isA<List<Object?>>());
    });

    test('model toMap methods include expected keys', () {
      const profile = CyberSkillProfile(
        name: 'A',
        relationshipToUser: '姊姊',
        familyRole: '家中長女',
        lifeStage: '育兒中',
        residenceCity: '桃園',
        occupation: '護理師',
        company: 'C',
        level: 'L',
        role: 'R',
        gender: 'F',
        mbti: 'INFJ',
        personaTags: <String>['p1'],
        cultureTags: <String>['c1'],
        personalValues: <String>['同理'],
        hobbies: <String>['園藝'],
        signatureMemory: '一起過年的餐桌',
        impression: 'i',
      );
      expect(profile.toMap()['company'], 'C');
      expect(profile.identityLine, 'C L R');
      expect(profile.warmIdentityLine, contains('姊姊'));
      expect(profile.personalContextLines.join('\n'), contains('桃園'));

      const message = RawMessage(sender: 's', content: 'm', timestamp: 't');
      expect(message.toMap()['timestamp'], 't');

      const doc = RawDocument(title: 'd', content: 'c', source: 'src');
      expect(doc.toMap()['source'], 'src');

      const email = RawEmail(
        from: 'f',
        subject: 's',
        body: 'b',
        date: '2026-01-01',
      );
      expect(email.toMap()['date'], '2026-01-01');
    });
  });

  group('SavedCyberSkill map and parsing fallback', () {
    test('fromMap parses defaults and invalid dates fallback', () {
      final parsed = SavedCyberSkill.fromMap(<String, dynamic>{
        'templateType': 'colleagueWork',
        'profileName': 'A',
        'profileIdentity': 'I',
        'analysisSummary': <String, dynamic>{'a': 1},
        'markdown': '# md',
        'version': 'v000009',
        'createdAt': 'invalid',
        'updatedAt': 'invalid',
      }, id: 'id1');

      expect(parsed.id, 'id1');
      expect(parsed.templateType, TemplateType.colleagueWork);
      expect(parsed.markdown, '# md');
      expect(parsed.analysisSummary['a'], 1);
    });

    test('fromMap falls back when analysisSummary is not a map', () {
      final parsed = SavedCyberSkill.fromMap(<String, dynamic>{
        'analysisSummary': 'not-map',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, id: 'id2');

      expect(parsed.analysisSummary, isEmpty);
      expect(parsed.version, 'v1');
    });

    test('toMap and analysis fromMap roundtrip', () {
      final analysis = CyberSkillAnalysis(
        catchPhrases: const <String>['a'],
        frequentWords: const <String>['b'],
        toneTraits: const <String>['c'],
        decisionPriorities: const <String>['d'],
        interpersonalPatterns: const <String>['e'],
        workMethods: const <String>['f'],
        boundaries: const <String>['g'],
        sentenceStyle: 'style',
        sourceStats: const <String, int>{'messages': 1, 'documents': 2},
      );
      final map = analysis.toMap();
      final rebuilt = CyberSkillAnalysis.fromMap(map);
      expect(rebuilt.sourceStats['messages'], 1);
      expect(rebuilt.sentenceStyle, 'style');
    });
  });
}
