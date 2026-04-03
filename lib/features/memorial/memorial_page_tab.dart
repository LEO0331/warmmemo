import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/export/pdf_exporter.dart';
import '../../core/utils/download_bytes_stub.dart'
    if (dart.library.html) '../../core/utils/download_bytes_web.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/material_catalog.dart';
import '../../data/models/draft_models.dart';
import '../../data/models/purchase.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/token_wallet_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../features/memorial/controllers/proposal_controller.dart';

class MemorialPageTab extends StatefulWidget {
  const MemorialPageTab({super.key});

  @override
  State<MemorialPageTab> createState() => _MemorialPageTabState();
}

class _MemorialPageTabState extends State<MemorialPageTab> {
  final _formKey = GlobalKey<FormState>();
  final _previewKey = GlobalKey();
  final _qrKey = GlobalKey();

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _mottoController = TextEditingController();
  final _bioController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _willNoteController = TextEditingController();
  final _slugController = TextEditingController();
  final _proposalVendorController = TextEditingController();
  final _proposalScheduleController = TextEditingController();
  final _proposalNoteController = TextEditingController();

  bool _showPreview = false;
  bool _isPublished = false;
  bool _isCheckingSlug = false;
  bool _publishToggleBusy = false;
  bool _submittingProposal = false;
  String _slugStatus = '建立公開連結後，即可提供 碼掃描追思。';
  String? _publishedSlug;
  String? _proposalOrderId;
  String? _proposalMaterialCode;
  DraftStats? _stats;
  Timer? _slugCheckDebounce;
  late final ProposalController _proposalController;

  @override
  void initState() {
    super.initState();
    _proposalController = ProposalController();
    _loadDraft();
  }

