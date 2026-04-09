import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/download_text_stub.dart'
    if (dart.library.html) '../../core/utils/download_text_web.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/models/cyber_skill.dart';
import '../../data/services/cyber_skill_generator_service.dart';
import '../../data/services/cyber_skill_storage_service.dart';

class SkillGeneratorTab extends StatefulWidget {
  const SkillGeneratorTab({
    super.key,
    CyberSkillGeneratorService? generator,
    CyberSkillStorageService? storage,
    String? Function()? currentUidProvider,
  }) : _generator = generator,
       _storage = storage,
       _currentUidProvider = currentUidProvider;

  final CyberSkillGeneratorService? _generator;
  final CyberSkillStorageService? _storage;
  final String? Function()? _currentUidProvider;

  @override
  State<SkillGeneratorTab> createState() => _SkillGeneratorTabState();
}

class _SkillGeneratorTabState extends State<SkillGeneratorTab> {
  late final CyberSkillGeneratorService _generator =
      widget._generator ?? const CyberSkillGeneratorService();
  late final CyberSkillStorageService _storage =
      widget._storage ?? CyberSkillStorageService.instance;
  late final String? Function() _currentUidProvider =
      widget._currentUidProvider ??
      (() => AuthService.instance.currentUser?.uid);

  final TextEditingController _jsonController = TextEditingController();
  TemplateType _templateType = TemplateType.warmmemoDaily;
  TemplateType? _historyFilter;
  CyberSkillInputV1? _parsedInput;
  CyberSkillAnalysis? _analysis;
  String _markdown = '';
  String? _error;
  bool _isGenerating = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUidProvider();
    final theme = Theme.of(context);

