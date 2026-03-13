import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/draft_models.dart';

class PdfExporter {
  PdfExporter._();

  static Future<void> exportMemorial(MemorialDraft draft) async {
    final bytes = await _pdfBytes(await _buildMemorialPage(draft));
    await Printing.sharePdf(bytes: bytes, filename: 'warmmemo_memorial.pdf');
  }

  static Future<void> exportObituary(ObituaryDraft draft) async {
    final bytes = await _pdfBytes(await _buildObituaryPage(draft));
    await Printing.sharePdf(bytes: bytes, filename: 'warmmemo_obituary.pdf');
  }

  static Future<pw.Page> _buildMemorialPage(MemorialDraft draft) async {
    final fontData = await rootBundle.load("assets/fonts/NotoSansTC-VariableFont_wght.ttf");
    final boldData = await rootBundle.load("assets/fonts/NotoSansTC-Bold.ttf");
    final myFont = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(boldData);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: myFont,
        bold: fontBold
      ),
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('WarmMemo 紀念頁草稿', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            _labelValue('姓名', draft.name ?? ''),
            _labelValue('暱稱', draft.nickname ?? ''),
            _labelValue('座右銘', draft.motto ?? ''),
            _section('生命故事', draft.bio),
            _section('人生片段', draft.highlights),
            _section('留給家人', draft.willNote),
          ],
        ),
      ),
    );
  }

  static Future<pw.Page> _buildObituaryPage(ObituaryDraft draft) async {
    final fontData = await rootBundle.load("assets/fonts/NotoSansTC-VariableFont_wght.ttf");
    final boldData = await rootBundle.load("assets/fonts/NotoSansTC-Bold.ttf");
    final myFont = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(boldData);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: myFont,
        bold: fontBold
      ),
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('WarmMemo 訃聞草稿', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            _labelValue('往生者', draft.deceasedName ?? ''),
            _labelValue('關係', draft.relationship ?? ''),
            _labelValue('地點', draft.location ?? ''),
            _labelValue('日期', draft.serviceDate ?? ''),
            _labelValue('語氣', draft.tone ?? ''),
            _section('備註', draft.customNote),
          ],
        ),
      ),
    );
  }

  static Future<Uint8List> _pdfBytes(pw.Page page) async {
    final doc = pw.Document();
    doc.addPage(page);
    return doc.save();
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label：', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _section(String title, String? body) {
    if (body == null || body.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: 12, bottom: 4),
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