  @override
  void dispose() {
    _slugCheckDebounce?.cancel();
    _nameController.dispose();
    _nicknameController.dispose();
    _mottoController.dispose();
    _bioController.dispose();
    _highlightsController.dispose();
    _willNoteController.dispose();
    _slugController.dispose();
    _proposalVendorController.dispose();
    _proposalScheduleController.dispose();
    _proposalNoteController.dispose();
    _proposalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = AuthService.instance.currentUser?.uid;

    return WarmBackdrop(
      child: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHero(
                  eyebrow: '追思紀念',
                  icon: Icons.person_outline,
                  title: '紀念頁 + QR 碼',
                  subtitle: '建立紀念頁、發布公開連結，並下載 QR 碼圖檔，方便用於墓碑、牌位或追思卡。',
                  badges: ['公開頁面', 'QR 碼', '下載 PNG'],
                ),
                const SizedBox(height: 12),
                if (_stats != null) _buildStatsCard(theme),
                if (_stats != null &&
                    AuthService.instance.currentUser?.uid != null) ...[
                  const SizedBox(height: 12),
                  _buildNotificationCard(AuthService.instance.currentUser!.uid),
                ],
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LabeledTextField(
                        label: '姓名',
                        controller: _nameController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? '請輸入姓名。'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      LabeledTextField(
                        label: '稱呼 / 暱稱',
                        controller: _nicknameController,
                      ),
                      const SizedBox(height: 8),
                      LabeledTextField(
                        label: '座右銘',
                        controller: _mottoController,
                      ),
                      const SizedBox(height: 8),
                      LabeledTextField(
                        label: '簡易自傳',
                        controller: _bioController,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 8),
                      LabeledTextField(
                        label: '人生重點',
                        controller: _highlightsController,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),
                      LabeledTextField(
                        label: '給家人的話',
                        controller: _willNoteController,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('預覽紀念頁'),
                          onPressed: _handlePreview,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (uid != null) _buildBusinessWorkspace(theme, uid),
                const SizedBox(height: 16),
                _buildQrSection(theme),
                const SizedBox(height: 24),
                if (_showPreview)
                  RepaintBoundary(
                    key: _previewKey,
                    child: _buildPreviewCard(theme),
                  ),
                if (_showPreview) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('匯出 PDF'),
                          onPressed: _exportMemorialPdf,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('匯出圖片'),
                          onPressed: _exportMemorialImage,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessWorkspace(ThemeData theme, String uid) {
    return SectionCard(
      title: '購買規劃小幫手',
      icon: Icons.business_center_outlined,
      child: StreamBuilder<List<Purchase>>(
        stream: OrderRepository.instance.watchOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return SelectableText('讀取訂單失敗：${snapshot.error}');
          }
          final orders = snapshot.data ?? const <Purchase>[];
          if (orders.isEmpty) {
            return const EmptyStateCard(
              title: '尚未有可推進訂單',
              description: '先到固定方案建立訂單，再回到這裡填寫偏好，我們會協助你更順利地往下一步前進。',
              icon: Icons.assignment_outlined,
            );
          }
          final selectableOrders = orders
              .where((order) => order.id != null && order.id!.isNotEmpty)
              .toList();
          if (selectableOrders.isEmpty) {
            return const EmptyStateCard(
              title: '訂單資料暫時不可用',
              description: '目前訂單資料尚未完整，暫時無法送出需求。請稍後重新整理，我們會在這裡等你。',
              icon: Icons.error_outline,
            );
          }
          final orderMap = {
            for (final order in selectableOrders) order.id ?? '': order,
          };
          final defaultOrder = _proposalOrderId != null
              ? orderMap[_proposalOrderId!]
              : selectableOrders.first;
          if (defaultOrder != null) {
            _syncProposalForm(defaultOrder);
          }
          final selectedOrder =
              (_proposalOrderId != null ? orderMap[_proposalOrderId!] : null) ??
              selectableOrders.first;
          final proposalHasInput = _hasProposalInput();
          final proposalUnchanged = _isProposalUnchanged(selectedOrder);
          final submitDisabled =
              _submittingProposal || !proposalHasInput || proposalUnchanged;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                '讓我們先了解你想要的墓碑/塔位方向與材質偏好，後續會更快幫你安排。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              SelectableText(
                '可先填寫款式想法、材質等級與期望時程，後續溝通會更省心。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedOrder.id,
                decoration: const InputDecoration(labelText: '選擇本次要規劃的訂單'),
                items: selectableOrders
                    .map(
                      (order) => DropdownMenuItem<String>(
                        value: order.id,
                        child: Text('${order.planName} (${order.status})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final nextOrder = orders.firstWhere(
                    (order) => order.id == value,
                  );
                  setState(() {
                    _proposalOrderId = value;
                    _proposalMaterialCode = _materialCodeFromOrder(nextOrder);
                    _proposalVendorController.text =
                        nextOrder.proposal?.vendorPreference ?? '';
                    _proposalScheduleController.text =
                        nextOrder.proposal?.schedulePreference ?? '';
                    _proposalNoteController.text =
                        nextOrder.proposal?.note ?? '';
                  });
                },
              ),
              const SizedBox(height: 8),
              SelectableText(
                '目前成交階段：${_conversionStep(selectedOrder)}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(
                '最近里程碑：${_latestMilestoneSummary(selectedOrder)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _proposalVendorController,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                decoration: const InputDecoration(labelText: '偏好的供應商（若有）'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _proposalMaterialCode,
                decoration: const InputDecoration(
                  labelText: '材質等級偏好（Basic / Standard / Premium）',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('未指定'),
                  ),
                  ...kMaterialOptionsV1.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.code,
                      child: Text(
                        '${item.label} (${item.tier})｜${item.priceBand}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _proposalMaterialCode = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _proposalScheduleController,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                decoration: const InputDecoration(labelText: '希望完成時間'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _proposalNoteController,
                inputFormatters: [LengthLimitingTextInputFormatter(240)],
                decoration: const InputDecoration(
                  labelText: '補充說明（預算/安裝條件/限制）',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: submitDisabled
                    ? null
                    : () =>
                          _submitOrderProposal(uid: uid, order: selectedOrder),
                icon: const Icon(Icons.send_outlined),
                label: Text(_submittingProposal ? '送出中...' : '送出商務提案'),
              ),
              const SizedBox(height: 6),
              Text(
                !proposalHasInput
                    ? '請至少填寫一項偏好再送出。'
                    : (proposalUnchanged
                          ? '目前內容與已送出提案相同。'
                          : '送出後我們會協助你進入報價、確認與安排流程。'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A6458),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncProposalForm(Purchase order) {
    if (_proposalOrderId == order.id) return;
    _proposalOrderId = order.id;
    _proposalMaterialCode = _materialCodeFromOrder(order);
    _proposalVendorController.text = order.proposal?.vendorPreference ?? '';
    _proposalScheduleController.text = order.proposal?.schedulePreference ?? '';
    _proposalNoteController.text = order.proposal?.note ?? '';
  }

  String? _materialCodeFromOrder(Purchase order) {
    final proposalMaterial = order.proposal?.materialChoice;
    if (proposalMaterial == null || proposalMaterial.trim().isEmpty) {
      return null;
    }
    final matched = kMaterialOptionsV1.where(
      (item) => item.label == proposalMaterial,
    );
    return matched.isEmpty ? null : matched.first.code;
  }

  String _conversionStep(Purchase order) {
    final proposalReady = order.proposal != null && !order.proposal!.isEmpty;
    final vendorReady =
        order.vendorAssignment != null && !order.vendorAssignment!.isEmpty;
    final materialReady =
        order.materialSelection != null && !order.materialSelection!.isEmpty;
    final scheduleReady = order.deliverySchedule.any(
      (item) => item.status == 'in_progress' || item.status == 'done',
    );
    if (!proposalReady) return '待提案';
    if (!vendorReady) return '待指派供應商';
    if (!materialReady) return '待確認材質';
    if (!scheduleReady) return '待建立排程';
    return '已進入製作';
  }

  String _latestMilestoneSummary(Purchase order) {
    if (order.deliverySchedule.isEmpty) return '尚未建立';
    final done = order.deliverySchedule.where((item) => item.status == 'done');
    if (done.isNotEmpty) {
      final latestDone = done.last;
      return '${latestDone.label}（done）';
    }
    final inProgress = order.deliverySchedule.where(
      (item) => item.status == 'in_progress',
    );
    if (inProgress.isNotEmpty) {
      final latest = inProgress.last;
      return '${latest.label}（in_progress）';
    }
    return '${order.deliverySchedule.first.label}（pending）';
  }

  Future<void> _submitOrderProposal({
    required String uid,
    required Purchase order,
  }) async {
    if (!_hasProposalInput()) {
      _showMessage('請至少填寫一項偏好。');
      return;
    }
    if (_isProposalUnchanged(order)) {
      _showMessage('提案內容未變更，已略過送出。');
      return;
    }
    setState(() => _submittingProposal = true);
    try {
      MaterialOption? material;
      if (_proposalMaterialCode != null) {
        final matched = kMaterialOptionsV1.where(
          (item) => item.code == _proposalMaterialCode,
        );
        if (matched.isNotEmpty) material = matched.first;
      }
      final updated = order.copyWith(
        proposal: OrderProposal(
          vendorPreference: _proposalVendorController.text.trim(),
          materialChoice: material?.label,
          schedulePreference: _proposalScheduleController.text.trim(),
          note: _proposalNoteController.text.trim(),
          submittedAt: DateTime.now(),
        ),
      );
      await _proposalController.submit(
        uid: uid,
        previous: order,
        next: updated,
      );
      _showMessage('提案已送出，Admin 會進一步審核與指派。');
    } catch (error) {
      _showMessage('提案送出失敗：$error');
    } finally {
      if (mounted) setState(() => _submittingProposal = false);
    }
  }

  bool _hasProposalInput() {
    return _proposalVendorController.text.trim().isNotEmpty ||
        _proposalMaterialCode != null ||
        _proposalScheduleController.text.trim().isNotEmpty ||
        _proposalNoteController.text.trim().isNotEmpty;
  }

  bool _isProposalUnchanged(Purchase order) {
    final old = order.proposal;
    String? selectedMaterial;
    if (_proposalMaterialCode != null) {
      final matched = kMaterialOptionsV1.where(
        (item) => item.code == _proposalMaterialCode,
      );
      if (matched.isNotEmpty) {
        selectedMaterial = matched.first.label;
      }
    }
    return (old?.vendorPreference ?? '').trim() ==
            _proposalVendorController.text.trim() &&
        (old?.materialChoice ?? '').trim() == (selectedMaterial ?? '').trim() &&
        (old?.schedulePreference ?? '').trim() ==
            _proposalScheduleController.text.trim() &&
        (old?.note ?? '').trim() == _proposalNoteController.text.trim();
  }

  Widget _buildStatsCard(ThemeData theme) {
    final stats = _stats!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn(theme, '瀏覽次數', stats.readCount),
            _statColumn(theme, '操作次數', stats.clickCount),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(String uid) {
    return StreamBuilder<List<NotificationEvent>>(
      stream: NotificationService.instance.streamForUser(uid),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <NotificationEvent>[];
        if (events.isEmpty) {
          return const SectionCard(
            title: '近期通知',
            icon: Icons.notifications_outlined,
            child: Text('目前沒有新的紀念頁通知。'),
          );
        }
        return SectionCard(
          title: '近期通知',
          icon: Icons.notifications_outlined,
          child: Column(
            children: List.generate(events.take(4).length, (index) {
              final event = events[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  event.status == 'read'
                      ? Icons.mark_email_read_outlined
                      : Icons.circle_outlined,
                  size: 20,
                ),
                title: Text(event.draftType ?? '紀念頁'),
                subtitle: Text('${event.channel} • ${event.status}'),
                trailing: Text(
                  event.occurredAt.toLocal().toString().split('.').first,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildQrSection(ThemeData theme) {
    final publicUrl = _effectivePublicUrl;
    final ready = _isPublished && publicUrl != null;

    return SectionCard(
      title: '公開紀念頁與 QR 碼',
      icon: Icons.qr_code_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _isPublished,
            title: const Text('發布公開紀念頁'),
            subtitle: const Text('發布後，訪客可透過掃描 QR 碼開啟唯讀紀念頁。'),
            onChanged: _publishToggleBusy
                ? null
                : (value) async {
                    setState(() {
                      _publishToggleBusy = true;
                      _isPublished = value;
                    });
                    if (value) {
                      await _publishPublicPage();
                    } else {
                      await _unpublishPublicPage();
                    }
                    if (!mounted) return;
                    setState(() => _publishToggleBusy = false);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            '公開網址代稱（Slug）',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _slugController,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(48),
            ],
            decoration: InputDecoration(
              hintText: 'jia-zu-ji-nian',
              suffixIcon: _isCheckingSlug
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _checkSlugAvailability,
                      icon: const Icon(Icons.verified_outlined),
                    ),
            ),
            onChanged: _handleSlugChanged,
          ),
          const SizedBox(height: 6),
          Text(_slugStatus, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(
            '公開網址',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            publicUrl ?? '尚未產生公開網址',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: publicUrl == null
                  ? const Color(0xFF8D6B5C)
                  : theme.colorScheme.primary,
            ),
          ),
          if (publicUrl != null) ...[
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8D7CC)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: publicUrl,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '掃碼進入追思頁',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_displayName, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _publishToggleBusy ? null : _publishPublicPage,
                icon: Icon(
                  _isPublished ? Icons.refresh_outlined : Icons.public_outlined,
                ),
                label: Text(_isPublished ? '更新公開頁' : '立即發布'),
              ),
              OutlinedButton.icon(
                onPressed: ready ? _copyPublicLink : null,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('複製連結'),
              ),
              OutlinedButton.icon(
                onPressed: ready ? _downloadQrPng : null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('下載 QR 碼PNG'),
              ),
              if (_isPublished)
                OutlinedButton.icon(
                  onPressed: _publishToggleBusy ? null : _unpublishPublicPage,
                  icon: const Icon(Icons.public_off_outlined),
                  label: const Text('取消發布'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Bullet('請保持高對比：深色 碼搭配淺色底。'),
          Bullet('實體印製需保留足夠尺寸，避免掃描失敗。'),
          Bullet('避免花紋、邊框或裝飾遮住 QR 碼區塊。'),
          Bullet('正式安裝前，先列印樣張實測。'),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '複製預覽文字',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: _copyPreviewText,
                ),
              ],
            ),
            if (_mottoController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${_mottoController.text.trim()}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_bioController.text.trim().isNotEmpty)
              _previewSection(theme, '簡易自傳', _bioController.text.trim()),
            if (_highlightsController.text.trim().isNotEmpty)
              _previewSection(theme, '人生重點', _highlightsController.text.trim()),
            if (_willNoteController.text.trim().isNotEmpty)
              _previewSection(theme, '給家人的話', _willNoteController.text.trim()),
            const Divider(),
            Text(
              _currentPublicUrl ?? '尚未產生公開網址',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _currentPublicUrl == null
                    ? const Color(0xFF8D6B5C)
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewSection(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(body),
        ],
      ),
    );
  }

  Widget _statColumn(ThemeData theme, String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String get _displayName {
    final nickname = _nicknameController.text.trim();
    if (nickname.isNotEmpty) return nickname;
    final name = _nameController.text.trim();
    return name.isEmpty ? '未命名紀念頁' : name;
  }

  String? get _currentPublicUrl {
    final slug = _effectiveSlug;
    if (slug.isEmpty) return null;
    final base = _publicBaseUrl;
    return '$base/#/m/$slug';
  }

  String get _effectiveSlug {
    final published = (_publishedSlug ?? '').trim();
    if (_isPublished && published.isNotEmpty) {
      return published;
    }
    return _slugController.text.trim();
  }

  String? get _effectivePublicUrl {
    final slug = _effectiveSlug;
    if (slug.isEmpty) return null;
    final base = _publicBaseUrl;
    return '$base/#/m/$slug';
  }

  String get _publicBaseUrl {
    const envBaseUrl = String.fromEnvironment('PUBLIC_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    final origin = Uri.base.origin;
    final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      return '$origin/${segments.first}';
    }
    return origin;
  }

  Future<void> _handlePreview() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _consumeTokenOrShowTopUp(
      AdvancedServiceType.memorialPreview,
    );
    if (!ok) return;
    await _saveDraft();
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      await UserProfileService.instance.markOnboardingStep(
        uid,
        UserProfileService.onboardingStepFirstDraft,
      );
    }
    if (!mounted) return;
    setState(() => _showPreview = true);
  }

  Future<void> _loadDraft() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final draft = await FirebaseDraftService.instance.loadMemorial(uid);
    await _refreshStats(uid);
    if (draft == null) {
      _ensureSlugIfNeeded();
      return;
    }

    setState(() {
      _nameController.text = draft.name ?? '';
      _nicknameController.text = draft.nickname ?? '';
      _mottoController.text = draft.motto ?? '';
      _bioController.text = draft.bio ?? '';
      _highlightsController.text = draft.highlights ?? '';
      _willNoteController.text = draft.willNote ?? '';
      _slugController.text = draft.slug ?? '';
      _isPublished = draft.isPublished ?? false;
      _publishedSlug = draft.isPublished == true ? draft.slug : null;
      if (draft.slug != null && draft.slug!.isNotEmpty) {
        _slugStatus = '目前代稱：${draft.slug}';
      }
    });

    if (_slugController.text.trim().isEmpty) {
      _ensureSlugIfNeeded();
    } else {
      await _checkSlugAvailability(silent: true);
    }
  }

  Future<void> _refreshStats(String uid) async {
    final stats = await FirebaseDraftService.instance.loadStats(uid);
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _saveDraft({
    bool? isPublished,
    DateTime? publicUpdatedAt,
  }) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    _ensureSlugIfNeeded();

    final draft = MemorialDraft(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      motto: _mottoController.text.trim(),
      bio: _bioController.text.trim(),
      highlights: _highlightsController.text.trim(),
      willNote: _willNoteController.text.trim(),
      slug: _slugController.text.trim(),
      isPublished: isPublished ?? _isPublished,
      qrEnabled: isPublished ?? _isPublished,
      publicUpdatedAt: publicUpdatedAt,
    );
    await FirebaseDraftService.instance.saveMemorial(uid, draft);
    await _refreshStats(uid);
  }

  Future<void> _publishPublicPage() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    _ensureSlugIfNeeded();
    final available = await _checkSlugAvailability();
    if (!available) return;

    final slug = _slugController.text.trim();
    final draft = MemorialDraft(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      motto: _mottoController.text.trim(),
      bio: _bioController.text.trim(),
      highlights: _highlightsController.text.trim(),
      willNote: _willNoteController.text.trim(),
      slug: slug,
      isPublished: true,
      qrEnabled: true,
      publicUpdatedAt: DateTime.now(),
    );

    try {
      if (_publishedSlug != null &&
          _publishedSlug != slug &&
          _publishedSlug!.trim().isNotEmpty) {
        await FirebaseDraftService.instance.unpublishMemorial(
          uid,
          _publishedSlug!,
        );
      }

      await FirebaseDraftService.instance.saveMemorial(uid, draft);
      await FirebaseDraftService.instance.publishMemorial(uid, draft);
      if (!mounted) return;
      setState(() {
        _isPublished = true;
        _publishedSlug = slug;
        _slugStatus = '公開紀念頁已上線。';
      });
      _showMessage('公開紀念頁已發布。');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPublished = false);
      _showMessage(_friendlyErrorMessage(error, fallback: '發布失敗，請稍後再試。'));
    }
  }

  Future<void> _unpublishPublicPage() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    final slug = (_publishedSlug ?? _slugController.text).trim();
    try {
      if (slug.isNotEmpty) {
        await FirebaseDraftService.instance.unpublishMemorial(uid, slug);
      }
      await _saveDraft(isPublished: false, publicUpdatedAt: DateTime.now());
      if (!mounted) return;
      setState(() {
        _isPublished = false;
        _publishedSlug = null;
        _slugStatus = '公開紀念頁已下架。';
      });
      _showMessage('公開紀念頁已取消發布。');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPublished = true);
      _showMessage(_friendlyErrorMessage(error, fallback: '取消發布失敗，請稍後再試。'));
    }
  }

  void _handleSlugChanged(String rawValue) {
    final sanitized = _sanitizeSlug(rawValue);
    if (sanitized != rawValue) {
      _slugController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    setState(() {
      _slugStatus = sanitized.isEmpty ? '請輸入網址代稱。' : '尚未檢查可用性。';
    });
    _slugCheckDebounce?.cancel();
    if (sanitized.isEmpty) return;
    _slugCheckDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _checkSlugAvailability(silent: true),
    );
  }

  Future<bool> _checkSlugAvailability({bool silent = false}) async {
    final uid = AuthService.instance.currentUser?.uid;
    final slug = _slugController.text.trim();
    if (uid == null || slug.isEmpty) return false;

    if (mounted) setState(() => _isCheckingSlug = true);
    final available = await FirebaseDraftService.instance
        .isMemorialSlugAvailable(slug, excludingUid: uid);
    if (!mounted) return available;
    setState(() {
      _isCheckingSlug = false;
      _slugStatus = available ? '此代稱可使用。' : '此代稱已被使用。';
    });
    if (!available && !silent) {
      _showMessage('此代稱已被使用。');
    }
    return available;
  }

  Future<void> _copyPublicLink() async {
    final url = _currentPublicUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseDraftService.instance.incrementStats(uid, clickDelta: 1);
    }
    _showMessage('已複製公開連結。');
  }

  Future<void> _downloadQrPng() async {
    final bytes = await _captureQrImage(url: _effectivePublicUrl);
    if (bytes == null) {
      _showMessage('目前無法產生 QR 碼圖片。');
      return;
    }
    final slug = _slugController.text.trim().isEmpty
        ? 'memorial-qr'
        : _slugController.text.trim();
    await downloadPngBytes(bytes: bytes, filename: 'warmmemo_$slug.png');
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseDraftService.instance.incrementStats(uid, clickDelta: 1);
    }
    _showMessage('QR 碼圖片已準備完成。');
  }

  Future<Uint8List?> _captureQrImage({String? url}) async {
    final data = url ?? _effectivePublicUrl;
    if (data == null || data.isEmpty) return null;

    try {
      await WidgetsBinding.instance.endOfFrame;
      final context = _qrKey.currentContext;
      final boundary = context?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          return bytes.buffer.asUint8List();
        }
      }
    } catch (_) {
      // Fall back to painter-based generation below.
    }

    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
    );
    final image = await painter.toImageData(
      1024,
      format: ui.ImageByteFormat.png,
    );
    return image?.buffer.asUint8List();
  }

  Future<void> _copyPreviewText() async {
    final lines = <String>[
      _displayName,
      if (_mottoController.text.trim().isNotEmpty) _mottoController.text.trim(),
      if (_bioController.text.trim().isNotEmpty) _bioController.text.trim(),
      if (_highlightsController.text.trim().isNotEmpty)
        _highlightsController.text.trim(),
      if (_willNoteController.text.trim().isNotEmpty)
        _willNoteController.text.trim(),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n\n')));
    _showMessage('已複製預覽文字。');
  }

  Future<void> _exportMemorialPdf() async {
    final ok = await _consumeTokenOrShowTopUp(
      AdvancedServiceType.memorialExportPdf,
    );
    if (!ok) return;
    try {
      await PdfExporter.exportMemorial(
        _currentMemorialDraft,
        publicUrl: _isPublished ? _currentPublicUrl : null,
      );
      _showMessage('PDF 匯出完成。');
    } catch (error) {
      _showMessage('PDF 匯出失敗： $error');
    }
  }

  Future<void> _exportMemorialImage() async {
    final ok = await _consumeTokenOrShowTopUp(
      AdvancedServiceType.memorialExportImage,
    );
    if (!ok) return;
    final bytes = await _capturePreviewImage();
    if (bytes == null) {
      _showMessage('目前無法匯出圖片。');
      return;
    }
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'warmmemo_memorial.png',
      ),
    ], text: 'WarmMemo 紀念頁');
    _showMessage('預覽圖片已匯出。');
  }

