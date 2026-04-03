import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/export/pdf_exporter.dart';
import '../../core/utils/download_bytes_stub.dart'
    if (dart.library.html) '../../core/utils/download_bytes_web.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';
import '../../data/services/token_wallet_service.dart';
import '../../data/services/user_profile_service.dart';

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
  String _templateVersion = 'v2';
  String _generatedText = '';
  List<String> _qualityWarnings = const [];
  final _previewKey = GlobalKey();
  final _qrKey = GlobalKey();

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
    _normalizeInputs();

    final name = _safeName;
    final rel = _safeRelationship;
    final loc = _safeLocation;
    final date = _safeServiceDate;
    final note = _safeNote;

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
      _qualityWarnings = _scanQualityWarnings(_generatedText);
    });
  }

  List<String> _scanQualityWarnings(String text) {
    final warnings = <String>[];
    final bannedWords = <String>['保證', '最便宜', '立刻成交'];
    for (final word in bannedWords) {
      if (text.contains(word)) {
        warnings.add('文案含敏感商業字詞：$word');
      }
    }
    if (!_serviceDateController.text.contains(RegExp(r'[0-9]'))) {
      warnings.add('建議補上可辨識日期，避免親友誤會時間。');
    }
    if (_locationController.text.trim().isEmpty) {
      warnings.add('建議補上地點，提升通知完整度。');
    }
    return warnings;
  }

  void _rewriteForClarity() {
    if (_generatedText.trim().isEmpty) return;
    _normalizeInputs();
    final compact = StringBuffer()
      ..writeln('各位親友您好：')
      ..writeln()
      ..writeln('$_safeRelationship在此通知，我們摯愛的「$_safeName」已安息。')
      ..writeln(
        '追思儀式時間：${_safeServiceDate.isEmpty ? '待補充' : _safeServiceDate}。',
      )
      ..writeln('地點：${_safeLocation.isEmpty ? '待補充' : _safeLocation}。')
      ..writeln()
      ..writeln(_safeNote.isEmpty ? '感謝大家的關心與陪伴。' : _safeNote);
    setState(() {
      _generatedText = compact.toString().trim();
      _qualityWarnings = _scanQualityWarnings(_generatedText);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  eyebrow: 'Obituary',
                  icon: Icons.campaign_outlined,
                  title: '數位訃聞草稿工具',
                  subtitle: '協助家屬打造清楚訃聞內容，完成後可快速分享文字、匯出 PDF/圖片與 QR 摘要，通知親友更便利。',
                  badges: ['清楚通知', '語氣模板', '多格式輸出'],
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LabeledTextField(
                        label: '往生者姓名（必填）',
                        controller: _deceasedNameController,
                        validator: (v) {
                          final safe = _sanitizeOpenText(
                            v ?? '',
                            maxLength: 40,
                          );
                          if (safe.isEmpty) return '請輸入姓名';
                          return null;
                        },
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
                        validator: (v) {
                          final raw = (v ?? '').trim();
                          if (raw.isEmpty) return null;
                          final safe = _sanitizeDateText(raw);
                          if (safe.isEmpty) return '請輸入有效日期或時間';
                          if (!RegExp(r'[0-9一二三四五六七八九十]').hasMatch(safe)) {
                            return '請包含可辨識日期資訊';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '希望的語氣',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('模板 v2（推薦）'),
                            selected: _templateVersion == 'v2',
                            onSelected: (_) =>
                                setState(() => _templateVersion = 'v2'),
                          ),
                          ChoiceChip(
                            label: const Text('模板 v1（簡潔）'),
                            selected: _templateVersion == 'v1',
                            onSelected: (_) =>
                                setState(() => _templateVersion = 'v1'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                            try {
                              if (_templateVersion == 'v1' && _tone == '溫和正式') {
                                setState(() => _tone = '極簡通知');
                              }
                              final ok = await _consumeTokenOrShowTopUp(
                                AdvancedServiceType.obituaryGenerate,
                              );
                              if (!ok) return;
                              _generateObituary();
                              await _saveDraft();
                              final uid = AuthService.instance.currentUser?.uid;
                              if (uid != null) {
                                try {
                                  await UserProfileService.instance
                                      .markOnboardingStep(
                                        uid,
                                        UserProfileService
                                            .onboardingStepFirstDraft,
                                      );
                                } catch (_) {
                                  // Do not block primary flow if onboarding write fails.
                                }
                              }
                            } catch (error) {
                              _showMessage(
                                _friendlyErrorMessage(
                                  error,
                                  fallback: '產生訃聞時發生錯誤，請稍後再試。',
                                ),
                              );
                            }
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
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
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
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await Clipboard.setData(
                                      ClipboardData(text: _generatedText),
                                    );
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
                            if (_qualityWarnings.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '文案檢查建議',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    ..._qualityWarnings.map(
                                      (item) => SelectableText('• $item'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final ok = await _consumeTokenOrShowTopUp(
                                      AdvancedServiceType.obituaryRewrite,
                                    );
                                    if (!ok) return;
                                    _rewriteForClarity();
                                  } catch (error) {
                                    _showMessage(
                                      _friendlyErrorMessage(
                                        error,
                                        fallback: '重寫失敗，請稍後再試。',
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.auto_fix_high_outlined),
                                label: const Text('一鍵重寫（更清楚）'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_generatedText.isNotEmpty)
                  SectionCard(
                    title: '快速分享',
                    icon: Icons.qr_code_2_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '可直接分享連結或文字，親友掃描 QR 後可開啟公開訃聞頁。',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _obituaryShareUrl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _shareObituaryLink,
                              icon: const Icon(Icons.ios_share_outlined),
                              label: const Text('分享訃聞連結'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _copyObituaryLink,
                              icon: const Icon(Icons.copy_all_outlined),
                              label: const Text('複製連結'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openObituaryLink,
                              icon: const Icon(Icons.open_in_new_outlined),
                              label: const Text('開啟連結'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _shareToFacebook,
                              icon: const Icon(Icons.facebook_outlined),
                              label: const Text('分享到 Facebook'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _shareToLine,
                              icon: const Icon(Icons.send_outlined),
                              label: const Text('分享到 LINE'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _shareByEmail,
                              icon: const Icon(Icons.email_outlined),
                              label: const Text('寄送 Email'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _downloadQrImage,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('下載 QR 圖片'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE8D7CC),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  QrImageView(
                                    data: _obituaryShareUrl,
                                    size: 168,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '訃聞連結 QR',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_generatedText.isNotEmpty) const SizedBox(height: 24),
                if (_generatedText.isNotEmpty)
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
                                AdvancedServiceType.obituaryExportPdf,
                              );
                              if (!ok) return;
                              await _exportObituaryPdf();
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
                                AdvancedServiceType.obituaryExportImage,
                              );
                              if (!ok) return;
                              await _exportObituaryImage();
                            },
                          ),
                        ),
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

  Future<void> _loadDraft() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    ObituaryDraft? draft;
    try {
      draft = await FirebaseDraftService.instance.loadObituary(uid);
    } catch (_) {
      return;
    }
    if (draft == null) return;
    final currentDraft = draft;

    setState(() {
      _deceasedNameController.text = currentDraft.deceasedName ?? '';
      _relationshipController.text = currentDraft.relationship ?? '家屬';
      _locationController.text = currentDraft.location ?? '';
      _serviceDateController.text = currentDraft.serviceDate ?? '';
      _tone = currentDraft.tone ?? '溫和正式';
      _customNoteController.text = currentDraft.customNote ?? '';
    });
  }

  Future<void> _saveDraft() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    _normalizeInputs();

    final draft = ObituaryDraft(
      deceasedName: _safeName,
      relationship: _safeRelationship,
      location: _safeLocation,
      serviceDate: _safeServiceDate,
      tone: _tone,
      customNote: _safeNote,
    );

    try {
      await FirebaseDraftService.instance.saveObituary(uid, draft);
    } catch (_) {
      // Draft persistence failure should not crash the user flow.
    }
  }

  ObituaryDraft get _currentObituaryDraft => ObituaryDraft(
    deceasedName: _safeName,
    relationship: _safeRelationship,
    location: _safeLocation,
    serviceDate: _safeServiceDate,
    tone: _tone,
    customNote: _safeNote,
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

    try {
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'warmmemo_obituary.png',
        ),
      ], text: 'WarmMemo 訃聞圖片');
      _showMessage('圖片已準備好');
    } catch (error) {
      _showMessage(_friendlyErrorMessage(error, fallback: '分享圖片失敗，請稍後再試。'));
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final message = result.errorCode == 'insufficient-balance'
        ? '${result.message ?? '點數不足'}（目前 ${result.balanceAfter} 點）'
        : (result.message ?? '點數扣除失敗，請稍後再試。');
    _showMessage(message);
    if (result.errorCode == 'insufficient-balance') {
      await _showTopUpRequestDialog(uid);
    }
    return false;
  }

  String get _obituaryShareUrl {
    final payload = <String, String>{
      'name': _safeName,
      'relationship': _safeRelationship,
      'location': _safeLocation,
      'date': _safeServiceDate,
      'note': _safeNote,
      'tone': _tone,
    };
    final encoded = base64UrlEncode(utf8.encode(jsonEncode(payload)));
    return '$_publicBaseUrl/#/o?d=${Uri.encodeComponent(encoded)}';
  }

  String get _publicBaseUrl {
    const envBaseUrl = String.fromEnvironment('PUBLIC_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    final origin = Uri.base.origin;
    final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      return '$origin/${segments.first}';
    }
    return origin;
  }

  Future<void> _shareObituaryLink() async {
    try {
      await Share.share(_obituaryShareUrl, subject: 'WarmMemo 訃聞通知');
    } catch (error) {
      _showMessage(_friendlyErrorMessage(error, fallback: '分享失敗，請稍後再試。'));
    }
  }

  Future<void> _copyObituaryLink() async {
    await Clipboard.setData(ClipboardData(text: _obituaryShareUrl));
    _showMessage('連結已複製。');
  }

  Future<void> _openObituaryLink() async {
    final uri = Uri.tryParse(_obituaryShareUrl);
    if (uri == null) {
      _showMessage('連結格式有誤。');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showMessage('目前無法開啟連結。');
    }
  }

  Future<void> _shareToFacebook() async {
    final url = Uri.encodeComponent(_obituaryShareUrl);
    final uri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$url');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showMessage('無法啟動 Facebook 分享，已改用一般分享。');
      await _shareObituaryLink();
    }
  }

  Future<void> _shareToLine() async {
    final url = Uri.encodeComponent(_obituaryShareUrl);
    final uri = Uri.parse(
      'https://social-plugins.line.me/lineit/share?url=$url',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showMessage('無法啟動 LINE 分享，已改用一般分享。');
      await _shareObituaryLink();
    }
  }

  Future<void> _shareByEmail() async {
    final subject = Uri.encodeComponent('WarmMemo 訃聞通知');
    final body = Uri.encodeComponent('訃聞連結：$_obituaryShareUrl');
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showMessage('無法啟動 Email 應用程式。');
    }
  }

  Future<void> _downloadQrImage() async {
    final bytes = await _captureQrImage();
    if (bytes == null) {
      _showMessage('目前無法產生 QR 圖片。');
      return;
    }
    try {
      await downloadPngBytes(
        bytes: bytes,
        filename: 'warmmemo_obituary_qr.png',
      );
      _showMessage('QR 圖片已下載。');
    } catch (error) {
      _showMessage(_friendlyErrorMessage(error, fallback: '下載 QR 失敗，請稍後再試。'));
    }
  }

  String get _safeName =>
      _sanitizeOpenText(_deceasedNameController.text, maxLength: 40);
  String get _safeRelationship =>
      _sanitizeOpenText(_relationshipController.text, maxLength: 24);
  String get _safeLocation =>
      _sanitizeOpenText(_locationController.text, maxLength: 80);
  String get _safeServiceDate => _sanitizeDateText(_serviceDateController.text);
  String get _safeNote => _sanitizeOpenText(
    _customNoteController.text,
    maxLength: 240,
    keepLineBreaks: true,
  );

  void _normalizeInputs() {
    final nextName = _safeName;
    final nextRelationship = _safeRelationship.isEmpty
        ? '家屬'
        : _safeRelationship;
    final nextLocation = _safeLocation;
    final nextDate = _safeServiceDate;
    final nextNote = _safeNote;
    if (_deceasedNameController.text != nextName) {
      _deceasedNameController.text = nextName;
    }
    if (_relationshipController.text != nextRelationship) {
      _relationshipController.text = nextRelationship;
    }
    if (_locationController.text != nextLocation) {
      _locationController.text = nextLocation;
    }
    if (_serviceDateController.text != nextDate) {
      _serviceDateController.text = nextDate;
    }
    if (_customNoteController.text != nextNote) {
      _customNoteController.text = nextNote;
    }
  }

  String _sanitizeDateText(String input) {
    final sanitized = _sanitizeOpenText(input, maxLength: 48);
    if (sanitized.isEmpty) return '';
    return sanitized.replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  String _sanitizeOpenText(
    String input, {
    int maxLength = 120,
    bool keepLineBreaks = false,
  }) {
    var text = input;
    text = text.replaceAll(
      RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'),
      '',
    );
    text = text.replaceAll('<', '＜').replaceAll('>', '＞');
    if (!keepLineBreaks) {
      text = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    } else {
      text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    }
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
    }
    return text;
  }

  Future<Uint8List?> _captureQrImage() async {
    final context = _qrKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  String _friendlyErrorMessage(Object error, {required String fallback}) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return '權限不足，請確認登入帳號與 Firestore 規則設定。';
      }
      return error.message ?? fallback;
    }
    if (error is PlatformException) {
      return error.message ?? fallback;
    }
    return fallback;
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
}