    return WarmBackdrop(
      child: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHero(
                  eyebrow: 'Cyber-Immortality',
                  icon: Icons.psychology_alt_outlined,
                  title: '數位分身 Skill 生成器',
                  subtitle:
                      '貼上標準化 JSON，快速生成可給 AI 使用的技能文件。可在「日常模式 WarmMemo」與「工作模式 Colleague」間切換。',
                  badges: ['雙版型切換', '可複製', '可下載', '可儲存'],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: '模式切換',
                  icon: Icons.swap_horiz_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TemplateType.values
                        .map(
                          (type) => ChoiceChip(
                            selected: _templateType == type,
                            label: Text(type.displayLabel),
                            onSelected: (_) => _switchTemplate(type),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'JSON 輸入（標準化原始材料型）',
                  icon: Icons.data_object_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        '必要欄位：profile + materials（messages/documents/emails 任一有資料）。',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _jsonController,
                        maxLines: 14,
                        minLines: 10,
                        decoration: const InputDecoration(
                          hintText:
                              '{\n  "profile": {...},\n  "materials": {\n    "messages": [...],\n    "documents": [...],\n    "emails": [...]\n  }\n}',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : _validateAndGenerate,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_fix_high_outlined),
                            label: Text(_isGenerating ? '生成中...' : '驗證並生成'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _applySampleJson,
                            icon: const Icon(Icons.notes_outlined),
                            label: const Text('套用範例 JSON'),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        SelectableText(
                          '錯誤：$_error',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: '生成結果',
                  icon: Icons.description_outlined,
                  child: _markdown.trim().isEmpty
                      ? const EmptyStateCard(
                          title: '尚未生成',
                          description: '先貼上標準化 JSON，按「驗證並生成」。',
                          icon: Icons.edit_note_outlined,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _copyMarkdown,
                                  icon: const Icon(Icons.copy_all_outlined),
                                  label: const Text('一鍵複製'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _downloadMarkdown,
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('下載 .md'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: uid == null || _isSaving
                                      ? null
                                      : _saveSkill,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(_isSaving ? '儲存中...' : '儲存到雲端'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SelectableText(
                              _markdown,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamilyFallback: const ['monospace'],
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: '已儲存版本',
                  icon: Icons.history_outlined,
                  child: uid == null
                      ? const EmptyStateCard(
                          title: '尚未登入',
                          description: '登入後可保存與管理你的 Skill 版本。',
                          icon: Icons.lock_outline,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  selected: _historyFilter == null,
                                  label: const Text('全部'),
                                  onSelected: (_) {
                                    setState(() => _historyFilter = null);
                                  },
                                ),
                                ...TemplateType.values.map(
                                  (type) => ChoiceChip(
                                    selected: _historyFilter == type,
                                    label: Text(type.displayLabel),
                                    onSelected: (_) {
                                      setState(() => _historyFilter = type);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildSavedList(uid),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedList(String uid) {
    return StreamBuilder<List<SavedCyberSkill>>(
      stream: _storage.watchSkills(uid),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return SelectableText('讀取 Skill 失敗：${snapshot.error}');
        }
        final all = snapshot.data ?? const <SavedCyberSkill>[];
        final filtered = _historyFilter == null
            ? all
            : all.where((item) => item.templateType == _historyFilter).toList();
        if (filtered.isEmpty) {
          return const EmptyStateCard(
            title: '尚無儲存版本',
            description: '生成後按「儲存到雲端」，即可在這裡按模板查看。',
            icon: Icons.archive_outlined,
          );
        }
        return Column(
          children: filtered
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SavedSkillCard(
                    skill: item,
                    onCopy: () async {
                      await Clipboard.setData(
                        ClipboardData(text: item.markdown),
                      );
                      if (!mounted) return;
                      AppFeedback.show(
                        context,
                        message: '已複製 ${item.profileName} 的 Skill 內容',
                        tone: FeedbackTone.success,
                      );
                    },
                    onUse: () {
                      setState(() {
                        _templateType = item.templateType;
                        _markdown = item.markdown;
                        _error = null;
                      });
                    },
                    onDelete: () => _deleteSkill(item.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _validateAndGenerate() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final input = _generator.parseInput(_jsonController.text);
      final analysis = _generator.analyze(input);
      final markdown = _generator.renderFromAnalysis(
        profile: input.profile,
        analysis: analysis,
        templateType: _templateType,
      );
      if (!mounted) return;
      setState(() {
        _parsedInput = input;
        _analysis = analysis;
        _markdown = markdown;
      });
      AppFeedback.show(
        context,
        message: '已生成 ${_templateType.displayLabel} 版型。',
        tone: FeedbackTone.success,
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
      AppFeedback.show(context, message: e.message, tone: FeedbackTone.error);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      AppFeedback.show(
        context,
        message: '生成失敗，請稍後再試。',
        tone: FeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _switchTemplate(TemplateType type) {
    if (_templateType == type) return;
    setState(() => _templateType = type);
    final input = _parsedInput;
    final analysis = _analysis;
    if (input == null || analysis == null) return;
    final markdown = _generator.renderFromAnalysis(
      profile: input.profile,
      analysis: analysis,
      templateType: type,
    );
    setState(() => _markdown = markdown);
  }

  void _applySampleJson() {
    _jsonController.text = const JsonEncoder.withIndent(
      '  ',
    ).convert(_sampleInputMap);
  }

  Future<void> _copyMarkdown() async {
    if (_markdown.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _markdown));
    if (!mounted) return;
    AppFeedback.show(context, message: 'Skill 已複製', tone: FeedbackTone.success);
  }

  Future<void> _downloadMarkdown() async {
    if (_markdown.trim().isEmpty) return;
    final profileName = _parsedInput?.profile.name ?? 'skill';
    final suffix = _templateType == TemplateType.warmmemoDaily
        ? 'warmmemo'
        : 'colleague';
    final safeName = profileName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff]+', unicode: true), '');
    final filename = '${safeName.isEmpty ? 'skill' : safeName}_$suffix.md';
    await downloadTextFile(content: _markdown, filename: filename);
  }

  Future<void> _saveSkill() async {
    final uid = _currentUidProvider();
    final input = _parsedInput;
    final analysis = _analysis;
    if (uid == null || input == null || analysis == null || _markdown.isEmpty) {
      AppFeedback.show(
        context,
        message: '請先完成生成後再儲存。',
        tone: FeedbackTone.info,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _storage.saveSkill(
        uid: uid,
        templateType: _templateType,
        profile: input.profile,
        analysis: analysis,
        markdown: _markdown,
      );
      if (!mounted) return;
      AppFeedback.show(
        context,
        message: '已儲存到雲端版本列表。',
        tone: FeedbackTone.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, message: '儲存失敗：$e', tone: FeedbackTone.error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteSkill(String skillId) async {
    final uid = _currentUidProvider();
    if (uid == null) return;
    try {
      await _storage.deleteSkill(uid: uid, skillId: skillId);
      if (!mounted) return;
      AppFeedback.show(context, message: '已刪除版本', tone: FeedbackTone.success);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.show(context, message: '刪除失敗：$e', tone: FeedbackTone.error);
    }
  }
}

class _SavedSkillCard extends StatelessWidget {
  const _SavedSkillCard({
    required this.skill,
    required this.onCopy,
    required this.onUse,
    required this.onDelete,
  });

  final SavedCyberSkill skill;
  final VoidCallback onCopy;
  final VoidCallback onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = skill.markdown
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(4)
        .join('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D7CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${skill.profileName}｜${skill.templateType.displayLabel}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '更新：${skill.updatedAt.toIso8601String()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            preview,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUse,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('查看'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('複製'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('刪除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const Map<String, Object?> _sampleInputMap = <String, Object?>{
  'profile': <String, Object?>{
    'name': '小安',
    'company': 'WarmMemo',
    'level': 'P6',
    'role': '產品經理',
    'gender': '女',
    'mbti': 'INFJ',
    'personaTags': <String>['溫和', '結構化溝通', '重視同理'],
    'cultureTags': <String>['用戶導向', '務實'],
    'impression': '談話很溫柔但推進事情很穩定',
  },
  'materials': <String, Object?>{
    'messages': <Map<String, Object?>>[
      <String, Object?>{
        'sender': '小安',
        'content': '先說結論：我們本週先把通知流程補齊，再談加值包裝。',
        'timestamp': '2026-04-01T10:00:00Z',
      },
      <String, Object?>{
        'sender': '小安',
        'content': '我想先對齊背景，家屬最在意的是清楚、可預期、不要被臨時加價。',
        'timestamp': '2026-04-01T11:00:00Z',
      },
    ],
    'documents': <Map<String, Object?>>[
      <String, Object?>{
        'title': '客服話術草案',
        'content': '流程先共情，再確認需求，最後給 1-2 個可執行選項。',
        'source': 'doc://customer-support',
      },
    ],
    'emails': <Map<String, Object?>>[
      <String, Object?>{
        'from': 'xiaoan@warmmemo.io',
        'subject': '交付節點確認',
        'body': '請先確認風險與回滾方案，確認後再安排對外通知。',
        'date': '2026-04-02',
      },
    ],
  },
};
