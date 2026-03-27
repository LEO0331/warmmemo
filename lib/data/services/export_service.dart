import '../../core/export/compliance_exporter.dart';
import '../firebase/draft_service.dart';
import 'notification_service.dart';

class ExportService {
  ExportService({
    FirebaseDraftService? draftService,
    NotificationService? notificationService,
  })  : _draftService = draftService ?? FirebaseDraftService.instance,
        _notificationService = notificationService ?? NotificationService.instance;

  static final ExportService instance = ExportService();

  final FirebaseDraftService _draftService;
  final NotificationService _notificationService;

  Future<void> exportCompliancePackage() async {
    final history = await _notificationService.fetchHistory(limit: 500);
    final metrics = await _draftService.adminMetricsStream().first;
    final bundles = await _draftService.fetchUserSummaries(limit: 120);
    await ComplianceExporter.exportHistoryWithDrafts(history, metrics, bundles);
  }
}
