import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _selectedTone;
  String? _selectedChannel;
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin 控制台',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          StreamBuilder<DraftMetrics>(
            stream: FirebaseDraftService.instance.adminMetricsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final metrics = snapshot.data ??
                  DraftMetrics(totalUsers: 0, totalReads: 0, totalClicks: 0);
              return SectionCard(
                title: '平台指標',
                icon: Icons.insights_outlined,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricColumn('活躍用戶', metrics.totalUsers.toString()),
                    _metricColumn('總閱讀', metrics.totalReads.toString()),
                    _metricColumn('總點擊', metrics.totalClicks.toString()),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '通知追蹤',
            icon: Icons.notifications_outlined,
            child: StreamBuilder<List<NotificationEvent>>(
              stream: FirebaseDraftService.instance.notificationTimeline(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data ?? [];
                final filtered = _filterEvents(events);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterRow('語氣', _extractUnique(events, (event) => event.tone)),
                    _buildFilterRow('渠道', _extractUnique(events, (event) => event.channel)),
                    _buildFilterRow('狀態', _extractUnique(events, (event) => event.status)),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Text('目前尚無符合條件的通知紀錄。')
                    else
                    ...filtered.map(_buildEventTile),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
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
      subtitle: Text("${event.channel} · ${event.status}${event.tone != null ? ' · ${event.tone}' : ''}"),
      trailing: Text(event.occurredAt.toLocal().toString().split('.').first),
    );
  }

  List<String> _extractUnique(List<NotificationEvent> events, String? Function(NotificationEvent) extractor) {
    final values = events.map(extractor).whereType<String>().toSet().toList();
    values.sort();
    return values;
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
}
