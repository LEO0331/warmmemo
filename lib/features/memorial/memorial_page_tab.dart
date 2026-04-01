import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/export/pdf_exporter.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/token_wallet_service.dart';
import '../../data/services/user_profile_service.dart';

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
  final _previewKey = GlobalKey();
  DraftStats? _stats;

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
      child: SelectionArea(
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
              '填寫親友的故事與回憶後，即可生成預覽，並透過 PDF／圖片快速分享給親友與長輩。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '進階服務採用點數制，新註冊贈送 5 點，每次生成/匯出會扣 1 點。',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7A4C39)),
            ),
            const SizedBox(height: 12),
            if (_stats != null) _buildStatsCard(theme, _stats!),
            if (_stats != null && AuthService.instance.currentUser?.uid != null)
              const SizedBox(height: 12),
            if (_stats != null && AuthService.instance.currentUser?.uid != null)
              _buildUserNotificationCard(AuthService.instance.currentUser!.uid),
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
                        final ok = await _consumeTokenOrShowTopUp(
                          AdvancedServiceType.memorialPreview,
                        );
                        if (!ok) return;
                        await _saveDraft();
                        final uid = AuthService.instance.currentUser?.uid;
                        if (uid != null) {
                          await UserProfileService.instance.markOnboardingStep(
                            uid,
                            UserProfileService.onboardingStepFirstDraft,
                          );
                        }
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
            if (_showPreview)
              RepaintBoundary(
                key: _previewKey,
                child: _buildPreviewCard(theme),
              ),
            if (_showPreview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('匯出 PDF'),
                        onPressed: () async {
                          final ok = await _consumeTokenOrShowTopUp(
                            AdvancedServiceType.memorialExportPdf,
                          );
                          if (!ok) return;
                          await _exportMemorialPdf();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('匯出圖片'),
                        onPressed: () async {
                          final ok = await _consumeTokenOrShowTopUp(
                            AdvancedServiceType.memorialExportImage,
                          );
                          if (!ok) return;
                          await _exportMemorialImage();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, DraftStats stats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn(theme, '閱讀次數', stats.readCount),
            _statColumn(theme, '點擊次數', stats.clickCount),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNotificationCard(String uid) {
    return StreamBuilder<List<NotificationEvent>>(
      stream: NotificationService.instance.streamForUser(uid),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const SectionCard(
            title: '我的通知狀態',
            icon: Icons.notifications_outlined,
            child: Text('尚未有通知紀錄，系統會自動追蹤閱讀與點擊。'),
          );
        }
        return SectionCard(
          title: '我的通知狀態',
          icon: Icons.notifications_outlined,
          child: Column(
            children: events
                .take(4)
                .map(
                  (event) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      event.status == 'read'
                          ? Icons.mark_email_read_outlined
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    title: Text(event.draftType ?? '草稿'),
                    subtitle: Text(
                      '${event.channel} · ${event.status}${event.tone != null ? ' · ${event.tone}' : ''}',
                    ),
                    trailing: Text(
                      event.occurredAt.toLocal().toString().split('.').first,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _statColumn(ThemeData theme, String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value.toString(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '一鍵複製全文',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () async {
                    final fullText = [
                      displayName,
                      if (motto.isNotEmpty) '「$motto」',
                      if (_bioController.text.trim().isNotEmpty) _bioController.text,
                      if (_highlightsController.text.trim().isNotEmpty) _highlightsController.text,
                      if (_willNoteController.text.trim().isNotEmpty) _willNoteController.text,
                    ].join('\n');
                    await Clipboard.setData(ClipboardData(text: fullText));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('紀念頁內容已複製')));
                  },
                ),
              ],
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
              SelectableText(_bioController.text),
              const SizedBox(height: 12),
            ],
            if (_highlightsController.text.trim().isNotEmpty) ...[
              Text(
                '人生片段',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(_highlightsController.text),
              const SizedBox(height: 12),
            ],
            if (_willNoteController.text.trim().isNotEmpty) ...[
              Text(
                '留給大家的話',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(_willNoteController.text),
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
                  child: InkWell(
                    onTap: () async {
                      final url = Uri.parse('https://warmmemo.tw/m/$fakeLinkId');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    onLongPress: () {
                      // 長按自動複製到剪貼簿
                      Clipboard.setData(ClipboardData(text: 'https://warmmemo.tw/m/$fakeLinkId'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已複製連結')),
                      );
                    },
                    child: Text(
                      'https://warmmemo.tw/m/$fakeLinkId',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline, // 增加底線讓它看起來像連結
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final draft = await FirebaseDraftService.instance.loadMemorial(uid);
    await _refreshStats(uid);
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

  Future<void> _refreshStats(String uid) async {
    final stats = await FirebaseDraftService.instance.loadStats(uid);
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _saveDraft() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final draft = MemorialDraft(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      motto: _mottoController.text.trim(),
      bio: _bioController.text.trim(),
      highlights: _highlightsController.text.trim(),
      willNote: _willNoteController.text.trim(),
    );

    await FirebaseDraftService.instance.saveMemorial(uid, draft);
    await _refreshStats(uid);
  }

  MemorialDraft get _currentMemorialDraft => MemorialDraft(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        motto: _mottoController.text.trim(),
        bio: _bioController.text.trim(),
        highlights: _highlightsController.text.trim(),
        willNote: _willNoteController.text.trim(),
      );

  Future<void> _exportMemorialPdf() async {
    try {
      await PdfExporter.exportMemorial(_currentMemorialDraft);
      _showMessage('PDF 已準備好');
    } catch (error) {
      _showMessage('匯出失敗：$error');
    }
  }

  Future<bool> _consumeTokenOrShowTopUp(AdvancedServiceType type) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      _showMessage('請先登入再使用進階功能。');
      return false;
    }
    final result = await TokenWalletService.instance.consume(
      uid: uid,
      type: type,
    );
    if (result.ok) return true;
    _showMessage('${result.message ?? '點數不足'}（目前 ${result.balanceAfter} 點）');
    await _showTopUpRequestDialog(uid);
    return false;
  }

  Future<void> _showTopUpRequestDialog(String uid) async {
    int selectedTokens = 10;
    final noteController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('提交加值申請'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('目前點數不足，可先送出加值申請，客服會協助你完成。'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: selectedTokens,
                decoration: const InputDecoration(labelText: '需求點數'),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 點')),
                  DropdownMenuItem(value: 20, child: Text('20 點')),
                  DropdownMenuItem(value: 50, child: Text('50 點')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedTokens = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '備註（可留空）'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('送出申請'),
            ),
          ],
        ),
      ),
    );
    if (submit == true) {
      await UserProfileService.instance.submitTopUpRequest(
        uid: uid,
        requestedTokens: selectedTokens,
        note: noteController.text,
      );
      _showMessage('加值申請已送出，客服將盡快聯繫。');
    }
    noteController.dispose();
  }

  Future<void> _exportMemorialImage() async {
    final bytes = await _capturePreviewImage();
    if (bytes == null) {
      _showMessage('無法擷取畫面');
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'warmmemo_memorial.png',
        ),
      ],
      text: 'WarmMemo 紀念頁圖片',
    );
    _showMessage('圖片已準備好');
  }

  Future<Uint8List?> _capturePreviewImage() async {
    final context = _previewKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
