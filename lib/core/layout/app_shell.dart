import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/firebase/auth_service.dart';
import '../../data/services/user_role_service.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/memorial/memorial_page_tab.dart';
import '../../features/obituary/digital_obituary_tab.dart';
import '../../features/overview/overview_tab.dart';
import '../../features/packages/packages_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.widget);

  final String label;
  final IconData icon;
  final Widget widget;
}

class _AppShellState extends State<AppShell> {
  final List<_NavItem> _baseDestinations = const [
    _NavItem('流程總覽', Icons.map_outlined, OverviewTab()),
    _NavItem('固定方案', Icons.handshake_outlined, PackagesTab()),
    _NavItem('簡易紀念頁', Icons.person_outline, MemorialPageTab()),
    _NavItem('數位訃聞', Icons.campaign_outlined, DigitalObituaryTab()),
  ];
  static const _adminDestination =
      _NavItem('Admin', Icons.admin_panel_settings, AdminDashboard());

  bool _isAdmin = false;
  bool _loadingRole = true;
  int _selectedIndex = 0;
  StreamSubscription<String>? _roleSub;

  List<_NavItem> get _destinations {
    final list = List<_NavItem>.from(_baseDestinations);
    if (_isAdmin) list.add(_adminDestination);
    return list;
  }

  @override
  void initState() {
    super.initState();
    _listenForRole();
  }

  Future<void> _listenForRole() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await UserRoleService.instance.ensureUserProfile(user);
    _roleSub?.cancel();
    _roleSub = UserRoleService.instance.roleStream(user.uid).listen((role) {
      if (!mounted) return;
      setState(() {
        _isAdmin = role == 'admin';
        _loadingRole = false;
        if (_selectedIndex >= _destinations.length) {
          _selectedIndex = _destinations.length - 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = _destinations;
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('暖備 WarmMemo'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: '登出',
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildDrawerContent(destinations)),
      body: Row(
        children: [
          if (isWide) _buildSidebar(destinations),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: destinations.map((dest) => dest.widget).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<_NavItem> destinations) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.fireplace, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'WarmMemo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: destinations.length,
              // ignore: unnecessary_underscores
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = destinations[index];
                final selected = index == _selectedIndex;
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  selected: selected,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('登出'),
            onTap: () => AuthService.instance.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent(List<_NavItem> destinations) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text('WarmMemo', style: TextStyle(color: Colors.white)),
          ),
          ...List.generate(destinations.length, (index) {
            final item = destinations[index];
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              selected: index == _selectedIndex,
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.of(context).maybePop();
              },
            );
          }),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('登出'),
            onTap: () {
              Navigator.of(context).maybePop();
              AuthService.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
