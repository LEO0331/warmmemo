import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> downloadPngBytes({
  required Uint8List bytes,
  required String filename,
}) {
  return Share.shareXFiles([
    XFile.fromData(
      bytes,
      mimeType: 'image/png',
      name: filename,
    ),
  ]);
}
