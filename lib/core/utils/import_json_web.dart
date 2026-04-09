// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickJsonTextFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json'
    ..multiple = false;

  final completer = Completer<String?>();

  input.onChange.listen((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(reader.result as String?);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('json-file-read-failed'));
      }
    });
    reader.readAsText(file);
  });

  input.click();
  return completer.future.timeout(
    const Duration(seconds: 30),
    onTimeout: () => null,
  );
}
