import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/data/models/cyber_skill.dart';
import 'package:warmmemo/data/services/cyber_skill_generator_service.dart';
import 'package:warmmemo/data/services/cyber_skill_storage_service.dart';
import 'package:warmmemo/features/skills/skill_generator_tab.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> pumpSkillTab(
    WidgetTester tester, {
    required _FakeGenerator generator,
    required _FakeStorage storage,
    String? uid = 'u1',
    Future<String?> Function()? importJsonText,
    List<String>? feedbackLog,
    List<String>? copiedLog,
    List<String>? downloadedLog,
  }) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkillGeneratorTab(
            key: UniqueKey(),
            generator: generator,
            storage: storage,
            currentUidProvider: () => uid,
            copyText: (text) async => copiedLog?.add(text),
            downloadText: (content, filename) async =>
                downloadedLog?.add('$filename::$content'),
            importJsonText: importJsonText,
            feedback: (_, message, tone) =>
                feedbackLog?.add('${tone.name}:$message'),
          ),
        ),
      ),
    );
    await pumpUi(tester);
  }

  testWidgets('template switch re-renders without re-parse', (tester) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();
    final feedback = <String>[];

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      feedbackLog: feedback,
    );

    await tester.enterText(find.byType(TextField).first, _sampleJson);
    await tester.tap(find.widgetWithText(FilledButton, '驗證並生成'));
    await pumpUi(tester);

    expect(generator.parseCount, 1);
    expect(find.textContaining('template:warmmemoDaily'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '工作模式 Colleague').first);
    await pumpUi(tester);
    expect(generator.parseCount, 1);
    expect(find.textContaining('template:colleagueWork'), findsOneWidget);

    expect(feedback.any((m) => m.contains('已生成')), isTrue);
  });

  testWidgets('apply sample json fills text area', (tester) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();

    await pumpSkillTab(tester, generator: generator, storage: storage);

    await tester.tap(find.widgetWithText(OutlinedButton, '套用範例 JSON'));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller!.text.contains('"profile"'), isTrue);
    expect(textField.controller!.text.contains('"materials"'), isTrue);
  });

  testWidgets('import json file validates and fills text area', (tester) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();
    final feedback = <String>[];

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      importJsonText: () async => _sampleJson,
      feedbackLog: feedback,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '匯入 JSON 檔'));
    await pumpUi(tester);

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller!.text, contains('"profile"'));
    expect(feedback.last, contains('JSON 已匯入並通過格式驗證'));
  });

  testWidgets('import json file shows format error for invalid json', (
    tester,
  ) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();
    final feedback = <String>[];

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      importJsonText: () async => '{"profile":{}}',
      feedbackLog: feedback,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '匯入 JSON 檔'));
    await pumpUi(tester);

    expect(find.textContaining('profile.name 是必填欄位'), findsWidgets);
    expect(feedback.last, contains('profile.name 是必填欄位'));
  });

  testWidgets('format/firebase/unknown errors map to safe messages', (
    tester,
  ) async {
    final storage = _FakeStorage();

    final formatGenerator = _FakeGenerator()
      ..parseError = const FormatException('格式錯誤');
    final firebaseGenerator = _FakeGenerator()
      ..parseError = FirebaseException(
        plugin: 'firebase_core',
        code: 'permission-denied',
      );
    final unknownGenerator = _FakeGenerator()..parseError = Exception('boom');

    final feedback = <String>[];
    await pumpSkillTab(
      tester,
      generator: formatGenerator,
      storage: storage,
      feedbackLog: feedback,
    );
    await tester.enterText(find.byType(TextField).first, _sampleJson);
    await tester.tap(find.widgetWithText(FilledButton, '驗證並生成'));
    await pumpUi(tester);
    expect(find.textContaining('格式錯誤'), findsWidgets);

    await pumpSkillTab(
      tester,
      generator: firebaseGenerator,
      storage: storage,
      feedbackLog: feedback,
    );
    await tester.enterText(find.byType(TextField).first, _sampleJson);
    await tester.tap(find.widgetWithText(FilledButton, '驗證並生成'));
    await pumpUi(tester);
    expect(find.textContaining('權限不足'), findsWidgets);

    await pumpSkillTab(
      tester,
      generator: unknownGenerator,
      storage: storage,
      feedbackLog: feedback,
    );
    await tester.enterText(find.byType(TextField).first, _sampleJson);
    await tester.tap(find.widgetWithText(FilledButton, '驗證並生成'));
    await pumpUi(tester);
    expect(find.textContaining('發生未知錯誤'), findsWidgets);
  });

  testWidgets('copy and download actions are callable', (tester) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();
    final copied = <String>[];
    final downloaded = <String>[];

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      copiedLog: copied,
      downloadedLog: downloaded,
    );

    await tester.enterText(find.byType(TextField).first, _sampleJson);
    await tester.tap(find.widgetWithText(FilledButton, '驗證並生成'));
    await pumpUi(tester);

    await tester.tap(find.widgetWithText(FilledButton, '一鍵複製'));
    await pumpUi(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, '下載 .md'));
    await pumpUi(tester);

    expect(copied.single.contains('template:warmmemoDaily'), isTrue);
    expect(
      downloaded.single.contains('_warmmemo.md::template:warmmemoDaily'),
      isTrue,
    );
  });

  testWidgets('save flow handles missing state success and firebase failure', (
    tester,
  ) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();
    final feedback = <String>[];

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      feedbackLog: feedback,
    );

    await tester.enterText(find.byType(TextField).first, _sampleJson);
    await tester.tap(find.widgetWithText(FilledButton, '驗證並生成'));
    await pumpUi(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, '儲存到雲端'));
    await pumpUi(tester);
    expect(storage.saveCalls, 1);
    expect(feedback.last, contains('已儲存到雲端版本列表'));

    storage.saveError = FirebaseException(
      plugin: 'firebase_core',
      code: 'failed-precondition',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, '儲存到雲端'));
    await pumpUi(tester);
    expect(feedback.last, contains('資料庫前置設定尚未完成'));
  });

  testWidgets('saved list supports filter use copy and delete paths', (
    tester,
  ) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();
    final copied = <String>[];
    final feedback = <String>[];

    storage.emitSkills(<SavedCyberSkill>[
      _savedSkill('s1', TemplateType.warmmemoDaily, '# warmmemo v1'),
      _savedSkill('s2', TemplateType.colleagueWork, '# colleague v1'),
    ]);

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      copiedLog: copied,
      feedbackLog: feedback,
    );
    await pumpUi(tester);

    expect(find.textContaining('日常模式 WarmMemo'), findsWidgets);
    expect(find.textContaining('工作模式 Colleague'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, '工作模式 Colleague').last);
    await pumpUi(tester);
    expect(find.textContaining('template:colleagueWork'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '查看').first);
    await pumpUi(tester);
    expect(find.textContaining('# colleague v1'), findsWidgets);

    await tester.tap(find.widgetWithText(OutlinedButton, '複製').first);
    await pumpUi(tester);
    expect(copied.last, contains('# colleague v1'));

    await tester.tap(find.widgetWithText(OutlinedButton, '刪除').first);
    await pumpUi(tester);
    expect(storage.deletedIds, contains('s2'));

    storage.deleteError = FirebaseException(
      plugin: 'firebase_core',
      code: 'unavailable',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, '刪除').first);
    await pumpUi(tester);
    expect(feedback.last, contains('服務暫時不可用'));
  });

  testWidgets('unauthenticated state hides cloud list actions', (tester) async {
    final generator = _FakeGenerator();
    final storage = _FakeStorage();

    await pumpSkillTab(
      tester,
      generator: generator,
      storage: storage,
      uid: null,
    );

    expect(find.text('尚未登入'), findsOneWidget);
  });
}

