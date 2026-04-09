import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

typedef ShareXFilesFn = Future<void> Function(List<XFile> files);
typedef ClipboardSetTextFn = Future<void> Function(String text);

Future<void> downloadTextFile({
  required String content,
  required String filename,
  ShareXFilesFn? shareXFiles,
  ClipboardSetTextFn? clipboardSetText,
}) async {
  final normalized = content.trimRight();
  if (normalized.isEmpty) {
    throw StateError('download-empty-content');
  }

  final safeFilename = _sanitizeFilename(filename);
  final bytes = Uint8List.fromList(utf8.encode(normalized));
  final share =
      shareXFiles ??
      (List<XFile> files) {
        return Share.shareXFiles(files);
      };
  final setClipboard =
      clipboardSetText ??
      (String text) {
        return Clipboard.setData(ClipboardData(text: text));
      };

  try {
    await share([
      XFile.fromData(bytes, mimeType: 'text/markdown', name: safeFilename),
    ]);
  } catch (_) {
    await setClipboard(normalized);
  }
}

@visibleForTesting
String sanitizeDownloadFilename(String raw) => _sanitizeFilename(raw);

String _sanitizeFilename(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'warmmemo_export.md';
  final safe = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  if (safe.endsWith('.md')) return safe;
  return '$safe.md';
}
