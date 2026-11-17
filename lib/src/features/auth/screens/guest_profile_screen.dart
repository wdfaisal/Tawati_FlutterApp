import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';

class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'حسابي',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0F766E)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_outline_rounded,
                    size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'أنت تتصفح كزائر',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك الآن الاطلاع على أخبار العائلة والمبادرات وصناديق التبرعات. '
              'سجّل الدخول للوصول إلى هويتك الرقمية وشجرة العائلة والمجموعات وكل الخدمات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 13,
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => context.pushNamed('login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.pushNamed('register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'تقديم طلب انضمام للعائلة',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  _GuestFeatureRow(
                    icon: Icons.article_outlined,
                    title: 'الأخبار والمناسبات',
                    subtitle: 'متاحة للتصفح',
                    available: true,
                  ),
                  SizedBox(height: 14),
                  _GuestFeatureRow(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'المبادرات وصناديق التبرعات',
                    subtitle: 'متاحة للتصفح',
                    available: true,
                  ),
                  SizedBox(height: 14),
                  _GuestFeatureRow(
                    icon: Icons.badge_outlined,
                    title: 'الهوية الرقمية وشجرة العائلة',
                    subtitle: 'تتطلب تسجيل الدخول',
                    available: false,
                  ),
                  SizedBox(height: 14),
                  _GuestFeatureRow(
                    icon: Icons.groups_outlined,
                    title: 'المجموعات والدردشة',
                    subtitle: 'تتطلب تسجيل الدخول',
                    available: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool available;

  const _GuestFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.primary : AppColors.textHint;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: available ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 11,
                  color: available ? AppColors.success : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        Icon(
          available ? Icons.check_circle_outline : Icons.lock_outline,
          size: 18,
          color: available ? AppColors.success : AppColors.textHint,
        ),
      ],
    );
  }
}
