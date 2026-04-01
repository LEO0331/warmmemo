import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/firebase/auth_service.dart';
import '../../data/services/token_wallet_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/services/user_role_service.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/final_countdown/final_countdown_tab.dart';
import '../../features/memorial/memorial_page_tab.dart';
import '../../features/obituary/digital_obituary_tab.dart';
import '../../features/overview/overview_tab.dart';
import '../../features/packages/packages_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

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
    _NavItem('人生倒數', Icons.hourglass_bottom_outlined, FinalCountdownTab()),
    _NavItem('固定方案', Icons.handshake_outlined, PackagesTab()),
    _NavItem('簡易紀念頁', Icons.person_outline, MemorialPageTab()),
    _NavItem('數位訃聞', Icons.campaign_outlined, DigitalObituaryTab()),
  ];
  static const _adminDestination =
      _NavItem('Admin', Icons.admin_panel_settings, AdminDashboard());

  bool _isAdmin = false;
  bool _loadingRole = true;
  bool _onboardingPrompted = false;
  int _selectedIndex = 0;
  StreamSubscription<String>? _roleSub;

  List<_NavItem> get _destinations {
    if (_isAdmin) {
      // 管理者僅需查看後台
      return const [_adminDestination];
    }
    return List<_NavItem>.from(_baseDestinations);
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex < 0 ? 0 : widget.initialIndex;
    _listenForRole();
  }

  Future<void> _listenForRole() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _roleSub?.cancel();
    _roleSub = UserRoleService.instance.roleStream(user.uid).listen(
      (role) {
        if (!mounted) return;
        setState(() {
          _isAdmin = role == 'admin';
          _loadingRole = false;
          if (_selectedIndex >= _destinations.length) {
            _selectedIndex = _destinations.length - 1;
          }
        });
        if (!_isAdmin && !_onboardingPrompted) {
          _onboardingPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showOnboardingIfNeeded(user.uid);
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _loadingRole = false;
          _isAdmin = false;
        });
      },
    );
    try {
      await UserRoleService.instance.ensureUserProfile(user);
    } catch (_) {
      // Keep UI functional even if profile bootstrap is blocked by rules/config.
      if (!mounted) return;
      setState(() {
        _loadingRole = false;
      });
    }
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
          if (!_isAdmin) _buildTokenBalanceChip(),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: '登出',
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildDrawerContent(destinations)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF8), Color(0xFFFFF4EC)],
          ),
        ),
        child: Row(
          children: [
            if (isWide) _buildSidebar(destinations),
            Expanded(
              child: SelectionArea(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: destinations.map((dest) => dest.widget).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(List<_NavItem> destinations) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF6EF), Color(0xFFFFEFE2)],
        ),
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: selected ? const Color(0xFFF8E5D8) : Colors.transparent,
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: selected,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC8744F), Color(0xFFE0A57E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
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

  Widget _buildTokenBalanceChip() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: StreamBuilder<int>(
        stream: TokenWalletService.instance.balanceStream(uid),
        builder: (context, snapshot) {
          final tokens = snapshot.data ?? 0;
          return Chip(
            avatar: const Icon(Icons.toll_outlined, size: 18),
            label: Text('點數 $tokens'),
            backgroundColor: const Color(0xFFF8E5D8),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          );
        },
      ),
    );
  }

  Future<void> _showOnboardingIfNeeded(String uid) async {
    Map<String, dynamic>? profile;
    try {
      profile = await UserProfileService.instance.getProfile(uid);
    } catch (_) {
      return;
    }
    final done = UserProfileService.instance.completedStepsCount(profile);
    if (done >= UserProfileService.onboardingTotalSteps || !mounted) return;

    Future<void> chooseService(String service) async {
      await UserProfileService.instance.setSelectedService(uid, service);
      if (!mounted) return;
      setState(() {});
    }

    Future<void> markTokenSeen() async {
      await UserProfileService.instance.markOnboardingStep(
        uid,
        UserProfileService.onboardingStepTokenSeen,
      );
      if (!mounted) return;
      setState(() {});
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StreamBuilder<Map<String, dynamic>?>(
          stream: UserProfileService.instance.profileStream(uid),
          builder: (context, snapshot) {
            final data = snapshot.data ?? profile ?? const <String, dynamic>{};
            final steps =
                (data['onboardingSteps'] as List<dynamic>? ?? const []).whereType<String>().toSet();
            final completed = UserProfileService.instance.completedStepsCount(data);
            final selectedService = data['onboardingSelectedService'] as String?;

            Widget stepTile({
              required String title,
              required bool done,
              Widget? action,
            }) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: done ? const Color(0xFFEAF5EC) : const Color(0xFFFFF4EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title)),
                    action ?? const SizedBox.shrink(),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: const Text('首次引導'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('你已完成 $completed/3 步'),
                      const SizedBox(height: 10),
                      stepTile(
                        title: selectedService == null
                            ? '1) 選擇想優先使用的服務'
                            : '1) 已選擇服務：$selectedService',
                        done: steps.contains(UserProfileService.onboardingStepSelectService),
                        action: selectedService == null
                            ? PopupMenuButton<String>(
                                onSelected: chooseService,
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: '固定方案', child: Text('固定方案')),
                                  PopupMenuItem(value: '簡易紀念頁', child: Text('簡易紀念頁')),
                                  PopupMenuItem(value: '數位訃聞', child: Text('數位訃聞')),
                                ],
                                child: const Text('選擇'),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      stepTile(
                        title: '2) 生成第一份草稿（在紀念頁或訃聞頁）',
                        done: steps.contains(UserProfileService.onboardingStepFirstDraft),
                      ),
                      const SizedBox(height: 8),
                      stepTile(
                        title: '3) 看到剩餘 token',
                        done: steps.contains(UserProfileService.onboardingStepTokenSeen),
                        action: steps.contains(UserProfileService.onboardingStepTokenSeen)
                            ? null
                            : TextButton(
                                onPressed: markTokenSeen,
                                child: const Text('我看到了'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('關閉'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
