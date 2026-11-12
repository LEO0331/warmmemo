import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/draft_models.dart';
import '../utils/meaning_memory_copy.dart';

class PdfExporter {
  PdfExporter._();

  static final _subset = _PdfFontAsset('assets/fonts/NotoSansTC-Subset.ttf');
  static final _bold = _PdfFontAsset('assets/fonts/NotoSansTC-Bold-Subset.ttf');
  static final _full = _PdfFontAsset('assets/fonts/NotoSansTC-Regular.ttf');

  static Future<void> exportMemorial(
    MemorialDraft draft, {
    String? publicUrl,
    String languageCode = 'zh',
  }) async {
    final bytes = await memorialBytes(
      draft,
      publicUrl: publicUrl,
      languageCode: languageCode,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'warmmemo_memorial.pdf');
  }

  static Future<void> exportObituary(ObituaryDraft draft) async {
    final bytes = await obituaryBytes(draft);
    await Printing.sharePdf(bytes: bytes, filename: 'warmmemo_obituary.pdf');
  }

  static Future<Uint8List> memorialBytes(
    MemorialDraft draft, {
    String? publicUrl,
    String languageCode = 'zh',
  }) {
    final meaning = MeaningMemoryCopy.forLanguageCode(languageCode);
    return _buildPdf(
      title: 'WarmMemo 紀念頁',
      fields: [
        ('姓名', draft.name),
        ('暱稱', draft.nickname),
        ('一句話', draft.motto),
      ],
      sections: [
        ('生平摘要', draft.bio),
        ('人生亮點', draft.highlights),
        ('給後人的話', draft.willNote),
        (meaning.storyPrompt, draft.meaningLifeStory),
        (meaning.purposePrompt, draft.meaningPurpose),
        (meaning.matteredToPrompt, draft.meaningMatteredTo),
        (meaning.memoriesPrompt, draft.meaningMemoriesToKeep),
      ],
      publicUrl: publicUrl != null && publicUrl.trim().isNotEmpty
          ? publicUrl
          : null,
    );
  }

  static Future<Uint8List> obituaryBytes(ObituaryDraft draft) {
    return _buildPdf(
      title: 'WarmMemo 訃聞',
      fields: [
        ('逝者姓名', draft.deceasedName),
        ('關係', draft.relationship),
        ('地點', draft.location),
        ('時間', draft.serviceDate),
        ('語氣', draft.tone),
      ],
      sections: [('補充註記', draft.customNote)],
    );
  }

  static Future<Uint8List> _buildPdf({
    required String title,
    required List<(String, String?)> fields,
    required List<(String, String?)> sections,
    String? publicUrl,
  }) async {
    final rows = [
      for (final (label, value) in fields) ('$label：', _normalizeText(value)),
    ];
    final paragraphs = [
      for (final (label, value) in sections)
        if (value != null && value.isNotEmpty) (label, _normalizeText(value)),
    ];
    const linkHeading = '公開紀念頁';
    final base = await _resolveFont(_subset, [
      for (final (_, text) in rows) text,
      for (final (_, text) in paragraphs) text,
      if (publicUrl != null) _normalizeText(publicUrl),
    ]);
    final bold = await _resolveFont(_bold, [
      title,
      for (final (label, _) in rows) label,
      for (final (label, _) in paragraphs) label,
      if (publicUrl != null) linkHeading,
    ]);

    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              for (final (label, value) in rows) _labelValue(label, value),
              for (final (label, value) in paragraphs) _section(label, value),
              if (publicUrl != null) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  linkHeading,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(_normalizeText(publicUrl)),
                pw.SizedBox(height: 10),
                pw.SizedBox(
                  width: 112,
                  height: 112,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: publicUrl,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  static String _normalizeText(String? text) =>
      (text ?? '').replaceAll(RegExp(r'\r\n?'), '\n').replaceAll('\t', ' ');

  static Future<pw.Font> _resolveFont(
    _PdfFontAsset preferred,
    List<String> text,
  ) async {
    final runes = {
      for (final value in text) ...value.runes.where((rune) => rune != 0x0a),
    };
    final subset = await preferred.load();
    if (subset != null && runes.every(subset.supports)) {
      return pw.Font.ttf(subset.bytes);
    }

    final full = await _full.load();
    if (full == null) {
      throw StateError('無法載入 PDF 字型。請重新連線載入頁面資源後再試。');
    }
    for (final rune in runes) {
      if (!full.supports(rune)) {
        final code = rune.toRadixString(16).toUpperCase().padLeft(4, '0');
        throw FormatException('PDF 字型不支援字元 U+$code。請修改該字元後再試。');
      }
    }
    return pw.Font.ttf(full.bytes);
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(body),
        ],
      ),
    );
  }
}

class _PdfFontAsset {
  _PdfFontAsset(this.path);

  final String path;
  _LoadedPdfFont? _cached;

  Future<_LoadedPdfFont?> load() async {
    if (_cached != null) return _cached;
    try {
      final bytes = await rootBundle.load(path);
      final glyphs = TtfParser(bytes).charToGlyphIndexMap;
      return _cached = _LoadedPdfFont(bytes, glyphs);
    } catch (_) {
      // A missing asset can be retried once the browser is connected again.
      return null;
    }
  }
}

class _LoadedPdfFont {
  _LoadedPdfFont(this.bytes, this.glyphs);

  final ByteData bytes;
  final Map<int, int> glyphs;

  bool supports(int rune) => (glyphs[rune] ?? 0) > 0;
}
