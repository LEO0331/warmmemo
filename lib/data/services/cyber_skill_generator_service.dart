import '../models/cyber_skill.dart';

class GeneratedSkillOutput {
  const GeneratedSkillOutput({
    required this.templateType,
    required this.markdown,
    required this.analysis,
  });

  final TemplateType templateType;
  final String markdown;
  final CyberSkillAnalysis analysis;
}

class CyberSkillGeneratorService {
  const CyberSkillGeneratorService();

  CyberSkillInputV1 parseInput(String rawJson) {
    return CyberSkillInputV1.fromJsonString(rawJson);
  }

  CyberSkillAnalysis analyze(CyberSkillInputV1 input) {
    final allTexts = input.allTexts;
    final sourceStats = <String, int>{
      'messages': input.messages.length,
      'documents': input.documents.length,
      'emails': input.emails.length,
    };
    final tokenFreq = _tokenFrequency(allTexts);
    final phraseFreq = _phraseFrequency(allTexts);
    final sentenceStyle = _sentenceStyle(allTexts);

    final catchPhrases = phraseFreq.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frequentWords = tokenFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CyberSkillAnalysis(
      catchPhrases: catchPhrases.take(8).map((e) => e.key).toList(),
      frequentWords: frequentWords.take(12).map((e) => e.key).toList(),
      toneTraits: _extractToneTraits(allTexts),
      decisionPriorities: _extractDecisionPriorities(allTexts),
      interpersonalPatterns: _extractInterpersonalPatterns(allTexts),
      workMethods: _extractWorkMethods(allTexts),
      boundaries: _extractBoundaries(allTexts),
      sentenceStyle: sentenceStyle,
      sourceStats: sourceStats,
    );
  }

  GeneratedSkillOutput generate({
    required CyberSkillInputV1 input,
    required TemplateType templateType,
  }) {
    final analysis = analyze(input);
    final markdown = renderFromAnalysis(
      profile: input.profile,
      analysis: analysis,
      templateType: templateType,
    );
    return GeneratedSkillOutput(
      templateType: templateType,
      markdown: markdown,
      analysis: analysis,
    );
  }

  String renderFromAnalysis({
    required CyberSkillProfile profile,
    required CyberSkillAnalysis analysis,
    required TemplateType templateType,
  }) {
    return switch (templateType) {
      TemplateType.warmmemoDaily => renderWarmmemoDailySkill(
        profile: profile,
        analysis: analysis,
      ),
      TemplateType.colleagueWork => renderColleagueWorkSkill(
        profile: profile,
        analysis: analysis,
      ),
    };
  }

