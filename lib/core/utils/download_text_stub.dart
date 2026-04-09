import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadTextFile({
  required String content,
  required String filename,
}) async {
  final normalized = content.trimRight();
  if (normalized.isEmpty) {
    throw StateError('download-empty-content');
  }

  final safeFilename = _sanitizeFilename(filename);
  final bytes = Uint8List.fromList(utf8.encode(normalized));

  try {
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'text/markdown', name: safeFilename),
    ]);
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: normalized));
  }
}

String _sanitizeFilename(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'warmmemo_export.md';
  final safe = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  if (safe.endsWith('.md')) return safe;
  return '$safe.md';
}
