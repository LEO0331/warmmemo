import '../../core/export/compliance_exporter.dart';
import '../firebase/draft_service.dart';
import 'notification_service.dart';

class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  final FirebaseDraftService _draftService = FirebaseDraftService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  Future<void> exportCompliancePackage() async {
    final history = await _notificationService.fetchHistory(limit: 500);
    final metrics = await _draftService.adminMetricsStream().first;
    final bundles = await _draftService.fetchUserSummaries(limit: 120);
    await ComplianceExporter.exportHistoryWithDrafts(history, metrics, bundles);
  }
}
