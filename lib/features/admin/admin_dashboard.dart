import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';
import '../../data/models/purchase.dart';
import '../../data/services/export_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/user_role_service.dart';
import 'order_tile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _exporting = false;
  String? _selectedTone;
  String? _selectedChannel;
  String? _selectedStatus;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<String>(
      stream: UserRoleService.instance.roleStream(uid),
      builder: (context, snapshot) {
        final role = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (role != 'admin') {
          return Center(
            child: Text(
              '此頁面僅限管理者閱覽，如欲申請請聯絡 WarmMemo 團隊。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return _buildAdminBody(context);
      },
    );
  }

  Widget _buildAdminBody(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin 控制台',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '封裝平台指標與訂單追蹤，協助銷售團隊快速處理 pending / received / complete 的需求。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildMetricsSection(),
          const SizedBox(height: 16),
          _buildNotificationSection(),
          const SizedBox(height: 16),
          _buildOrdersSection(),
          const SizedBox(height: 16),
          _buildExportSection(),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return StreamBuilder<DraftMetrics>(
      stream: FirebaseDraftService.instance.adminMetricsStream(),
      builder: (context, snapshot) {
        final metrics = snapshot.data ??
            DraftMetrics(totalUsers: 0, totalReads: 0, totalClicks: 0);
        return SectionCard(
          title: '平台指標',
          icon: Icons.insights_outlined,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricColumn('活躍用戶', metrics.totalUsers.toString()),
                  _metricColumn('閱讀總數', metrics.totalReads.toString()),
                  _metricColumn('點擊總數', metrics.totalClicks.toString()),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<int>(
                stream: NotificationService.instance.pendingCount(),
                builder: (context, pendingSnapshot) {
                  final pending = pendingSnapshot.data ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text('待送達通知：$pending 筆'),
                        avatar: const Icon(Icons.timer_outlined, size: 18),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationSection() {
    return SectionCard(
      title: '通知趨勢與過濾',
      icon: Icons.campaign_outlined,
      child: StreamBuilder<List<NotificationEvent>>(
        stream: NotificationService.instance.timeline(limit: 80),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          final filtered = _filterEvents(events);
          final statusCounts = _countBy(events, (event) => event.status);
          final statuses = statusCounts.keys.toList()..sort();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrendCard(events),
              const SizedBox(height: 12),
              _buildFilterRow('語氣', _extractUnique(events, (event) => event.tone)),
              const SizedBox(height: 6),
              _buildFilterRow('渠道', _extractUnique(events, (event) => event.channel)),
              const SizedBox(height: 6),
              _buildFilterRow('狀態', statuses),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: statusCounts.entries
                    .map((entry) => Chip(label: Text('${entry.key}：${entry.value}')))
                    .toList(),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Text('目前沒有符合條件的通知事件。')
              else
                Column(
                  children: filtered
                      .take(6)
                      .map((event) => _buildEventTile(event))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  // 提醒推播與付款功能暫時移除，以避免干擾後台動線。

  Widget _buildExportSection() {
    return SectionCard(
      title: '合規匯出',
      icon: Icons.file_download_outlined,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: Text(_exporting ? '匯出中…' : '下載歷史與草稿'),
              onPressed: _exporting ? null : _exportCompliance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return SectionCard(
      title: '方案訂單管理',
      icon: Icons.assignment_turned_in_outlined,
      child: StreamBuilder<List<Purchase>>(
        stream: PurchaseService.instance.adminOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Text('目前沒有訂單。');
          return Column(
            children: orders
                .map(
                  (order) => OrderTile(
                    key: ValueKey(order.id ?? order.planName),
                    purchase: order,
                    onSave: (updated) {
                      if (updated.userId == null) return;
                      PurchaseService.instance
                          .updateOrder(uid: updated.userId!, purchase: updated);
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _exportCompliance() async {
    setState(() => _exporting = true);
    try {
      await ExportService.instance.exportCompliancePackage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已準備好合規匯出檔案。')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('匯出失敗：$error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _buildFilterRow(String label, List<String> options) {
    final value = _selectedValueForLabel(label);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: Text('$label · 全部'),
          selected: value == null,
          onSelected: (_) => _updateFilter(label, null),
        ),
        ...options.map((option) {
          final selected = option == value;
          return ChoiceChip(
            label: Text(option),
            selected: selected,
            onSelected: (_) => _updateFilter(label, selected ? null : option),
          );
        }),
      ],
    );
  }

  Widget _buildEventTile(NotificationEvent event) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: Text(event.draftType ?? '草稿'),
      subtitle: Text(
        '${event.channel} · ${event.status}'
        '${event.tone != null ? ' · ${event.tone}' : ''}',
      ),
      trailing: Text(
        event.occurredAt.toLocal().toString().split('.').first,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  List<String> _extractUnique(
    List<NotificationEvent> events,
    String? Function(NotificationEvent) extractor,
  ) {
    final values = events.map(extractor).whereType<String>().toSet().toList();
    values.sort();
    return values;
  }

  Widget _buildTrendCard(List<NotificationEvent> events) {
    final byDraft = <String, Map<String, int>>{};
    final toneCounts = <String, int>{};
    for (final event in events) {
      final draft = event.draftType ?? '草稿';
      final channel = event.channel;
      byDraft.putIfAbsent(draft, () => {})
          .update(channel, (value) => value + 1, ifAbsent: () => 1);
      if (event.tone != null) {
        toneCounts.update(event.tone!, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return SectionCard(
      title: 'Tone / Channel 趨勢',
      icon: Icons.trending_up,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toneCounts.isNotEmpty)
            Wrap(
              spacing: 12,
              children: toneCounts.entries
                  .map((entry) => Chip(label: Text('${entry.key}：${entry.value} 次')))
                  .toList(),
            ),
          const SizedBox(height: 8),
          ...byDraft.entries.map((entry) => Text(
                '【${entry.key}】${entry.value.entries.map((c) => '${c.key} ${c.value}').join(' • ')}',
              )),
        ],
      ),
    );
  }

  List<NotificationEvent> _filterEvents(List<NotificationEvent> events) {
    return events.where((event) {
      final toneOk = _selectedTone == null || event.tone == _selectedTone;
      final channelOk = _selectedChannel == null || event.channel == _selectedChannel;
      final statusOk = _selectedStatus == null || event.status == _selectedStatus;
      return toneOk && channelOk && statusOk;
    }).toList();
  }

  String? _selectedValueForLabel(String label) {
    switch (label) {
      case '語氣':
        return _selectedTone;
      case '渠道':
        return _selectedChannel;
      case '狀態':
        return _selectedStatus;
      default:
        return null;
    }
  }

  void _updateFilter(String label, String? value) {
    setState(() {
      switch (label) {
        case '語氣':
          _selectedTone = value;
          break;
        case '渠道':
          _selectedChannel = value;
          break;
        case '狀態':
          _selectedStatus = value;
          break;
      }
    });
  }

  Widget _metricColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Map<String, int> _countBy(
    List<NotificationEvent> events,
    String Function(NotificationEvent) extractor,
  ) {
    final counts = <String, int>{};
    for (final event in events) {
      final key = extractor(event);
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}