  String renderWarmmemoDailySkill({
    required CyberSkillProfile profile,
    required CyberSkillAnalysis analysis,
  }) {
    final safeName = _sanitizeForRender(profile.name, maxLength: 80);
    final safeIdentity = _sanitizeForRender(
      profile.warmIdentityLine,
      maxLength: 120,
    );
    final safeImpression = _sanitizeForRender(
      profile.impression ?? '',
      maxLength: 280,
    );
    final personalContextLines = profile.personalContextLines
        .map((line) => _sanitizeForRender(line, maxLength: 140))
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final title = '$safeName 的日常對話分身';
    final tags = [
      'warmmemo',
      'daily-life',
      if (profile.personaTags.isNotEmpty)
        ...profile.personaTags
            .take(3)
            .map((e) => _sanitizeForRender(e, maxLength: 24)),
    ];
    final warmPhrases = _quoteList(analysis.catchPhrases, maxItemLength: 60);
    final frequentWords = _quoteList(
      analysis.frequentWords.take(8).toList(),
      maxItemLength: 40,
    );
    final safeToneTraits = _boundedList(
      analysis.toneTraits,
      maxItems: 10,
      maxItemLength: 80,
    );
    final safeDecision = _boundedList(
      analysis.decisionPriorities,
      maxItems: 10,
      maxItemLength: 90,
    );
    final safeBoundaries = _boundedList(
      analysis.boundaries,
      maxItems: 10,
      maxItemLength: 100,
    );

    return '''
---
name: ${_yamlScalar('warmmemo_${_slugify(safeName)}_daily')}
description: ${_yamlScalar('$safeName 的日常陪伴與回憶對話版型')}
tags:
${tags.map((e) => '  - ${_yamlScalar(e)}').join('\n')}
version: 1.0
---

# $title

## 人物定位

你是 $safeName，定位是「日常陪伴、回憶對話、情感支持」。
${safeIdentity == '家人般的陪伴者' ? '' : '身份背景：$safeIdentity。'}
${safeImpression.isEmpty ? '' : '主觀印象：$safeImpression。'}
${personalContextLines.isEmpty ? '' : '\n${personalContextLines.map((e) => '- $e').join('\n')}'}

## 語氣與表達規則

- 說話節奏：${analysis.sentenceStyle}
- 常見語氣特徵：${safeToneTraits.join('、')}
- 常見口頭禪：$warmPhrases
- 常用詞：$frequentWords
- 回答原則：先共情、再確認需求、最後給可執行建議。

## 決策與價值排序

${safeDecision.map((e) => '- $e').join('\n')}

## 互動邊界（禁區 / 敏感處理）

${safeBoundaries.map((e) => '- $e').join('\n')}
- 當對話涉及重大醫療、法律、金流決策時，先提醒「這需要真人專業協助」。

## 情境回覆示例

> 使用者說：「我今天真的很想他。」
> 你：先接住情緒，再用對方熟悉語氣陪伴，例如「我在，你可以慢慢說。」

> 使用者說：「我不知道該怎麼跟家人談。」
> 你：先整理問題，再提供 1-2 個可操作句型，避免一次丟太多步驟。

> 使用者說：「我現在很亂，幫我做決定。」
> 你：先釐清限制條件，提供分步選項，不直接替對方做不可逆決定。

## 來源摘要與可信度

- 材料筆數：messages=${analysis.sourceStats['messages'] ?? 0}、documents=${analysis.sourceStats['documents'] ?? 0}、emails=${analysis.sourceStats['emails'] ?? 0}
- 推斷方式：依文字頻率、決策語句與互動句式抽取（非完整人格複製）。
- 使用建議：適合日常對話與情緒支持，不可作為法律/醫療/財務專業替代。

## 使用說明（給 AI）

1. 保持角色一致，不切換成通用客服口吻。
2. 先遵循「共情 → 釐清 → 建議」流程。
3. 若超出邊界，明確說明限制並給下一步求助方向。
''';
  }

  String renderColleagueWorkSkill({
    required CyberSkillProfile profile,
    required CyberSkillAnalysis analysis,
  }) {
    final safeName = _sanitizeForRender(profile.name, maxLength: 80);
    final safeIdentity = _sanitizeForRender(
      profile.workIdentityLine,
      maxLength: 120,
    );
    final safeImpression = _sanitizeForRender(
      profile.impression ?? '',
      maxLength: 280,
    );
    final safeMbti = _sanitizeForRender(profile.mbti ?? '', maxLength: 16);
    final workFocus = analysis.workMethods.isEmpty
        ? const <String>['按優先級拆解問題並可追蹤交付']
        : _boundedList(analysis.workMethods, maxItems: 10, maxItemLength: 100);
    final toneTraits = analysis.toneTraits.isEmpty
        ? const <String>['務實直接']
        : _boundedList(analysis.toneTraits, maxItems: 10, maxItemLength: 80);
    final interpersonal = analysis.interpersonalPatterns.isEmpty
        ? const <String>['先對齊需求，再提出方案']
        : _boundedList(
            analysis.interpersonalPatterns,
            maxItems: 10,
            maxItemLength: 100,
          );
    final safeDecision = _boundedList(
      analysis.decisionPriorities,
      maxItems: 10,
      maxItemLength: 90,
    );
    final safeBoundaries = _boundedList(
      analysis.boundaries,
      maxItems: 10,
      maxItemLength: 100,
    );

    return '''
---
name: ${_yamlScalar('colleague_${_slugify(safeName)}')}
description: ${_yamlScalar('$safeName，$safeIdentity')}
user-invocable: true
---

# $safeName

$safeIdentity

---

## PART A：工作能力

### 職責範圍

- 典型工作方式：${workFocus.join('、')}
- 決策優先級：${safeDecision.join('、')}
- 常見輸出型態：結論先行、步驟化建議、可執行清單。

### 技術與協作規範

- 常見工作語句：${_quoteList(analysis.catchPhrases)}
- 溝通節奏：${analysis.sentenceStyle}
- 協作模式：${interpersonal.join('、')}
- 風險偏好：重大變更先驗證、再推進。

### Code Review / 任務推進重點

${workFocus.map((e) => '- $e').join('\n')}

---

## PART B：人物性格

### Layer 0：核心性格（最高優先級）

${toneTraits.map((e) => '- $e').join('\n')}
${safeBoundaries.map((e) => '- $e').join('\n')}

### Layer 1：身份

你是 $safeName。
${safeIdentity == '同事' ? '' : '在 $safeIdentity 的語境中思考與回覆。'}
${safeMbti.isEmpty ? '' : 'MBTI：$safeMbti。'}
${safeImpression.isEmpty ? '' : '補充印象：$safeImpression。'}

### Layer 2：表達風格

- 口頭禪：${_quoteList(analysis.catchPhrases)}
- 高頻詞：${_quoteList(analysis.frequentWords.take(8).toList())}
- 句式：${analysis.sentenceStyle}

### Layer 3：決策與判斷

${safeDecision.map((e) => '- $e').join('\n')}

### Layer 4：人際行為

${interpersonal.map((e) => '- $e').join('\n')}

### Layer 5：邊界與雷區

${safeBoundaries.map((e) => '- $e').join('\n')}

---

## 运行规则

接收到任何任务或问题时：

1. **先由 PART B 判断**：你会不会接这个任务？用什么态度接？
2. **再由 PART A 执行**：用你的工作方法完成任务
3. **输出时保持 PART B 的表达风格**：保留用词和句式习惯

**PART B 的 Layer 0 规则永远优先，任何情况下不得违背。**
''';
  }

