import 'package:flutter/material.dart';

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
  final ScrollController _scrollController = ScrollController();
  String? _statusFilter;
  String? _planFilter;

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
          Text('Admin 控制台', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('檢視用戶提交的方案訂單，並可針對單筆填寫禮儀公司資訊後完成案件。'),
          const SizedBox(height: 16),
          _buildOrdersOverview(),
          const SizedBox(height: 16),
          _buildOrdersWorkQueue(),
        ],
      ),
    );
  }

  Widget _buildOrdersOverview() {
    return StreamBuilder<List<Purchase>>(
      stream: PurchaseService.instance.adminOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        final planNames = orders.map((o) => o.planName).toSet().toList()..sort();
        final statuses = orders.map((o) => o.status).toSet().toList()..sort();
        final filtered = orders.where((o) {
          final sOk = _statusFilter == null || o.status == _statusFilter;
          final pOk = _planFilter == null || o.planName == _planFilter;
          return sOk && pOk;
        }).toList();
        return SectionCard(
          title: '方案訂單管理（檢視）',
          icon: Icons.assignment_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 12),
              if (filtered.isEmpty) const Text('目前沒有符合條件的訂單。')
              else
                ...filtered.map(
                  (o) => ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(o.planName),
                    subtitle: Text('狀態：${o.status}｜金額：${o.priceLabel}'),
                    trailing: Text(
                      o.createdAt.toLocal().toString().split('.').first,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersWorkQueue() {
    return StreamBuilder<List<Purchase>>(
      stream: PurchaseService.instance.adminOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        final filtered = orders.where((o) {
          final sOk = _statusFilter == null || o.status == _statusFilter;
          final pOk = _planFilter == null || o.planName == _planFilter;
          return sOk && pOk;
        }).toList();
        if (filtered.isEmpty) {
          return const SectionCard(
            title: '個別訂單處理',
            icon: Icons.task_outlined,
            child: Text('目前沒有待處理的訂單。'),
          );
        }
        return SectionCard(
          title: '個別訂單處理',
          icon: Icons.task_outlined,
          child: Column(
            children: filtered.map((o) {
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(o.planName),
                subtitle: Text('狀態：${o.status}｜用戶：${o.userId ?? '-'}'),
                trailing: FilledButton(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<Purchase>(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(purchase: o),
                      ),
                    );
                    if (updated != null && updated.userId != null) {
                      await PurchaseService.instance.updateOrder(
                        uid: updated.userId!,
                        purchase: updated.copyWith(status: 'complete'),
                      );
                    }
                  },
                  child: const Text('填寫/完成'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
