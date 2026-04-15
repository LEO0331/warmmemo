import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/motion_tokens.dart';
import '../widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/services/token_wallet_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/services/user_role_service.dart';
import '../../features/admin/admin_dashboard.dart' deferred as admin_dashboard;
import '../../features/final_countdown/final_countdown_tab.dart'
    deferred as final_countdown_tab;
import '../../features/memorial/memorial_page_tab.dart'
    deferred as memorial_page_tab;
import '../../features/obituary/digital_obituary_tab.dart'
    deferred as digital_obituary_tab;
import '../../features/overview/overview_tab.dart' deferred as overview_tab;
import '../../features/packages/packages_tab.dart' deferred as packages_tab;
import '../../features/skills/skill_generator_tab.dart'
    deferred as skill_generator_tab;

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.loadLibrary,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  final List<_NavItem> _baseDestinations = [
    _NavItem(
      label: '流程總覽',
      icon: Icons.map_outlined,
      loadLibrary: overview_tab.loadLibrary,
      builder: () => overview_tab.OverviewTab(),
    ),
    _NavItem(
      label: '數位分身',
      icon: Icons.psychology_alt_outlined,
      loadLibrary: skill_generator_tab.loadLibrary,
      builder: () => skill_generator_tab.SkillGeneratorTab(),
    ),
    _NavItem(
      label: '人生倒數',
      icon: Icons.hourglass_bottom_outlined,
      loadLibrary: final_countdown_tab.loadLibrary,
      builder: () => final_countdown_tab.FinalCountdownTab(),
    ),
    _NavItem(
      label: '固定方案',
      icon: Icons.handshake_outlined,
      loadLibrary: packages_tab.loadLibrary,
      builder: () => packages_tab.PackagesTab(),
    ),
    _NavItem(
      label: '簡易紀念頁',
      icon: Icons.person_outline,
      loadLibrary: memorial_page_tab.loadLibrary,
      builder: () => memorial_page_tab.MemorialPageTab(),
    ),
    _NavItem(
      label: '數位訃聞',
      icon: Icons.campaign_outlined,
      loadLibrary: digital_obituary_tab.loadLibrary,
      builder: () => digital_obituary_tab.DigitalObituaryTab(),
    ),
  ];
  static final _adminDestination = _NavItem(
    label: 'Admin',
    icon: Icons.admin_panel_settings,
    loadLibrary: admin_dashboard.loadLibrary,
    builder: () => admin_dashboard.AdminDashboard(),
  );

  bool _isAdmin = false;
  bool _loadingRole = true;
  int _selectedIndex = 0;
  final Set<int> _loadedTabIndexes = <int>{};
  final Set<int> _loadingTabIndexes = <int>{};
  final Map<int, Widget> _tabWidgetCache = <int, Widget>{};
  StreamSubscription<String>? _roleSub;
  int? _queuedTabIndex;
  bool _isSwitchingTab = false;
  late final AnimationController _tabFadeController;

  List<_NavItem> get _destinations {
    if (_isAdmin) {
      // 管理者僅需查看後台
      return [_adminDestination];
    }
    return List<_NavItem>.from(_baseDestinations);
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex < 0 ? 0 : widget.initialIndex;
    _tabFadeController = AnimationController(
      vsync: this,
      duration: MotionTokens.button,
      value: 1,
    );
    _listenForRole();
    unawaited(_ensureTabLoaded(_selectedIndex));
  }

  Future<void> _listenForRole() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _roleSub?.cancel();
    _roleSub = UserRoleService.instance
        .roleStream(user.uid)
        .listen(
          (role) {
            if (!mounted) return;
            final nextIsAdmin = role == 'admin';
            setState(() {
              final roleChanged = _isAdmin != nextIsAdmin;
              _isAdmin = nextIsAdmin;
              _loadingRole = false;
              if (roleChanged) {
                _resetDeferredTabs();
              }
              if (_selectedIndex >= _destinations.length) {
                _selectedIndex = _destinations.length - 1;
              }
            });
            unawaited(_ensureTabLoaded(_selectedIndex));
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loadingRole = false;
              _isAdmin = false;
            });
            unawaited(_ensureTabLoaded(_selectedIndex));
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
    unawaited(_ensureTabLoaded(_selectedIndex));
  }

  @override
  void dispose() {
    _tabFadeController.dispose();
    _roleSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final destinations = _destinations;
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('暖備 WarmMemo'),
        centerTitle: false,
        actions: [
          if (!_isAdmin) _buildTokenBalanceChip(),
          if (!_isAdmin)
            IconButton(
              icon: const Icon(Icons.tips_and_updates_outlined),
              tooltip: '使用引導',
              onPressed: () {
                final uid = AuthService.instance.currentUser?.uid;
                if (uid == null) return;
                _showOnboardingIfNeeded(uid, forceOpen: true);
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: '登出',
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildDrawerContent(destinations)),
      body: WarmBackdrop(
        child: Row(
          children: [
            if (isWide) _buildSidebar(destinations),
            Expanded(
              child: SelectionArea(
                child: AnimatedBuilder(
                  animation: _tabFadeController,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List<Widget>.generate(
                      destinations.length,
                      (index) => _buildTabChild(index, destinations[index]),
                    ),
                  ),
                  builder: (context, child) {
                    final curved = CurvedAnimation(
                      parent: _tabFadeController,
                      curve: MotionTokens.gentleCurve,
                    );
                    final dy = (1 - curved.value) * 8;
                    return FadeTransition(
                      opacity: curved,
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      ),
                    );
                  },
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
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.fireplace,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WarmMemo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: selected
                        ? const Color(0xFFF8E5D8)
                        : Colors.transparent,
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: selected,
                    onTap: () => _switchTab(index),
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
              onTap: () async {
                final navigator = Navigator.of(context);
                await _switchTab(index);
                if (!mounted) return;
                navigator.maybePop();
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
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showOnboardingIfNeeded(
    String uid, {
    bool forceOpen = false,
  }) async {
    Map<String, dynamic>? profile;
    try {
      profile = await UserProfileService.instance.getProfile(uid);
    } catch (_) {
      return;
    }
    final done = UserProfileService.instance.completedStepsCount(profile);
    if (!forceOpen && done >= UserProfileService.onboardingTotalSteps ||
        !mounted) {
      return;
    }

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

    await Future<void>.delayed(MotionTokens.button);
    if (!mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: '首次引導',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: MotionTokens.dialog,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StreamBuilder<Map<String, dynamic>?>(
          stream: UserProfileService.instance.profileStream(uid),
          builder: (context, snapshot) {
            final data = snapshot.data ?? profile ?? const <String, dynamic>{};
            final steps =
                (data['onboardingSteps'] as List<dynamic>? ?? const [])
                    .whereType<String>()
                    .toSet();
            final completed = UserProfileService.instance.completedStepsCount(
              data,
            );
            final selectedService =
                data['onboardingSelectedService'] as String?;

            Widget stepTile({
              required String title,
              required bool done,
              Widget? action,
            }) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFEAF5EC)
                      : const Color(0xFFFFF4EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title)),
                    action ?? const SizedBox.shrink(),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: AlertDialog(
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
                              done: steps.contains(
                                UserProfileService.onboardingStepSelectService,
                              ),
                              action: selectedService == null
                                  ? PopupMenuButton<String>(
                                      onSelected: chooseService,
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: '固定方案',
                                          child: Text('固定方案'),
                                        ),
                                        PopupMenuItem(
                                          value: '簡易紀念頁',
                                          child: Text('簡易紀念頁'),
                                        ),
                                        PopupMenuItem(
                                          value: '數位訃聞',
                                          child: Text('數位訃聞'),
                                        ),
                                      ],
                                      child: const Text('選擇'),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            stepTile(
                              title: '2) 生成第一份草稿（在紀念頁或訃聞頁）',
                              done: steps.contains(
                                UserProfileService.onboardingStepFirstDraft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            stepTile(
                              title: '3) 看到剩餘 token',
                              done: steps.contains(
                                UserProfileService.onboardingStepTokenSeen,
                              ),
                              action:
                                  steps.contains(
                                    UserProfileService.onboardingStepTokenSeen,
                                  )
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
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MotionTokens.gentleCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _switchTab(int index) async {
    if (index == _selectedIndex) return;
    if (index < 0 || index >= _destinations.length) return;
    if (_isSwitchingTab) {
      _queuedTabIndex = index;
      return;
    }
    _isSwitchingTab = true;
    try {
      await _tabFadeController.reverse();
      if (!mounted) return;
      setState(() => _selectedIndex = index);
      unawaited(_ensureTabLoaded(index));
      await _tabFadeController.forward();
    } finally {
      _isSwitchingTab = false;
      final queued = _queuedTabIndex;
      _queuedTabIndex = null;
      if (queued != null && queued != _selectedIndex && mounted) {
        await _switchTab(queued);
      }
    }
  }

  void _resetDeferredTabs() {
    _loadedTabIndexes.clear();
    _loadingTabIndexes.clear();
    _tabWidgetCache.clear();
  }

  Future<void> _ensureTabLoaded(int index) async {
    final destinations = _destinations;
    if (index < 0 || index >= destinations.length) return;
    if (_loadedTabIndexes.contains(index) ||
        _loadingTabIndexes.contains(index)) {
      return;
    }

    _loadingTabIndexes.add(index);
    try {
      await destinations[index].loadLibrary();
      if (!mounted) return;
      setState(() {
        _loadedTabIndexes.add(index);
        _tabWidgetCache.putIfAbsent(index, destinations[index].builder);
      });
    } finally {
      _loadingTabIndexes.remove(index);
    }
  }

  Widget _buildTabChild(int index, _NavItem item) {
    if (_loadedTabIndexes.contains(index)) {
      return _tabWidgetCache.putIfAbsent(index, item.builder);
    }
    unawaited(_ensureTabLoaded(index));
    return const Center(child: CircularProgressIndicator());
  }
}
