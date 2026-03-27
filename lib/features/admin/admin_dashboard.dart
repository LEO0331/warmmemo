import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/models/purchase.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/user_role_service.dart';
import 'order_detail_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Firestore rules currently check admin by doing cross-document exists+get on
  // `/users/{uid}`. In collectionGroup queries, that cost is paid per document,
  // so large page sizes can hit Firestore's cross-document access limits and
  // cause permission-denied even for real admins.
  static const int _pageSize = 4;

  final ScrollController _scrollController = ScrollController();
  String? _statusFilter;
  String? _planFilter;
  String? _paymentQuickFilter;
  String? _verifierQuickFilter;
  String _keyword = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _cursor;
  bool _batchUpdating = false;
  bool _loadingPage = false;
  bool _initializedForAdmin = false;
  bool _adminDocEnsured = false;
  bool _adminDocChecked = false;
  bool? _adminDocExists;
  String? _lastErrorCode;
  String? _lastErrorDetail;
  final List<Purchase> _allOrders = [];
  final Set<String> _selectedOrderIds = <String>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return const Center(child: CircularProgressIndicator());
    return StreamBuilder<String>(
      stream: UserRoleService.instance.roleStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data != 'admin') {
          return Center(
            child: Text(
              '此頁面僅限管理者閱覽，如欲申請請聯絡 WarmMemo 團隊。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        if (!_adminDocEnsured) {
          _adminDocEnsured = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final colorScheme = Theme.of(context).colorScheme;
            try {
              await UserRoleService.instance.ensureAdminDoc(uid);
              final exists = await UserRoleService.instance.adminDocExists(uid);
              if (!mounted) return;
              setState(() {
                _adminDocExists = exists;
                _adminDocChecked = true;
                _lastErrorCode = null;
                _lastErrorDetail = null;
              });
            } catch (error) {
              if (!mounted) return;
              setState(() {
                _adminDocChecked = true;
                _adminDocExists = false;
              });
              _captureError(error);
              AppFeedback.showWithMessenger(
                messenger,
                colorScheme: colorScheme,
                message: '建立管理員識別失敗：$error',
                tone: FeedbackTone.error,
              );
            }
            if (!mounted || _initializedForAdmin) return;
            if (_adminDocExists == false) return;
            _initializedForAdmin = true;
            _loadFirstPage();
          });
        }

        return _buildAdminBody(context, uid);
      },
    );
  }

  Widget _buildAdminBody(BuildContext context, String uid) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Admin 控制台',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final colorScheme = Theme.of(context).colorScheme;
                  await Clipboard.setData(ClipboardData(text: uid));
                  if (!mounted) return;
                  AppFeedback.showWithMessenger(
                    messenger,
                    colorScheme: colorScheme,
                    message: '已複製 UID：$uid',
                    tone: FeedbackTone.info,
                  );
                },
                child: const Text('複製 UID'),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final colorScheme = Theme.of(context).colorScheme;
                  try {
                    await FirebaseFirestore.instance
                        .collectionGroup('orders')
                        .orderBy(FieldPath.documentId)
                        .limit(1)
                        .get();
                    if (!mounted) return;
                    setState(() {
                      _lastErrorCode = null;
                      _lastErrorDetail = null;
                    });
                    AppFeedback.showWithMessenger(
                      messenger,
                      colorScheme: colorScheme,
                      message: '診斷成功：collectionGroup orders 可查詢',
                      tone: FeedbackTone.success,
                    );
                  } catch (error) {
                    if (!mounted) return;
                    _captureError(error);
                    AppFeedback.showWithMessenger(
                      messenger,
                      colorScheme: colorScheme,
                      message: '診斷失敗：$error',
                      tone: FeedbackTone.error,
                    );
                  }
                },
                child: const Text('診斷'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_adminDocChecked && _adminDocExists == false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '偵測不到 admins/$uid。請確認 Firestore 已建立管理員文件。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          if (_adminDocChecked && _adminDocExists == false) const SizedBox(height: 12),
          if (_lastErrorCode != null || _lastErrorDetail != null) ...[
            _buildErrorPanel(theme),
            const SizedBox(height: 12),
          ],
          Text('檢視用戶提交的方案訂單，並可針對單筆填寫禮儀公司資訊後完成案件。'),
          const SizedBox(height: 16),
          _buildMetricsPanel(),
          const SizedBox(height: 16),
          if (_loadingPage && _allOrders.isEmpty) ...[
            const SkeletonOrderList(count: 4),
            const SizedBox(height: 12),
          ],
          _buildOrdersOverview(),
          const SizedBox(height: 16),
          _buildOrdersWorkQueue(),
          const SizedBox(height: 12),
          if (_loadingPage)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )),
          if (!_loadingPage && _cursor != null)
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.expand_more),
                label: const Text('載入更多'),
                onPressed: _loadMore,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersOverview() {
    final planNames = _allOrders.map((o) => o.planName).toSet().toList()..sort();
    final statuses = _allOrders.map((o) => o.status).toSet().toList()..sort();
    final verifiers = _allOrders
        .map((o) => _latestVerifier(o))
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filtered = _applyFilters(_allOrders);
    return SectionCard(
      title: '方案訂單管理（檢視）',
      icon: Icons.assignment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '搜尋（方案 / userId / 公司 / 聯絡）',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  _fromDate == null
                      ? '起始日期'
                      : '起：${_fromDate!.toLocal().toString().split(' ').first}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: _fromDate ?? DateTime.now(),
                  );
                  if (picked != null) setState(() => _fromDate = picked);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _toDate == null
                      ? '結束日期'
                      : '迄：${_toDate!.toLocal().toString().split(' ').first}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: _toDate ?? DateTime.now(),
                  );
                  if (picked != null) setState(() => _toDate = picked);
                },
              ),
              TextButton(
                onPressed: () => setState(() {
                  _fromDate = null;
                  _toDate = null;
                }),
                child: const Text('清除日期'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('全部狀態'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              ...statuses.map((s) => ChoiceChip(
                    label: Text(s),
                    selected: _statusFilter == s,
                    onSelected: (_) => setState(() => _statusFilter = s),
                  )),
              ChoiceChip(
                label: const Text('全部方案'),
                selected: _planFilter == null,
                onSelected: (_) => setState(() => _planFilter = null),
              ),
              ...planNames.map((p) => ChoiceChip(
                    label: Text(p),
                    selected: _planFilter == p,
                    onSelected: (_) => setState(() => _planFilter = p),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('全部付款'),
                selected: _paymentQuickFilter == null,
                onSelected: (_) => setState(() => _paymentQuickFilter = null),
              ),
              ChoiceChip(
                label: const Text('paid'),
                selected: _paymentQuickFilter == 'paid',
                onSelected: (_) => setState(() => _paymentQuickFilter = 'paid'),
              ),
              ChoiceChip(
                label: const Text('checkout_created'),
                selected: _paymentQuickFilter == 'checkout_created',
                onSelected: (_) => setState(() => _paymentQuickFilter = 'checkout_created'),
              ),
              ChoiceChip(
                label: const Text('expired'),
                selected: _paymentQuickFilter == 'expired',
                onSelected: (_) => setState(() => _paymentQuickFilter = 'expired'),
              ),
              ChoiceChip(
                label: const Text('failed'),
                selected: _paymentQuickFilter == 'failed',
                onSelected: (_) => setState(() => _paymentQuickFilter = 'failed'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            '統計：已付款 ${_allOrders.where((o) => o.paymentStatus == 'paid').length} 筆 / 共 ${_allOrders.length} 筆',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('全部核對人'),
                selected: _verifierQuickFilter == null,
                onSelected: (_) => setState(() => _verifierQuickFilter = null),
              ),
              ...verifiers.map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: _verifierQuickFilter == v,
                  onSelected: (_) => setState(() => _verifierQuickFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const EmptyStateCard(
              title: '沒有符合條件的訂單',
              description: '你可以調整狀態、方案、付款與核對人篩選條件。',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            ...filtered.map(
              (o) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        o.planName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      SelectableText('狀態：${o.status}'),
                      SelectableText('付款：${o.paymentStatus ?? '-'}'),
                      SelectableText('金額：${o.priceLabel}'),
                      SelectableText('建立時間：${o.createdAt.toLocal().toString().split('.').first}'),
                      SelectableText('最近核對：${_latestVerificationSummary(o)}'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _copyVerificationSummary(o),
                            child: const Text('複製核對摘要'),
                          ),
                          if (o.checkoutUrl != null && o.checkoutUrl!.isNotEmpty)
                            OutlinedButton(
                              onPressed: () => _resendCheckoutLink(o),
                              child: const Text('重送付款連結'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersWorkQueue() {
    final filtered = _applyFilters(_allOrders);
    if (filtered.isEmpty) {
      return const SectionCard(
        title: '個別訂單處理',
        icon: Icons.task_outlined,
        child: EmptyStateCard(
          title: '目前沒有待處理訂單',
          description: '等待用戶送單後，這裡會顯示可處理項目。',
          icon: Icons.task_alt_outlined,
        ),
      );
    }
    final cards = filtered.map((o) {
      final selected = o.id != null && _selectedOrderIds.contains(o.id!);
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: o.id == null
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedOrderIds.add(o.id!);
                              } else {
                                _selectedOrderIds.remove(o.id!);
                              }
                            });
                          },
                  ),
                  const Text('批次勾選'),
                ],
              ),
              SelectableText(
                o.planName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText('狀態：${o.status}'),
              SelectableText('付款：${o.paymentStatus ?? '-'}'),
              SelectableText('用戶：${o.userId ?? '-'}'),
              SelectableText('最近核對：${_latestVerificationSummary(o)}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (o.checkoutUrl != null && o.checkoutUrl!.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => _resendCheckoutLink(o),
                      child: const Text('重送付款連結'),
                    ),
                  OutlinedButton(
                    onPressed: () => _copyVerificationSummary(o),
                    child: const Text('複製核對摘要'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<Purchase>(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(purchase: o),
                        ),
                      );
                      if (updated != null && updated.userId != null) {
                        await PurchaseService.instance.updateOrder(
                          uid: updated.userId!,
                          purchase: updated,
                        );
                        setState(() {
                          final idx = _allOrders.indexWhere((p) => p.id == updated.id);
                          if (idx != -1) _allOrders[idx] = updated;
                        });
                      }
                    },
                    child: const Text('編輯訂單'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();

    return SectionCard(
      title: '個別訂單處理',
      icon: Icons.task_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.select_all_outlined),
                  label: const Text('全選當前列表'),
                  onPressed: () {
                    setState(() {
                      _selectedOrderIds
                        ..clear()
                        ..addAll(filtered.map((e) => e.id).whereType<String>());
                    });
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.deselect_outlined),
                  label: const Text('清空勾選'),
                  onPressed: () => setState(_selectedOrderIds.clear),
                ),
                FilledButton(
                  onPressed: _batchUpdating ? null : () => _batchApply(caseStatus: 'received'),
                  child: const Text('批次標記 received'),
                ),
                FilledButton(
                  onPressed: _batchUpdating ? null : () => _batchApply(caseStatus: 'complete'),
                  child: const Text('批次標記 complete'),
                ),
                FilledButton(
                  onPressed: _batchUpdating ? null : () => _batchApply(paymentStatus: 'paid'),
                  child: const Text('批次標記 paid'),
                ),
              ],
            ),
          ),
          ...cards,
        ],
      ),
    );
  }

  List<Purchase> _applyFilters(List<Purchase> source) {
    return source.where((o) {
      final sOk = _statusFilter == null || o.status == _statusFilter;
      final pOk = _planFilter == null || o.planName == _planFilter;
      final payOk = _paymentQuickFilter == null || o.paymentStatus == _paymentQuickFilter;
      final verifier = _latestVerifier(o);
      final vOk = _verifierQuickFilter == null || verifier == _verifierQuickFilter;
      final keywordTarget = [
        o.planName,
        o.userId ?? '',
        o.companyName ?? '',
        o.contactNumber ?? '',
      ].join(' ').toLowerCase();
      final kOk = _keyword.isEmpty || keywordTarget.contains(_keyword);
      final fromOk = _fromDate == null ||
          !o.createdAt.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day));
      final toOk = _toDate == null ||
          !o.createdAt.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59));
      return sOk && pOk && payOk && vOk && kOk && fromOk && toOk;
    }).toList();
  }

  Widget _buildMetricsPanel() {
    final total = _allOrders.length;
    final pending = _allOrders.where((o) => o.status == 'pending').length;
    final received = _allOrders.where((o) => o.status == 'received').length;
    final complete = _allOrders.where((o) => o.status == 'complete').length;
    final paid = _allOrders.where((o) => o.paymentStatus == 'paid').length;
    final paidRate = total == 0 ? 0 : ((paid / total) * 100).round();
    final completed = _allOrders.where((o) => o.status == 'complete').toList();
    final avgHours = completed.isEmpty
        ? 0.0
        : completed
                .map((o) => (o.verifiedAt ?? o.createdAt).difference(o.createdAt).inMinutes / 60)
                .reduce((a, b) => a + b) /
            completed.length;

    return SectionCard(
      title: '營運指標',
      icon: Icons.insights_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _metricChip('總訂單', '$total'),
          _metricChip('待受理', '$pending'),
          _metricChip('處理中', '$received'),
          _metricChip('已完成', '$complete'),
          _metricChip('已付款', '$paid'),
          _metricChip('付款率', '$paidRate%'),
          _metricChip('平均結案時間', '${avgHours.toStringAsFixed(1)}h'),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _batchApply({String? caseStatus, String? paymentStatus}) async {
    final selected = _allOrders
        .where((o) => o.id != null && _selectedOrderIds.contains(o.id))
        .toList();
    if (selected.isEmpty) {
      AppFeedback.show(context, message: '請先勾選要批次更新的訂單', tone: FeedbackTone.info);
      return;
    }
    final confirmed = await _confirmBatchAction(
      selectedOrders: selected,
      caseStatus: caseStatus,
      paymentStatus: paymentStatus,
    );
    if (!confirmed) return;
    setState(() => _batchUpdating = true);
    try {
      final actor = AuthService.instance.currentUser?.email ?? AuthService.instance.currentUser?.uid;
      final report = await PurchaseService.instance.adminBatchUpdate(
        purchases: selected,
        caseStatus: caseStatus,
        paymentStatus: paymentStatus,
        actor: actor,
      );
      await _loadFirstPage();
      if (!mounted) return;
      setState(() {
        _selectedOrderIds.clear();
        _batchUpdating = false;
      });
      AppFeedback.show(
        context,
        message: '批次更新完成：成功 ${report.updatedCount} 筆，略過 ${report.skippedCount} 筆',
        tone: FeedbackTone.success,
      );
      await _showBatchResult(report);
    } catch (error) {
      if (!mounted) return;
      setState(() => _batchUpdating = false);
      _captureError(error);
      AppFeedback.show(context, message: '批次更新失敗：$error', tone: FeedbackTone.error);
    }
  }

  Future<bool> _confirmBatchAction({
    required List<Purchase> selectedOrders,
    String? caseStatus,
    String? paymentStatus,
  }) async {
    final target = <String>[];
    if (caseStatus != null) target.add('案件狀態 -> $caseStatus');
    if (paymentStatus != null) target.add('付款狀態 -> $paymentStatus');
    final preview = selectedOrders.take(5).toList();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認批次更新'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText('預計更新筆數：${selectedOrders.length}'),
            SelectableText('變更內容：${target.isEmpty ? '-' : target.join('，')}'),
            const SizedBox(height: 8),
            const Text('預覽前 5 筆：'),
            const SizedBox(height: 6),
            ...preview.map(
              (o) => SelectableText('• ${o.planName}｜${o.userId ?? '-'}｜${o.status}/${o.paymentStatus ?? '-'}'),
            ),
            if (selectedOrders.length > preview.length)
              SelectableText('... 另有 ${selectedOrders.length - preview.length} 筆'),
            const SizedBox(height: 8),
            const Text('送出後會寫入人工核對操作紀錄。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確認送出'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showBatchResult(BatchUpdateReport report) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('批次更新結果'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText('選取：${report.selectedCount} 筆'),
                SelectableText('成功：${report.updatedCount} 筆'),
                SelectableText('略過：${report.skippedCount} 筆'),
                if (report.skipped.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('略過原因：'),
                  const SizedBox(height: 6),
                  ...report.skipped.take(8).map(
                    (item) => SelectableText(
                      '• ${item.planName}｜${item.userId}｜${item.reason}',
                    ),
                  ),
                  if (report.skipped.length > 8)
                    SelectableText('... 另有 ${report.skipped.length - 8} 筆略過'),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  String _latestVerificationSummary(Purchase order) {
    if (order.verificationLogs.isEmpty) return '尚未人工核對';
    final latest = order.verificationLogs.last;
    final time = latest.actedAt.toLocal().toString().split('.').first;
    return '$time｜${latest.actor}';
  }

  Future<void> _resendCheckoutLink(Purchase order) async {
    final url = order.checkoutUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;
    AppFeedback.show(
      context,
      message: '已重送付款連結（已複製）',
      tone: FeedbackTone.success,
    );
  }

  Future<void> _loadFirstPage() async {
    setState(() => _loadingPage = true);
    try {
      final page = await PurchaseService.instance.adminOrdersPage(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _allOrders
          ..clear()
          ..addAll(page.items..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
        _cursor = page.cursor;
        _loadingPage = false;
      });
    } catch (error) {
      if (!mounted) return;
      _captureError(error);
      setState(() {
        _loadingPage = false;
        _cursor = null;
      });
      final currentUid = AuthService.instance.currentUser?.uid ?? '-';
      final message = error.toString().contains('permission-denied')
          ? '讀取訂單失敗：permission-denied。請確認 Firestore 有 `admins/$currentUid` 文件。'
          : '讀取訂單失敗：$error';
      AppFeedback.show(context, message: message, tone: FeedbackTone.error);
    }
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingPage) return;
    setState(() => _loadingPage = true);
    try {
      final page = await PurchaseService.instance.adminOrdersPage(
        limit: _pageSize,
        startAfterDocPath: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _allOrders
          ..addAll(page.items)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cursor = page.cursor;
        _loadingPage = false;
      });
    } catch (error) {
      if (!mounted) return;
      _captureError(error);
      setState(() => _loadingPage = false);
      final currentUid = AuthService.instance.currentUser?.uid ?? '-';
      final message = error.toString().contains('permission-denied')
          ? '載入更多失敗：permission-denied。請確認 Firestore 有 `admins/$currentUid` 文件。'
          : '載入更多失敗：$error';
      AppFeedback.show(
        context,
        message: message,
        tone: FeedbackTone.error,
        actionLabel: '重試',
        onAction: _loadMore,
      );
    }
  }

  String? _latestVerifier(Purchase order) {
    if (order.verificationLogs.isEmpty) return null;
    return order.verificationLogs.last.actor;
  }

  Future<void> _copyVerificationSummary(Purchase order) async {
    final latest = order.verificationLogs.isNotEmpty ? order.verificationLogs.last : null;
    final summary = StringBuffer()
      ..writeln('方案：${order.planName}')
      ..writeln('訂單狀態：${order.status}')
      ..writeln('付款狀態：${order.paymentStatus ?? '-'}')
      ..writeln('最近核對：${latest == null ? '尚未人工核對' : '${latest.actedAt.toLocal().toString().split('.').first}｜${latest.actor}'}');
    if (latest?.summary != null) {
      summary.writeln('核對摘要：${latest!.summary}');
    }
    if (latest?.note != null && latest!.note!.isNotEmpty) {
      summary.writeln('核對備註：${latest.note}');
    }
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (!mounted) return;
    AppFeedback.show(context, message: '核對摘要已複製', tone: FeedbackTone.success);
  }

  Widget _buildErrorPanel(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系統錯誤碼：${_lastErrorCode ?? 'unknown'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _humanReadableError(_lastErrorCode),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          if (_lastErrorDetail != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              _lastErrorDetail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _captureError(Object error) {
    final text = error.toString();
    final code = _extractErrorCode(text);
    setState(() {
      _lastErrorCode = code;
      _lastErrorDetail = text;
    });
  }

  String _extractErrorCode(String text) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(text);
    if (match == null) return 'unknown';
    final raw = match.group(1) ?? 'unknown';
    if (raw.contains('/')) return raw.split('/').last;
    return raw;
  }

  String _humanReadableError(String? code) {
    switch (code) {
      case 'permission-denied':
        return '權限不足，請確認目前帳號已在 admins 集合開通且 Firestore 規則已部署。';
      case 'failed-precondition':
        return '查詢前置條件不足，通常是索引或查詢條件不匹配。';
      case 'unavailable':
        return '服務暫時不可用，可能是網路或 Firebase 服務異常。';
      default:
        return '請將下方原始錯誤回報給技術團隊，以便快速定位。';
    }
  }
}
