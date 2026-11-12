import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:warmmemo/core/export/pdf_exporter.dart';
import 'package:warmmemo/data/models/draft_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Flutter bundles the licensed subset and uncommon-character font',
    () async {
      Future<TtfParser> parse(String file) async =>
          TtfParser(await rootBundle.load('assets/fonts/$file'));

      final subset = await parse('NotoSansTC-Subset.ttf');
      final bold = await parse('NotoSansTC-Bold-Subset.ttf');
      final full = await parse('NotoSansTC-Regular.ttf');
      expect(
        subset.bytes.lengthInBytes,
        lessThan(full.bytes.lengthInBytes ~/ 20),
      );
      for (final codePoint in '陳美玲，John 2026。'.runes) {
        expect(subset.charToGlyphIndexMap[codePoint], greaterThan(0));
      }
      expect(bold.charToGlyphIndexMap['紀'.runes.single], greaterThan(0));
      expect(subset.charToGlyphIndexMap['龘'.runes.single], isNull);
      expect(full.charToGlyphIndexMap['龘'.runes.single], greaterThan(0));
    },
  );

  test(
    'memorial embeds subset glyphs and draws its public-link QR offline',
    () async {
      final draft = MemorialDraft(name: '陳美玲', bio: 'John 2026。', motto: '，');
      final linked = await _withoutHttp(
        () => PdfExporter.memorialBytes(
          draft,
          publicUrl: 'https://example.test/#/m/offline-fixture',
        ),
      );
      final private = await _withoutHttp(
        () => PdfExporter.memorialBytes(draft),
      );
      final pdf = _PdfEvidence(linked);
      expect(
        pdf.fontNames,
        containsAll(['WarmMemoPDF-RegularSubset', 'WarmMemoPDF-BoldSubset']),
      );
      expect(pdf.fontNames, isNot(contains('WarmMemoPDF-Regular')));
      pdf.expectInk('紀陳美玲，John2026。');
      expect(pdf.rectangles, greaterThan(100));
      expect(_PdfEvidence(private).rectangles, isZero);
    },
  );

  test(
    'obituary embeds uncommon Traditional Chinese and mixed text offline',
    () async {
      final bytes = await _withoutHttp(
        () => PdfExporter.obituaryBytes(
          ObituaryDraft(
            deceasedName: '王小明龘',
            serviceDate: '2026-11-12',
            customNote: 'Mary 2026。',
          ),
        ),
      );
      final pdf = _PdfEvidence(bytes);
      expect(pdf.fontNames, contains('WarmMemoPDF-Regular'));
      pdf.expectInk('訃王小明龘Mary2026。');
      expect(pdf.rectangles, isZero);
    },
  );

  test(
    'shared source outlines render both punctuation characters correctly',
    () async {
      final bytes = await _withoutHttp(
        () => PdfExporter.obituaryBytes(ObituaryDraft(deceasedName: '·・龘')),
      );
      final outlines = _PdfEvidence(bytes).embeddedOutlines();
      final firstDot = outlines[0x00b7];
      expect(firstDot, isNotEmpty);
      expect(outlines[0x30fb], orderedEquals(firstDot!));
      expect(outlines[0x9f98], isNot(orderedEquals(firstDot)));
    },
  );

  test(
    'reports unsupported glyphs instead of producing a missing-glyph box',
    () async {
      await expectLater(
        _withoutHttp(
          () => PdfExporter.obituaryBytes(ObituaryDraft(deceasedName: '🍰')),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'unsupported Unicode code point',
            contains('U+1F370'),
          ),
        ),
      );
    },
  );
}

Future<Uint8List> _withoutHttp(Future<Uint8List> Function() generate) async {
  var attemptedClients = 0;
  try {
    return await HttpOverrides.runZoned(
      generate,
      createHttpClient: (_) {
        attemptedClients++;
        throw StateError('Network disabled for PDF generation');
      },
    );
  } finally {
    expect(attemptedClients, isZero);
  }
}

// Inspect the simple indirect objects emitted by the Dart PDF writer. Check
// each ToUnicode mapping against the matching embedded font's glyph outline.
class _PdfEvidence {
  _PdfEvidence(Uint8List bytes) : _source = latin1.decode(bytes) {
    expect(_source, startsWith('%PDF-'));
    expect(bytes.length, inInclusiveRange(2000, 120000));
    final objects = RegExp(r'(?:^|\n)(\d+) 0 obj\s').allMatches(_source);
    for (final object in objects) {
      final start = object.end;
      final end = _source.indexOf('endobj', start);
      final body = _source.substring(start, end);
      final stream = body.indexOf('stream\n');
      final dictionary = stream < 0 ? body : body.substring(0, stream);
      List<int>? content;
      if (stream >= 0) {
        final length = int.parse(
          RegExp(r'/Length\s+(\d+)').firstMatch(dictionary)![1]!,
        );
        final offset = start + stream + 'stream\n'.length;
        content = bytes.sublist(offset, offset + length);
        if (dictionary.contains('/FlateDecode')) content = zlib.decode(content);
      }
      _objects[int.parse(object[1]!)] = (dictionary, content);
    }
  }

  final String _source;
  final _objects = <int, (String, List<int>?)>{};

  Set<String> get fontNames => RegExp(
    r'/BaseFont\s*/([^\s/>]+)',
  ).allMatches(_source).map((match) => match[1]!).toSet();

  int get rectangles {
    final pageContents = _objects.values
        .map((entry) => _ref(entry.$1, 'Contents'))
        .whereType<int>();
    return pageContents
        .map(
          (id) => RegExp(
            r'\bre\b',
          ).allMatches(latin1.decode(_objects[id]!.$2!)).length,
        )
        .fold(0, (total, count) => total + count);
  }

  Map<int, Uint8List> embeddedOutlines() {
    final outlines = <int, Uint8List>{};
    for (final (dictionary, _) in _objects.values) {
      final unicode = _ref(dictionary, 'ToUnicode');
      if (unicode == null) continue;
      final descriptor = _ref(dictionary, 'FontDescriptor')!;
      final fontFile = _ref(_objects[descriptor]!.$1, 'FontFile2')!;
      final font = TtfParser(
        ByteData.sublistView(Uint8List.fromList(_objects[fontFile]!.$2!)),
      );
      final mapping = latin1.decode(_objects[unicode]!.$2!);
      final entries = RegExp(
        r'^<([0-9A-F]{4})> <([0-9A-F]{4})>$',
        multiLine: true,
      );
      for (final match in entries.allMatches(mapping)) {
        final glyph = int.parse(match[1]!, radix: 16);
        final codePoint = int.parse(match[2]!, radix: 16);
        if (glyph == 0) continue;
        final outline = font.readGlyph(glyph).data;
        if (outline.isNotEmpty) outlines[codePoint] = outline;
      }
    }
    return outlines;
  }

  void expectInk(String expected) {
    final glyphsWithInk = embeddedOutlines().keys;
    for (final codePoint in expected.runes) {
      expect(
        glyphsWithInk,
        contains(codePoint),
        reason:
            'Missing embedded outline for ${String.fromCharCode(codePoint)}',
      );
    }
  }

  int? _ref(String dictionary, String key) {
    final match = RegExp('/$key\\s*\\[?\\s*(\\d+) 0 R').firstMatch(dictionary);
    return match == null ? null : int.parse(match[1]!);
  }
}
