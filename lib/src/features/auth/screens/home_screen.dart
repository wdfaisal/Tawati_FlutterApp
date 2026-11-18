import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawati_mobile/src/core/guest_mode.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/auth/screens/guest_profile_screen.dart';
import 'package:tawati_mobile/src/features/home/screens/home_tab.dart';
import 'package:tawati_mobile/src/features/family/screens/card_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/donations_tab.dart';
import 'package:tawati_mobile/src/features/groups/screens/groups_tab.dart';
import 'package:tawati_mobile/src/features/family/screens/profile_screen.dart';
import 'package:tawati_mobile/src/shared/widgets/app_drawer.dart';

class _NavTab {
  final Widget screen;
  final String title;
  final IconData icon;
  final IconData activeIcon;

  const _NavTab({
    required this.screen,
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (ref.read(authProvider).isAuthenticated) {
      ref.read(fcmServiceProvider).initialize();
    }
    guestBlockedNotifier.addListener(_onGuestBlocked);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (guestBlockedNotifier.value > 0) _onGuestBlocked();
    });
  }

  @override
  void dispose() {
    guestBlockedNotifier.removeListener(_onGuestBlocked);
    super.dispose();
  }

  /// The router bounced a visitor away from a protected route: explain why and
  /// offer the sign-in sheet.
  void _onGuestBlocked() {
    if (!mounted || guestBlockedNotifier.value == 0) return;
    guestBlockedNotifier.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showGuestLoginPrompt(context);
    });
  }

  void _openTab(String title) {
    if (!mounted) return;
    final index = _visibleTabs(ref.read(appConfigProvider), isGuest: ref.read(authProvider).isVisitor)
        .indexWhere((t) => t.title == title);
    if (index >= 0) {
      setState(() => _currentIndex = index);
    }
  }

  List<_NavTab> _visibleTabs(Map<String, dynamic> config, {required bool isGuest}) {
    final modules = (config['modules'] as Map<String, dynamic>?) ?? const {};
    final donationsEnabled = modules['donations'] != false;
    final groupsEnabled = modules['groups'] != false;

    if (isGuest) {
      return [
        _NavTab(
          screen: HomeTab(
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            onOpenDonations: () => _openTab('التبرعات'),
            onOpenGroups: () => showGuestLoginPrompt(context),
          ),
          title: 'الرئيسية',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        if (donationsEnabled)
          _NavTab(
            screen: DonationsTab(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
            title: 'التبرعات',
            icon: Icons.volunteer_activism_outlined,
            activeIcon: Icons.volunteer_activism,
          ),
        const _NavTab(
          screen: GuestProfileScreen(),
          title: 'حسابي',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      ];
    }

    return [
      _NavTab(
        screen: HomeTab(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          onOpenDonations: () => _openTab('التبرعات'),
          onOpenGroups: () => _openTab('المجموعات'),
        ),
        title: 'الرئيسية',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      const _NavTab(
        screen: CardScreen(),
        title: 'تواتي',
        icon: Icons.badge_outlined,
        activeIcon: Icons.badge,
      ),
      if (donationsEnabled)
        _NavTab(
          screen: DonationsTab(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
          title: 'التبرعات',
          icon: Icons.volunteer_activism_outlined,
          activeIcon: Icons.volunteer_activism,
        ),
      if (groupsEnabled)
        const _NavTab(
          screen: GroupsTab(),
          title: 'المجموعات',
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups,
        ),
      const _NavTab(
        screen: ProfileScreen(),
        title: 'الملف',
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final isGuest = ref.watch(authProvider).isVisitor;
    final tabs = _visibleTabs(config, isGuest: isGuest);
    if (_currentIndex >= tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }
    final safeIndex = _currentIndex < tabs.length ? _currentIndex : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: safeIndex,
          children: [for (final t in tabs) t.screen],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(child: _buildNavItem(i, tabs[i])),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavTab tab) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12))
            : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? tab.activeIcon : tab.icon, color: isSelected ? AppColors.primary : AppColors.textHint, size: 22),
          const SizedBox(height: 4),
          Text(
            tab.title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ]),
      ),
    );
  }
}
