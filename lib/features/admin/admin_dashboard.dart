import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/draft_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirebaseDraftService.instance.adminOverview(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data ?? [];
              final lastUpdated = items
                  .map((item) => item['updatedAt'] as Timestamp?)
                  .whereType<Timestamp>()
                  .map((ts) => ts.toDate())
                  .fold<DateTime?>(null, (previous, current) {
                if (previous == null) return current;
                return current.isAfter(previous) ? current : previous;
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    title: '平台概況',
                    icon: Icons.dashboard_customize_outlined,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('活躍用戶'),
                            Text('${items.length}'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('最後更新'),
                            Text(lastUpdated != null
                                ? lastUpdated.toIso8601String()
                                : '尚未更新'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('用戶列表', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...items.map((item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(item['uid'] ?? 'unknown'),
                          subtitle: Text(item['updatedAt'] != null
                              ? (item['updatedAt'] as Timestamp).toDate().toIso8601String()
                              : '無紀錄'),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