  Map<String, int> _tokenFrequency(List<String> texts) {
    final freq = <String, int>{};
    final tokenRegex = RegExp(
      r'[\u4e00-\u9fff]{2,}|[A-Za-z][A-Za-z0-9_-]{1,}',
      unicode: true,
    );
    for (final text in texts) {
      for (final match in tokenRegex.allMatches(text)) {
        final token = match.group(0)!.toLowerCase().trim();
        if (token.length < 2) continue;
        if (_stopWords.contains(token)) continue;
        freq[token] = (freq[token] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<String, int> _phraseFrequency(List<String> texts) {
    final freq = <String, int>{};
    for (final text in texts) {
      final lines = text
          .split(RegExp(r'[\n。！？!?]'))
          .map((e) => e.trim())
          .where((e) => e.length >= 4 && e.length <= 20);
      for (final line in lines) {
        if (_stopPhrase(line)) continue;
        freq[line] = (freq[line] ?? 0) + 1;
      }
    }
    return freq;
  }

  String _sentenceStyle(List<String> texts) {
    var sentenceCount = 0;
    var totalLen = 0;
    var bulletLike = 0;
    for (final text in texts) {
      final lines = text.split('\n');
      for (final line in lines) {
        final t = line.trim();
        if (t.isEmpty) continue;
        if (RegExp(r'^[-*•\d]+[.)、\s]').hasMatch(t)) bulletLike++;
      }
      final sentences = text
          .split(RegExp(r'[。！？!?]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final s in sentences) {
        sentenceCount++;
        totalLen += s.length;
      }
    }
    if (sentenceCount == 0) return '句子偏短、直接回覆';
    final avg = totalLen / sentenceCount;
    final sentenceDesc = switch (avg) {
      < 16 => '短句偏多、回覆直接',
      < 34 => '句長中等、重點與背景並行',
      _ => '長句偏多、傾向先鋪陳再下結論',
    };
    if (bulletLike >= 3) {
      return '$sentenceDesc，且常用條列整理。';
    }
    return '$sentenceDesc。';
  }

  List<String> _extractToneTraits(List<String> texts) {
    final merged = texts.join('\n');
    final traits = <String>[];
    if (_containsAny(merged, const ['請', '麻煩', '辛苦', '謝謝'])) {
      traits.add('語氣偏禮貌、重視互相尊重');
    }
    if (_containsAny(merged, const ['先說結論', '結論是', '直接講'])) {
      traits.add('偏好結論先行');
    }
    if (_containsAny(merged, const ['先對齊', 'context', '背景'])) {
      traits.add('重視先對齊背景與脈絡');
    }
    if (_containsAny(merged, const ['風險', '驗證', '確認'])) {
      traits.add('行事謹慎，先評估風險再執行');
    }
    if (traits.isEmpty) traits.add('語氣平實，重視可執行性');
    return traits;
  }

  List<String> _extractDecisionPriorities(List<String> texts) {
    final merged = texts.join('\n');
    final priorities = <String>[];
    if (_containsAny(merged, const ['impact', '成效', '結果', '收益'])) {
      priorities.add('優先看結果與影響範圍');
    }
    if (_containsAny(merged, const ['風險', '穩定', '回滾', '備援'])) {
      priorities.add('優先控制風險與可回復性');
    }
    if (_containsAny(merged, const ['時間', 'deadline', '排程'])) {
      priorities.add('重視時程與交付節點');
    }
    if (_containsAny(merged, const ['資料', '數據', '指標'])) {
      priorities.add('偏好以數據或證據支撐判斷');
    }
    if (priorities.isEmpty) priorities.add('先釐清目標，再決定執行路徑');
    return priorities;
  }

  List<String> _extractInterpersonalPatterns(List<String> texts) {
    final merged = texts.join('\n');
    final patterns = <String>[];
    if (_containsAny(merged, const ['先對齊', '同步', '@'])) {
      patterns.add('會先同步關鍵關係人，避免資訊落差');
    }
    if (_containsAny(merged, const ['麻煩', '請協助', '幫忙'])) {
      patterns.add('分工時語氣偏禮貌，傾向請求式協作');
    }
    if (_containsAny(merged, const ['不建議', '先不要', '暫緩'])) {
      patterns.add('反對時多用風險與條件式表達，不直接衝突');
    }
    if (patterns.isEmpty) patterns.add('協作上重視明確責任與下一步');
    return patterns;
  }

  List<String> _extractWorkMethods(List<String> texts) {
    final merged = texts.join('\n');
    final methods = <String>[];
    if (_containsAny(merged, const ['拆解', '分步', '步驟'])) {
      methods.add('先拆解任務，再逐步推進');
    }
    if (_containsAny(merged, const ['驗證', '測試', '檢查'])) {
      methods.add('交付前會先做驗證與自我檢查');
    }
    if (_containsAny(merged, const ['文件', '紀錄', '說明'])) {
      methods.add('重視文件與可追溯紀錄');
    }
    if (_containsAny(merged, const ['review', 'CR', 'code review'])) {
      methods.add('習慣透過 review 保持品質一致性');
    }
    if (_containsAny(merged, const ['排程', '里程碑', '截止'])) {
      methods.add('會用里程碑追蹤進度與交付');
    }
    if (methods.isEmpty) {
      methods.add('面對需求會先確認目標、約束與交付形式');
    }
    return methods;
  }

  List<String> _extractBoundaries(List<String> texts) {
    final merged = texts.join('\n');
    final boundaries = <String>[];
    if (_containsAny(merged, const ['不負責', '不在範圍', '超出範圍'])) {
      boundaries.add('遇到超出範圍的事項，會先界定責任邊界');
    }
    if (_containsAny(merged, const ['先不要', '暫不', '不建議'])) {
      boundaries.add('在資訊不足時傾向暫緩，不做高風險承諾');
    }
    if (_containsAny(merged, const ['不能保證', '無法承諾'])) {
      boundaries.add('不提供無法驗證或無法保證的承諾');
    }
    if (boundaries.isEmpty) {
      boundaries.add('優先維持真實、可驗證、可落地的回覆邊界');
    }
    return boundaries;
  }

  bool _containsAny(String text, List<String> needles) {
    final lower = text.toLowerCase();
    return needles.any((needle) => lower.contains(needle.toLowerCase()));
  }

  String _quoteList(List<String> values, {int maxItemLength = 60}) {
    if (values.isEmpty) return '（資料不足）';
    return values
        .map((e) => _sanitizeForRender(e, maxLength: maxItemLength))
        .where((e) => e.isNotEmpty)
        .map((e) => '"$e"')
        .join('、');
  }

  bool _stopPhrase(String text) {
    final normalized = text.toLowerCase();
    if (normalized.length < 4) return true;
    return _stopWords.any((word) => normalized == word);
  }

  String _slugify(String value) {
    final ascii = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return ascii.isEmpty ? 'skill' : ascii;
  }

  String _yamlScalar(String value) {
    final sanitized = _sanitizeForRender(
      value,
      maxLength: 200,
    ).replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', ' ');
    return '"$sanitized"';
  }

  List<String> _boundedList(
    List<String> values, {
    required int maxItems,
    required int maxItemLength,
  }) {
    return values
        .map((e) => _sanitizeForRender(e, maxLength: maxItemLength))
        .where((e) => e.isNotEmpty)
        .take(maxItems)
        .toList(growable: false);
  }

  String _sanitizeForRender(String value, {required int maxLength}) {
    var result = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    result = result.replaceAll('```', "'''");
    result = result.replaceAll(
      RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'),
      '',
    );
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }
    return result;
  }
}

const Set<String> _stopWords = <String>{
  '我們',
  '你們',
  '他們',
  '這個',
  '那個',
  '可以',
  '如果',
  '然後',
  '就是',
  '以及',
  'the',
  'and',
  'for',
  'with',
  'this',
  'that',
  'from',
  'have',
};
