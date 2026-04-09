import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/cyber_skill.dart';
import 'package:warmmemo/data/services/cyber_skill_generator_service.dart';
import 'package:warmmemo/data/services/cyber_skill_storage_service.dart';

void main() {
  group('CyberSkillGeneratorService', () {
    const service = CyberSkillGeneratorService();

    test('parseInput validates required profile/materials fields', () {
      expect(() => service.parseInput(''), throwsA(isA<FormatException>()));
      expect(
        () => service.parseInput('{"profile":{"name":"A"}}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.parseInput(
          '{"profile":{"name":"A"},"materials":{"messages":[],"documents":[],"emails":[]}}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('generate supports warmmemoDaily and colleagueWork templates', () {
      final input = service.parseInput(_sampleJson);
      final warmmemo = service.generate(
        input: input,
        templateType: TemplateType.warmmemoDaily,
      );
      final colleague = service.generate(
        input: input,
        templateType: TemplateType.colleagueWork,
      );

      expect(warmmemo.markdown.contains('## 互動邊界（禁區 / 敏感處理）'), isTrue);
      expect(colleague.markdown.contains('## PART A：工作能力'), isTrue);
      expect(colleague.markdown.contains('## PART B：人物性格'), isTrue);
      expect(warmmemo.analysis.sourceStats['messages'], 2);
    });

    test('renderFromAnalysis switches template without re-parse', () {
      final input = service.parseInput(_sampleJson);
      final analysis = service.analyze(input);

      final warmmemo = service.renderFromAnalysis(
        profile: input.profile,
        analysis: analysis,
        templateType: TemplateType.warmmemoDaily,
      );
      final colleague = service.renderFromAnalysis(
        profile: input.profile,
        analysis: analysis,
        templateType: TemplateType.colleagueWork,
      );

      expect(warmmemo, isNotEmpty);
      expect(colleague, isNotEmpty);
      expect(warmmemo.contains('WarmMemo'), isTrue);
      expect(colleague.contains('colleague_'), isTrue);
    });
  });

  group('CyberSkillStorageService', () {
    test('save and watch skills grouped by template type metadata', () async {
      final db = FakeFirebaseFirestore();
      final storage = CyberSkillStorageService(firestore: db);
      final profile = CyberSkillProfile(
        name: '小安',
        company: 'WarmMemo',
        level: 'P6',
        role: '產品經理',
      );
      const analysis = CyberSkillAnalysis(
        catchPhrases: <String>['先說結論'],
        frequentWords: <String>['風險', '對齊'],
        toneTraits: <String>['溫和'],
        decisionPriorities: <String>['先看影響'],
        interpersonalPatterns: <String>['先同步'],
        workMethods: <String>['先拆解任務'],
        boundaries: <String>['不做無法驗證承諾'],
        sentenceStyle: '短句偏多、回覆直接',
        sourceStats: <String, int>{'messages': 2, 'documents': 1, 'emails': 1},
      );

      await storage.saveSkill(
        uid: 'u1',
        templateType: TemplateType.warmmemoDaily,
        profile: profile,
        analysis: analysis,
        markdown: '# warmmemo',
      );
      await storage.saveSkill(
        uid: 'u1',
        templateType: TemplateType.colleagueWork,
        profile: profile,
        analysis: analysis,
        markdown: '# colleague',
      );

      final saved = await storage.watchSkills('u1').first;
      expect(saved.length, 2);
      expect(
        saved.map((e) => e.templateType).toSet(),
        containsAll(<TemplateType>[
          TemplateType.warmmemoDaily,
          TemplateType.colleagueWork,
        ]),
      );

      final rawDocs = await db
          .collection('users')
          .doc('u1')
          .collection('cyberSkills')
          .get();
      final firstData = rawDocs.docs.first.data();
      expect(firstData.containsKey('analysisSummary'), isTrue);
      expect(firstData.containsKey('materials'), isFalse);
      expect(firstData.containsKey('rawMessages'), isFalse);
    });
  });
}

const String _sampleJson = '''
{
  "profile": {
    "name": "小安",
    "company": "WarmMemo",
    "level": "P6",
    "role": "產品經理",
    "personaTags": ["溫和", "重視同理"],
    "cultureTags": ["用戶導向"],
    "impression": "說話溫柔但推進務實"
  },
  "materials": {
    "messages": [
      {"sender": "小安", "content": "先說結論：本週先處理通知流程。", "timestamp": "2026-04-01T10:00:00Z"},
      {"sender": "小安", "content": "我想先對齊背景再決策。", "timestamp": "2026-04-01T12:00:00Z"}
    ],
    "documents": [
      {"title": "客服 SOP", "content": "先共情，再確認需求，最後給可執行選項。", "source": "doc://sop"}
    ],
    "emails": [
      {"from": "xiaoan@warmmemo.io", "subject": "排程確認", "body": "先檢查風險與回滾方案。", "date": "2026-04-02"}
    ]
  }
}
''';
