import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final name = user?.fullNameAr ?? 'مستخدم';
    final memberNumber = user?.memberNumber ?? '';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            HeaderSection(name: name, memberNumber: memberNumber),
            NavSection(onNavigate: (route) {
              Navigator.of(context).pop();
              context.pushNamed(route);
            }),
            BottomSection(onSignOut: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.goNamed('login');
            }),
          ],
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  final String name;
  final String memberNumber;

  const HeaderSection({super.key, required this.name, required this.memberNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(Icons.person, size: 36, color: AppColors.primary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Scaffold.of(context).closeEndDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (memberNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.verified, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  memberNumber,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class NavSection extends StatelessWidget {
  final void Function(String route) onNavigate;

  const NavSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'الرئيسية', route: 'home', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.badge_outlined, activeIcon: Icons.badge, label: 'الهوية الرقمية', route: 'familyTree', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism, label: 'التبرعات', route: 'donations', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'تبرعاتي', route: 'myDonations', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'المبادرات والمجموعات', route: 'initiatives', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'الأخبار والمناسبات', route: 'news', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.account_tree_outlined, activeIcon: Icons.account_tree, label: 'شجرة العائلة', route: 'familyTree', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.how_to_reg_outlined, activeIcon: Icons.how_to_reg, label: 'طلبات الانضمام', route: 'joinRequests', onTap: onNavigate),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'الإشعارات', route: 'notifications', onTap: onNavigate),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'الإعدادات', route: 'settings', onTap: (_) {}),
          const SizedBox(height: 4),
          _NavItem(icon: Icons.headset_mic_outlined, activeIcon: Icons.headset_mic, label: 'تواصل معنا', route: 'contact', onTap: (_) {}),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final void Function(String route) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.textHint),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomSection extends StatelessWidget {
  final VoidCallback onSignOut;

  const BottomSection({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تواتي © 2024 — الإصدار 1.2.0',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 10,
              color: AppColors.textHint,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
