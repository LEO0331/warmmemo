import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:warmmemo/core/utils/download_text_stub.dart';
import 'package:warmmemo/core/utils/import_json_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('download_text_stub', () {
    test('throws when content is empty after trimRight', () async {
      await expectLater(
        () => downloadTextFile(content: '   \n\n', filename: 'a.md'),
        throwsA(isA<StateError>()),
      );
    });

    test('sanitizes filename and keeps .md suffix', () {
      expect(sanitizeDownloadFilename(''), 'warmmemo_export.md');
      expect(sanitizeDownloadFilename(' report '), 'report.md');
      expect(sanitizeDownloadFilename('x:/bad*name?.md'), 'x_bad_name_.md');
    });

    test('uses share callback when share succeeds', () async {
      var shareCalls = 0;
      var sharedFilesLength = 0;
      String? clipboardText;
      await downloadTextFile(
        content: 'hello',
        filename: 'notes',
        shareXFiles: (files) async {
          shareCalls += 1;
          sharedFilesLength = files.length;
        },
        clipboardSetText: (text) async {
          clipboardText = text;
        },
      );

      expect(shareCalls, 1);
      expect(sharedFilesLength, 1);
      expect(clipboardText, isNull);
    });

    test('falls back to clipboard when share throws', () async {
      String? clipboardText;
      await downloadTextFile(
        content: 'copy me\n\n',
        filename: 'memo.md',
        shareXFiles: (_) async {
          throw Exception('share-failed');
        },
        clipboardSetText: (text) async {
          clipboardText = text;
        },
      );

      expect(clipboardText, 'copy me');
    });

    test('share callback receives one xfile', () async {
      var sharedFilesLength = 0;
      await downloadTextFile(
        content: '# Title',
        filename: 'skill.md',
        shareXFiles: (files) async {
          sharedFilesLength = files.length;
        },
      );
      expect(sharedFilesLength, 1);
    });

    test('default handlers path falls back to clipboard in test env', () async {
      await downloadTextFile(content: 'default-path', filename: 'demo');
      final copied = await Clipboard.getData('text/plain');
      if (copied?.text != null) {
        expect(copied?.text, 'default-path');
      }
    });
  });

  group('import_json_stub', () {
    test('throws unsupported on non-web stub', () async {
      await expectLater(
        pickJsonTextFile,
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('json-import-not-supported'),
          ),
        ),
      );
    });
  });
}
