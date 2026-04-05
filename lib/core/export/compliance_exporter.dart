import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/admin_models.dart';
import '../../data/models/draft_models.dart';

class ComplianceExporter {
  ComplianceExporter._();

  static Future<void> exportHistoryWithDrafts(
    List<NotificationEvent> events,
    DraftMetrics metrics,
    List<UserComplianceSnapshot> bundles,
  ) async {
    final pdf = await _buildPdf(events, metrics);
    final csv = _buildCsv(events, metrics);
    final bundlePdf = await _buildDraftPdf(bundles);
    final bundleCsv = _buildDraftCsv(bundles);

    await Share.shareXFiles(
      [
        XFile.fromData(csv, mimeType: 'text/csv', name: 'history.csv'),
        XFile.fromData(pdf, mimeType: 'application/pdf', name: 'history.pdf'),
        XFile.fromData(bundleCsv, mimeType: 'text/csv', name: 'compliance-drafts.csv'),
        XFile.fromData(bundlePdf, mimeType: 'application/pdf', name: 'compliance-drafts.pdf'),
      ],
      text: 'WarmMemo 歷史與合規紀錄',
    );
  }

  static Future<void> exportHistory(
      List<NotificationEvent> events, DraftMetrics metrics) async {
    final pdf = await _buildPdf(events, metrics);
    final csv = _buildCsv(events, metrics);

    await Share.shareXFiles(
      [
        XFile.fromData(csv, mimeType: 'text/csv', name: 'warmmemo_history.csv'),
        XFile.fromData(pdf, mimeType: 'application/pdf', name: 'warmmemo_history.pdf'),
      ],
      text: 'WarmMemo 歷史紀錄',
    );
  }

  static Future<Uint8List> _buildPdf(List<NotificationEvent> events, DraftMetrics metrics) async {
    final doc = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/NotoSansTC-VariableFont_wght.ttf");
    final myFont = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontData);
    doc.addPage(pw.Page(
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
            pw.Text('WarmMemo 歷史紀錄', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text('活躍用戶：${metrics.totalUsers}'),
            pw.Text('總閱讀：${metrics.totalReads}'),
            pw.Text('總點擊：${metrics.totalClicks}'),
            pw.SizedBox(height: 16),
            pw.Text('通知事件（最新 ${events.length} 筆）', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Column(
              children: events.map((event) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(event.userId)),
                      pw.Text(event.channel),
                      pw.Text(event.status),
                      pw.Text(event.occurredAt.toIso8601String()),
                    ],
                  )).toList(),
            ),
          ],
        ),
      ),
    ));
    return doc.save();
  }

  static Uint8List _buildCsv(List<NotificationEvent> events, DraftMetrics metrics) {
    final buffer = StringBuffer();
    buffer.writeln('WarmMemo 歷史紀錄');
    buffer.writeln('活躍用戶,${metrics.totalUsers}');
    buffer.writeln('總閱讀,${metrics.totalReads}');
    buffer.writeln('總點擊,${metrics.totalClicks}');
    buffer.writeln();
    buffer.writeln('userId,channel,status,tone,draftType,occurredAt');
    for (final event in events) {
      buffer.writeln(
          '${_escape(event.userId)},${_escape(event.channel)},${_escape(event.status)},${_escape(event.tone ?? '')},${_escape(event.draftType ?? '')},${event.occurredAt.toIso8601String()}');
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static String _escape(String value) => value.replaceAll(',', '，');

  static Future<Uint8List> _buildDraftPdf(List<UserComplianceSnapshot> bundles) async {
    final doc = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/NotoSansTC-VariableFont_wght.ttf");
    final myFont = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontData);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: myFont,
        bold: fontBold
      ),
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return [
          pw.Text('WarmMemo 合規草稿快照', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          ...bundles.map((bundle) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('User · ${bundle.userId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (bundle.memorialDraft != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('Memorial：${bundle.memorialDraft?.name ?? '—'}'),
                  ),
                if (bundle.obituaryDraft != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text('Obituary：${bundle.obituaryDraft?.deceasedName ?? '—'}'),
                  ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    '閱讀：${bundle.stats.readCount} / 點擊：${bundle.stats.clickCount}'
                    '${bundle.lastReminderAt != null ? ' / 最後提醒：${bundle.lastReminderAt!.toIso8601String()}' : ''}',
                  ),
                ),
                pw.Divider(),
              ],
            );
          }),
        ];
      },
    ));
    return doc.save();
  }

  static Uint8List _buildDraftCsv(List<UserComplianceSnapshot> bundles) {
    final buffer = StringBuffer();
    buffer.writeln('userId,memorialName,obituaryName,readCount,clickCount,lastReminderAt');
    for (final bundle in bundles) {
      buffer.writeln(
        '${_escape(bundle.userId)},'
        '${_escape(bundle.memorialDraft?.name ?? '')},'
        '${_escape(bundle.obituaryDraft?.deceasedName ?? '')},'
        '${bundle.stats.readCount},'
        '${bundle.stats.clickCount},'
        '${bundle.lastReminderAt?.toIso8601String() ?? ''}',
      );
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }
}
