import 'package:flutter/material.dart';

import '../../data/firebase/auth_service.dart';
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
  final List<_NavItem> _destinations = const [
    _NavItem('流程總覽', Icons.map_outlined, OverviewTab()),
    _NavItem('固定方案', Icons.handshake_outlined, PackagesTab()),
    _NavItem('簡易紀念頁', Icons.person_outline, MemorialPageTab()),
    _NavItem('數位訃聞', Icons.campaign_outlined, DigitalObituaryTab()),
    _NavItem('Admin', Icons.admin_panel_settings, AdminDashboard()),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('暖備 WarmMemo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => AuthService.instance.signOut(),
            tooltip: '登出',
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildDrawerContent(context)),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: _destinations
                  .map((dest) => NavigationRailDestination(
                        icon: Icon(dest.icon),
                        label: Text(dest.label),
                      ))
                  .toList(),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _destinations.map((dest) => dest.widget).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('WarmMemo'),
          ),
          ...List.generate(_destinations.length, (index) {
            final item = _destinations[index];
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
        ],
      ),
    );
  }
}
