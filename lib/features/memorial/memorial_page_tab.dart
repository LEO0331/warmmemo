import 'package:flutter/material.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/draft_storage.dart';

/// TAB 3 – 簡易紀念頁（One-page life summary）
class MemorialPageTab extends StatefulWidget {
  const MemorialPageTab({super.key});

  @override
  State<MemorialPageTab> createState() => _MemorialPageTabState();
}

class _MemorialPageTabState extends State<MemorialPageTab> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _mottoController = TextEditingController();
  final _bioController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _willNoteController = TextEditingController();

  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _mottoController.dispose();
    _bioController.dispose();
    _highlightsController.dispose();
    _willNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '簡易紀念頁（示意原型）',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '這裡示範「一頁式生命摘要」的填寫方式，'
              '正式商業版會在雲端產生一個專屬連結，提供家屬於告別式前後 14 天分享給親友瀏覽，'
              '並可選擇是否付費延長保存。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  LabeledTextField(
                    label: '本名（必填）',
                    controller: _nameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '請輸入姓名' : null,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '暱稱／大家怎麼叫他（她）',
                    controller: _nicknameController,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '一句話座右銘／代表他的話',
                    controller: _mottoController,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '生命故事簡介（100–300 字）',
                    controller: _bioController,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '人生幾個重要片段（學業、工作、家庭、興趣…）',
                    controller: _highlightsController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '想留下給家人／朋友的一段話（可作為遺言雛形）',
                    controller: _willNoteController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('產生紀念頁預覽'),
                      onPressed: () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        await _saveDraft();
                        setState(() {
                          _showPreview = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_showPreview) _buildPreviewCard(theme),
            const SizedBox(height: 24),
            const SectionCard(
              title: '商業思維：紀念頁如何變成服務？',
              icon: Icons.lightbulb_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('・免費版：與喪葬方案綁定，提供 14 日連結，有效期限到期自動下架'),
                  SizedBox(height: 4),
                  Text('・付費升級：延長保存、更多照片／影片空間、自訂網址'),
                  SizedBox(height: 4),
                  Text('・B2B：提供禮儀公司白標版本，讓他們也能提供數位紀念服務'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final displayName =
        _nicknameController.text.trim().isEmpty ? _nameController.text : _nicknameController.text;
    final motto = _mottoController.text.trim();
    final fakeLinkId = _nameController.text.isEmpty
        ? 'example1234'
        : _nameController.text.hashCode.toRadixString(16);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (motto.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '「$motto」',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_bioController.text.trim().isNotEmpty) ...[
              Text(
                '生命故事',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_bioController.text),
              const SizedBox(height: 12),
            ],
            if (_highlightsController.text.trim().isNotEmpty) ...[
              Text(
                '人生片段',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_highlightsController.text),
              const SizedBox(height: 12),
            ],
            if (_willNoteController.text.trim().isNotEmpty) ...[
              Text(
                '留給大家的話',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_willNoteController.text),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.link_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'https://warmmemo.tw/m/$fakeLinkId',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '示意：正式服務中，此連結將於建立後 14 天內可供瀏覽，逾期可付費延長保存。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDraft() async {
    final storage = await DraftStorage.instance;
    final draft = storage.loadMemorialDraft();
    if (draft == null) return;

    setState(() {
      _nameController.text = draft.name ?? '';
      _nicknameController.text = draft.nickname ?? '';
      _mottoController.text = draft.motto ?? '';
      _bioController.text = draft.bio ?? '';
      _highlightsController.text = draft.highlights ?? '';
      _willNoteController.text = draft.willNote ?? '';
    });
  }

  Future<void> _saveDraft() async {
    final storage = await DraftStorage.instance;
    final draft = MemorialDraft(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      motto: _mottoController.text.trim(),
      bio: _bioController.text.trim(),
      highlights: _highlightsController.text.trim(),
      willNote: _willNoteController.text.trim(),
    );

    await storage.saveMemorialDraft(draft);
  }
}