class _FakeGenerator extends CyberSkillGeneratorService {
  int parseCount = 0;
  Object? parseError;

  @override
  CyberSkillInputV1 parseInput(String rawJson) {
    parseCount += 1;
    final error = parseError;
    if (error != null) {
      if (error is Exception) throw error;
      throw Exception(error.toString());
    }
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

class _FakeStorage extends CyberSkillStorageService {
  _FakeStorage() : super(firestore: FakeFirebaseFirestore());

  final StreamController<List<SavedCyberSkill>> _controller =
      StreamController<List<SavedCyberSkill>>.broadcast();
  List<SavedCyberSkill> _currentSkills = const <SavedCyberSkill>[];
  int saveCalls = 0;
  final List<String> deletedIds = <String>[];
  Object? saveError;
  Object? deleteError;

  @override
  Stream<List<SavedCyberSkill>> watchSkills(String uid) async* {
    yield _currentSkills;
    yield* _controller.stream;
  }

  void emitSkills(List<SavedCyberSkill> skills) {
    _currentSkills = skills;
    _controller.add(skills);
  }

  @override
  Future<SavedCyberSkill> saveSkill({
    required String uid,
    required TemplateType templateType,
    required CyberSkillProfile profile,
    required CyberSkillAnalysis analysis,
    required String markdown,
    String? existingId,
  }) async {
    saveCalls += 1;
    final error = saveError;
    if (error != null) {
      if (error is Exception) throw error;
      throw Exception(error.toString());
    }
    final saved = _savedSkill(
      existingId ?? 'saved-$saveCalls',
      templateType,
      markdown,
    );
    emitSkills(<SavedCyberSkill>[saved]);
    return saved;
  }

  @override
  Future<void> deleteSkill({
    required String uid,
    required String skillId,
  }) async {
    final error = deleteError;
    if (error != null) {
      if (error is Exception) throw error;
      throw Exception(error.toString());
    }
    deletedIds.add(skillId);
  }
}

SavedCyberSkill _savedSkill(String id, TemplateType type, String markdown) {
  final now = DateTime.utc(2026, 4, 9, 10, 0, 0);
  return SavedCyberSkill(
    id: id,
    templateType: type,
    profileName: '小安',
    profileIdentity: 'WarmMemo P6 PM',
    analysisSummary: const <String, dynamic>{},
    markdown: markdown,
    version: 'v000001',
    createdAt: now,
    updatedAt: now,
  );
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
