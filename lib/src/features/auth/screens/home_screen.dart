import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
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
  int _currentIndex = 0;

  List<_NavTab> _visibleTabs(Map<String, dynamic> config) {
    final modules = (config['modules'] as Map<String, dynamic>?) ?? const {};
    final donationsEnabled = modules['donations'] != false;
    final groupsEnabled = modules['groups'] != false;

    return [
      const _NavTab(
        screen: HomeTab(),
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
        const _NavTab(
          screen: DonationsTab(),
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
    final tabs = _visibleTabs(config);
    if (_currentIndex >= tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }
    final safeIndex = _currentIndex < tabs.length ? _currentIndex : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
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
