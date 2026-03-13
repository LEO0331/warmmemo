import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';
import '../../data/models/purchase.dart';
import '../../data/services/export_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/reminder_service.dart';
import '../../data/services/user_role_service.dart';
import 'order_tile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _invoiceEmailController = TextEditingController();
  final _invoiceNameController = TextEditingController();
  final _invoiceAmountController = TextEditingController(text: '120000');
  final _invoiceDescriptionController = TextEditingController(text: 'WarmMemo 專案費用');
  PaymentProvider _selectedProvider = PaymentProvider.stripe;
  String? _invoiceLink;
  bool _creatingInvoice = false;
  bool _exporting = false;
  bool _sendingReminder = false;
  String? _reminderMessage;
  String? _selectedTone;
  String? _selectedChannel;
  String? _selectedStatus;
  String _selectedReminderChannel = 'email';

  @override
  void dispose() {
    _invoiceEmailController.dispose();
    _invoiceNameController.dispose();
    _invoiceAmountController.dispose();
    _invoiceDescriptionController.dispose();
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
            '封裝平台指標、通知追蹤與提醒推播，協助銷售團隊快速找到還在等待通知的用戶。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildMetricsSection(),
          const SizedBox(height: 16),
          _buildNotificationSection(),
          const SizedBox(height: 16),
          _buildReminderSection(),
          const SizedBox(height: 16),
          _buildPaymentSection(),
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

  Widget _buildReminderSection() {
    return SectionCard(
      title: '提醒推播',
      icon: Icons.notifications_active_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<int>(
            stream: NotificationService.instance.pendingCount(),
            builder: (context, snapshot) {
              final pending = snapshot.data ?? 0;
              return Text('目前有 $pending 筆通知仍維持 pending，可以再推提醒。');
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['email', 'line', 'sms']
                .map((channel) => ChoiceChip(
                      label: Text(channel.toUpperCase()),
                      selected: _selectedReminderChannel == channel,
                      onSelected: (_) {
                        setState(() => _selectedReminderChannel = channel);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(_sendingReminder ? '推播中…' : '提醒待處理用戶'),
                  onPressed: _sendingReminder ? null : _sendReminder,
                ),
              ),
            ],
          ),
          if (_reminderMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _reminderMessage!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return SectionCard(
      title: '付款與發票 (Stripe / 綠界)',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _invoiceEmailController,
            decoration: const InputDecoration(labelText: '帳單 Email'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _invoiceNameController,
            decoration: const InputDecoration(labelText: '姓名／公司'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _invoiceAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '金額 (NTD)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PaymentProvider>(
                  initialValue: _selectedProvider,
                  decoration: const InputDecoration(labelText: '供應商'),
                  items: PaymentProvider.values
                      .map((provider) => DropdownMenuItem(
                            value: provider,
                            child: Text(provider.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProvider = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _invoiceDescriptionController,
            decoration: const InputDecoration(labelText: '描述'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.payment_outlined),
              label: Text(_creatingInvoice ? '建立中…' : '建立發票'),
              onPressed: _creatingInvoice ? null : _createInvoice,
            ),
          ),
          if (_invoiceLink != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(
                '發票連結：$_invoiceLink',
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }

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

  Future<void> _createInvoice() async {
    final email = _invoiceEmailController.text.trim();
    final name = _invoiceNameController.text.trim();
    final amount = double.tryParse(_invoiceAmountController.text.trim()) ?? 0;
    final description = _invoiceDescriptionController.text.trim();
    if (email.isEmpty || name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫 Email、姓名與金額。')),
      );
      return;
    }

    setState(() {
      _creatingInvoice = true;
      _invoiceLink = null;
    });

    try {
      final result = await PaymentService.instance.createInvoice(
        email: email,
        name: name,
        amountCents: (amount * 100).round(),
        description: description.isEmpty ? 'WarmMemo 服務' : description,
        provider: _selectedProvider,
        currency: 'twd',
      );
      if (!mounted) return;
      setState(() => _invoiceLink = result.checkoutUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('發票已建立：${result.invoiceId}')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建立發票失敗：$error')),
      );
    } finally {
      if (mounted) setState(() => _creatingInvoice = false);
    }
  }

  Future<void> _sendReminder() async {
    setState(() {
      _sendingReminder = true;
      _reminderMessage = null;
    });
    try {
      final result = await ReminderService.instance.pushReminders(
        channel: _selectedReminderChannel,
      );
      if (!mounted) return;
      setState(() {
        if (result.users.isEmpty) {
          _reminderMessage = '目前沒有等待提醒的用戶。';
        } else {
          _reminderMessage =
              '已向 ${result.users.length} 位用戶發送 ${result.channel.toUpperCase()} 提醒。';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _reminderMessage = '提醒失敗：$error');
    } finally {
      if (mounted) setState(() => _sendingReminder = false);
    }
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
