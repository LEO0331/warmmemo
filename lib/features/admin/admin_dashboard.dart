import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String? _cursor;
  bool _loadingPage = false;
  bool _initializedForAdmin = false;
  bool _adminDocEnsured = false;
  bool _adminDocChecked = false;
  bool? _adminDocExists;
  final List<Purchase> _allOrders = [];

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
            try {
              await UserRoleService.instance.ensureAdminDoc(uid);
              final exists = await UserRoleService.instance.adminDocExists(uid);
              if (!mounted) return;
              setState(() {
                _adminDocExists = exists;
                _adminDocChecked = true;
              });
            } catch (error) {
              if (!mounted) return;
              setState(() {
                _adminDocChecked = true;
                _adminDocExists = false;
              });
              messenger.showSnackBar(
                SnackBar(content: Text('建立管理員識別失敗：$error')),
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
                  await Clipboard.setData(ClipboardData(text: uid));
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('已複製 UID：$uid')),
                  );
                },
                child: const Text('複製 UID'),
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
          Text('檢視用戶提交的方案訂單，並可針對單筆填寫禮儀公司資訊後完成案件。'),
          const SizedBox(height: 16),
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
    final filtered = _applyFilters(_allOrders);
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
          if (filtered.isEmpty)
            const Text('目前沒有符合條件的訂單。')
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
  }

  Widget _buildOrdersWorkQueue() {
    final filtered = _applyFilters(_allOrders);
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
                  setState(() {
                    final idx = _allOrders.indexWhere((p) => p.id == updated.id);
                    if (idx != -1) _allOrders[idx] = updated.copyWith(status: 'complete');
                  });
                }
              },
              child: const Text('填寫/完成'),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Purchase> _applyFilters(List<Purchase> source) {
    return source.where((o) {
      final sOk = _statusFilter == null || o.status == _statusFilter;
      final pOk = _planFilter == null || o.planName == _planFilter;
      return sOk && pOk;
    }).toList();
  }

  Future<void> _loadFirstPage() async {
    setState(() => _loadingPage = true);
    try {
      final page = await PurchaseService.instance.adminOrdersPage(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _allOrders
          ..clear()
          ..addAll(page.items);
        _cursor = page.cursor;
        _loadingPage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPage = false;
        _cursor = null;
      });
      final currentUid = AuthService.instance.currentUser?.uid ?? '-';
      final message = error.toString().contains('permission-denied')
          ? '讀取訂單失敗：permission-denied。請確認 Firestore 有 `admins/$currentUid` 文件，'
              '且後台查詢已使用小分頁（目前 $_pageSize 筆/頁）。'
          : '讀取訂單失敗：$error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _loadMore() async {
    if (_cursor == null || _loadingPage) return;
    setState(() => _loadingPage = true);
    try {
      final page = await PurchaseService.instance.adminOrdersPage(
        limit: _pageSize,
        startAfterCreatedAt: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _allOrders.addAll(page.items);
        _cursor = page.cursor;
        _loadingPage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingPage = false);
      final currentUid = AuthService.instance.currentUser?.uid ?? '-';
      final message = error.toString().contains('permission-denied')
          ? '載入更多失敗：permission-denied。請確認 Firestore 有 `admins/$currentUid` 文件。'
          : '載入更多失敗：$error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
