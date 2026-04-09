import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/cyber_skill.dart';
import 'package:warmmemo/data/services/cyber_skill_generator_service.dart';
import 'package:warmmemo/features/skills/skill_generator_tab.dart';

void main() {
  testWidgets('template switch re-renders without re-parse', (tester) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final generator = _CountingGenerator();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkillGeneratorTab(
            generator: generator,
            currentUidProvider: () => null,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, _sampleJson);
    final generateBtn = find.widgetWithText(FilledButton, '驗證並生成');
    await tester.ensureVisible(generateBtn);
    await tester.tap(generateBtn);
    await tester.pumpAndSettle();

    expect(generator.parseCount, 1);
    expect(find.textContaining('template:warmmemoDaily'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '工作模式 Colleague'));
    await tester.pumpAndSettle();
    expect(generator.parseCount, 1);
    expect(find.textContaining('template:colleagueWork'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '日常模式 WarmMemo'));
    await tester.pumpAndSettle();
    expect(generator.parseCount, 1);
    expect(find.textContaining('template:warmmemoDaily'), findsOneWidget);
  });
}

class _CountingGenerator extends CyberSkillGeneratorService {
  int parseCount = 0;

  @override
  CyberSkillInputV1 parseInput(String rawJson) {
    parseCount += 1;
    return super.parseInput(rawJson);
  }

  @override
  CyberSkillAnalysis analyze(CyberSkillInputV1 input) {
    return const CyberSkillAnalysis(
      catchPhrases: <String>['先說結論'],
      frequentWords: <String>['風險'],
      toneTraits: <String>['溫和'],
      decisionPriorities: <String>['先看影響'],
      interpersonalPatterns: <String>['先同步'],
      workMethods: <String>['先拆解'],
      boundaries: <String>['不做過度承諾'],
      sentenceStyle: '短句偏多',
      sourceStats: <String, int>{'messages': 1, 'documents': 0, 'emails': 0},
    );
  }

  @override
  String renderFromAnalysis({
    required CyberSkillProfile profile,
    required CyberSkillAnalysis analysis,
    required TemplateType templateType,
  }) {
    return 'template:${templateType.wireValue}\nname:${profile.name}';
  }
}

const String _sampleJson = '''
{
  "profile": { "name": "小安" },
  "materials": {
    "messages": [
      { "sender": "小安", "content": "先說結論：先處理通知流程。" }
    ],
    "documents": [],
    "emails": []
  }
}
''';
