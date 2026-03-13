import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/export/pdf_exporter.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';

/// TAB 4 – 數位訃聞系統（Digital Obituary）
class DigitalObituaryTab extends StatefulWidget {
  const DigitalObituaryTab({super.key});

  @override
  State<DigitalObituaryTab> createState() => _DigitalObituaryTabState();
}

class _DigitalObituaryTabState extends State<DigitalObituaryTab> {
  final _formKey = GlobalKey<FormState>();
  final _deceasedNameController = TextEditingController();
  final _relationshipController = TextEditingController(text: '家屬');
  final _locationController = TextEditingController();
  final _serviceDateController = TextEditingController();
  final _customNoteController = TextEditingController();

  String _tone = '溫和正式';
  String _generatedText = '';
  final _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _deceasedNameController.dispose();
    _relationshipController.dispose();
    _locationController.dispose();
    _serviceDateController.dispose();
    _customNoteController.dispose();
    super.dispose();
  }

  void _generateObituary() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _deceasedNameController.text.trim();
    final rel = _relationshipController.text.trim();
    final loc = _locationController.text.trim();
    final date = _serviceDateController.text.trim();
    final note = _customNoteController.text.trim();

    String base;
    switch (_tone) {
      case '宗教色彩':
        base =
            '敬啟者：\n\n$rel謹此沉痛告知，家中至親「$name」已安息主懷／往生極樂，'
            '我們將於 $date 於 $loc 舉行追思告別禮拜／誦經告別儀式，敬邀親友同來追思與祝禱。';
        break;
      case '極簡通知':
        base =
            '各位親友好：\n\n家中親人「$name」已於近日辭世，告別式將於 $date 在 $loc 舉行，'
            '不收奠儀與花圈，願一切從簡，心意到即可。';
        break;
      default:
        base =
            '親愛的親友們：\n\n$rel在此向各位沉痛告知，我們深愛的「$name」已於近日離世。'
            '告別與追思儀式訂於 $date 在 $loc 舉行，誠摯邀請曾與他（她）有緣的朋友，一同以祝福與思念送他（她）最後一程。';
    }

    final footer = note.isEmpty
        ? '\n\n敬請以祝福代替過多關心，讓家屬有空間整理心情。感謝您與我們一同紀念他（她）的一生。'
        : '\n\n$note';

    setState(() {
      _generatedText = '$base$footer';
    });
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
              '數位訃聞草稿工具',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '協助家屬打造清楚的訃聞內容，完成後可立即生成分享文、PDF、圖片或 QR code，讓通知快速觸達親友。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  LabeledTextField(
                    label: '往生者姓名（必填）',
                    controller: _deceasedNameController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '請輸入姓名' : null,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '發文人身分（例如：家屬、長子、長女…）',
                    controller: _relationshipController,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '告別／追思儀式地點',
                    controller: _locationController,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '日期與時間（例如：4/20（日）上午 10:00）',
                    controller: _serviceDateController,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '希望的語氣',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('溫和正式'),
                        selected: _tone == '溫和正式',
                        onSelected: (_) {
                          setState(() => _tone = '溫和正式');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('宗教色彩'),
                        selected: _tone == '宗教色彩',
                        onSelected: (_) {
                          setState(() => _tone = '宗教色彩');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('極簡通知'),
                        selected: _tone == '極簡通知',
                        onSelected: (_) {
                          setState(() => _tone = '極簡通知');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: '額外想補充的說明（例如：不收奠儀、改以捐款⋯）',
                    controller: _customNoteController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.auto_fix_high_outlined),
                      label: const Text('產生訃聞文案'),
                      onPressed: () async {
                        _generateObituary();
                        await _saveDraft();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_generatedText.isNotEmpty)
              RepaintBoundary(
                key: _previewKey,
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '可直接貼到通訊軟體的訃聞文字',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: '一鍵複製',
                              icon: const Icon(Icons.copy_all_outlined),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await Clipboard.setData(ClipboardData(text: _generatedText));
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('文案已複製')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _generatedText,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_generatedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('匯出 PDF'),
                        onPressed: _exportObituaryPdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('匯出圖片'),
                        onPressed: _exportObituaryImage,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDraft() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final draft = await FirebaseDraftService.instance.loadObituary(uid);
    if (draft == null) return;

    setState(() {
      _deceasedNameController.text = draft.deceasedName ?? '';
      _relationshipController.text = draft.relationship ?? '家屬';
      _locationController.text = draft.location ?? '';
      _serviceDateController.text = draft.serviceDate ?? '';
      _tone = draft.tone ?? '溫和正式';
      _customNoteController.text = draft.customNote ?? '';
    });
  }

  Future<void> _saveDraft() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final draft = ObituaryDraft(
      deceasedName: _deceasedNameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      location: _locationController.text.trim(),
      serviceDate: _serviceDateController.text.trim(),
      tone: _tone,
      customNote: _customNoteController.text.trim(),
    );

    await FirebaseDraftService.instance.saveObituary(uid, draft);
  }

  ObituaryDraft get _currentObituaryDraft => ObituaryDraft(
        deceasedName: _deceasedNameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        location: _locationController.text.trim(),
        serviceDate: _serviceDateController.text.trim(),
        tone: _tone,
        customNote: _customNoteController.text.trim(),
      );

  Future<void> _exportObituaryPdf() async {
    try {
      await PdfExporter.exportObituary(_currentObituaryDraft);
      _showMessage('PDF 已準備好');
    } catch (error) {
      _showMessage('匯出失敗：$error');
    }
  }

  Future<void> _exportObituaryImage() async {
    final bytes = await _captureObituaryImage();
    if (bytes == null) {
      _showMessage('無法擷取圖片');
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'warmmemo_obituary.png',
        ),
      ],
      text: 'WarmMemo 訃聞圖片',
    );
    _showMessage('圖片已準備好');
  }

  Future<Uint8List?> _captureObituaryImage() async {
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