  Future<Uint8List?> _capturePreviewImage() async {
    final context = _previewKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  MemorialDraft get _currentMemorialDraft => MemorialDraft(
    name: _nameController.text.trim(),
    nickname: _nicknameController.text.trim(),
    motto: _mottoController.text.trim(),
    bio: _bioController.text.trim(),
    highlights: _highlightsController.text.trim(),
    willNote: _willNoteController.text.trim(),
    slug: _slugController.text.trim(),
    isPublished: _isPublished,
    qrEnabled: _isPublished,
    publicUpdatedAt: DateTime.now(),
  );

  Future<bool> _consumeTokenOrShowTopUp(AdvancedServiceType type) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      _showMessage('請先登入。');
      return false;
    }
    final result = await TokenWalletService.instance.consume(
      uid: uid,
      type: type,
    );
    if (result.ok) return true;
    final message = result.errorCode == 'insufficient-balance'
        ? '${result.message ?? '點數不足。'} 目前餘額：${result.balanceAfter}。'
        : (result.message ?? '點數扣除失敗，請稍後再試。');
    _showMessage(message);
    if (result.errorCode == 'insufficient-balance') {
      await _showTopUpRequestDialog(uid);
    }
    return false;
  }

  Future<void> _showTopUpRequestDialog(String uid) async {
    int selectedTokens = 10;
    final noteController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('申請點數'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('如需更多點數，可快速送出申請。'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: selectedTokens,
                decoration: const InputDecoration(labelText: '申請點數'),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedTokens = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '備註'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('送出'),
            ),
          ],
        ),
      ),
    );
    if (submit == true) {
      await UserProfileService.instance.submitTopUpRequest(
        uid: uid,
        requestedTokens: selectedTokens,
        note: noteController.text,
      );
      _showMessage('點數申請已送出。');
    }
    noteController.dispose();
  }

  void _ensureSlugIfNeeded() {
    if (_slugController.text.trim().isNotEmpty) return;
    final fallback = _slugify(_nameController.text.trim());
    final base = fallback.isEmpty ? 'memorial' : fallback;
    final raw = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = raw.length > 5 ? raw.substring(raw.length - 5) : raw;
    _slugController.text = '$base-$suffix';
  }

  String _sanitizeSlug(String input) {
    final slug = _slugify(input);
    return slug.length > 48 ? slug.substring(0, 48) : slug;
  }

  String _slugify(String value) {
    var slug = value.toLowerCase().trim();
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    slug = slug.replaceAll(RegExp(r'^-+'), '');
    slug = slug.replaceAll(RegExp(r'-+$'), '');
    return slug;
  }

  String _friendlyErrorMessage(Object error, {required String fallback}) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return '權限不足，請部署新版 Firestore 規則後再重試。';
      }
      return error.message ?? fallback;
    }
    return fallback;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
