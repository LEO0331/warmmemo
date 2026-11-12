// Release-mode browser fixture for tools/verify_pdf_web.cjs.
import 'package:flutter/material.dart';
import 'package:warmmemo/core/export/pdf_exporter.dart';
import 'package:warmmemo/data/models/draft_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(const MaterialApp(home: _PdfSmoke()));
}

class _PdfSmoke extends StatefulWidget {
  const _PdfSmoke();

  @override
  State<_PdfSmoke> createState() => _PdfSmokeState();
}

class _PdfSmokeState extends State<_PdfSmoke> {
  String _status = 'Ready';

  Future<void> _export(Future<void> Function() generate) async {
    setState(() => _status = 'Generating');
    try {
      await generate();
      if (mounted) setState(() => _status = 'Exported');
    } catch (error) {
      if (mounted) setState(() => _status = 'Export error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _export(
                () => PdfExporter.exportMemorial(
                  MemorialDraft(name: '陳美玲', bio: '，John 2026。'),
                  publicUrl: 'https://example.test/#/m/offline-fixture',
                ),
              ),
              child: const Text('Export memorial'),
            ),
            FilledButton(
              onPressed: () => _export(
                () => PdfExporter.exportObituary(
                  ObituaryDraft(
                    deceasedName: '王小明龘𠱓',
                    serviceDate: '2026-11-12',
                    customNote: '·・龘，Mary 2026。',
                  ),
                ),
              ),
              child: const Text('Export obituary'),
            ),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
