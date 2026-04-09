import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> downloadTextFile({
  required String content,
  required String filename,
}) {
  final bytes = Uint8List.fromList(utf8.encode(content));
  return Share.shareXFiles([
    XFile.fromData(bytes, mimeType: 'text/markdown', name: filename),
  ]);
}
