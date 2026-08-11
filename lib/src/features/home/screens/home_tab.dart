import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';
import 'package:tawati_mobile/src/features/news/models/news.dart';
import 'package:tawati_mobile/src/features/initiatives/models/initiative.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/shared/widgets/shared_widgets.dart';

final _newsProvider = FutureProvider.autoDispose<List<News>>((ref) {
  return ref.read(newsServiceProvider).getNews();
});

final _initiativesProvider = FutureProvider.autoDispose<List<Initiative>>((ref) {
  return ref.read(initiativeServiceProvider).getInitiatives();
});

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final newsAsync = ref.watch(_newsProvider);
    final initiativesAsync = ref.watch(_initiativesProvider);

    return Column(
      children: [
        const _TopAppBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_newsProvider);
              ref.invalidate(_initiativesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              children: [
                _SmartIdentityCard(userName: authState.user?.fullNameAr ?? ''),
          const SizedBox(height: 20),
          _SocialImpactSection(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: 'أحدث الأخبار',
              actionText: 'عرض الكل',
              onAction: () => context.go('/news'),
            ),
          ),
          const SizedBox(height: 8),
          newsAsync.when(
            data: (news) => SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: news.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 280,
                  child: NewsCard(
                    title: news[i].title,
                    subtitle: news[i].subtitle,
                    type: news[i].type,
                    date: news[i].createdAt,
                    onTap: () => context.push('/news/detail', extra: news[i]),
                  ),
                ),
              ),
            ),
            loading: () => SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skeletonBox(height: 120, borderRadius: 12),
                      const SizedBox(height: 10),
                      skeletonLine(width: 60, height: 10),
                      const SizedBox(height: 6),
                      skeletonLine(height: 14),
                      const SizedBox(height: 4),
                      skeletonLine(width: 160, height: 12),
                    ],
                  ),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorState(message: 'تعذر تحميل الأخبار', onRetry: () => ref.invalidate(_newsProvider)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: 'المبادرات النشطة',
              actionText: 'اكتشف المزيد',
              onAction: () => context.go('/initiatives'),
            ),
          ),
          const SizedBox(height: 8),
          initiativesAsync.when(
            data: (list) => Column(
              children: list.take(3).map((i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _InitiativeProgressCard(
                  title: i.title,
                  type: i.type,
                  participants: i.participantCount,
                  maxParticipants: i.maxParticipants,
                ),
              )).toList(),
            ),
            loading: () => Column(
              children: List.generate(2, (_) => skeletonCard()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorState(message: 'تعذر تحميل المبادرات', onRetry: () => ref.invalidate(_initiativesProvider)),
            ),
          ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding, left: 8, right: 8),
      height: 64 + topPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const Spacer(),
          Image.asset('assets/images/Tawati-logo.png', width: 100, height: 36),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SmartIdentityCard extends StatelessWidget {
  final String userName;
  const _SmartIdentityCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/1000308658.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك مجدداً',
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أهلاً بك يا ${userName.isNotEmpty ? userName : 'العارض'}',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  color: AppColors.primaryDark,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickActionButton(icon: Icons.qr_code_scanner, label: 'مسح QR'),
              const SizedBox(width: 8),
              _QuickActionButton(icon: Icons.account_balance_wallet_outlined, label: 'محفظتي'),
              const SizedBox(width: 8),
              _QuickActionButton(icon: Icons.settings_outlined, label: 'الإعدادات'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialImpactSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4, bottom: 12),
            child: Text(
              'أثرك المجتمعي',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ImpactCard(
                  icon: Icons.volunteer_activism,
                  value: '1,250',
                  label: 'إجمالي التبرعات (ر.س)',
                  iconBg: AppColors.primaryLight,
                  iconColor: AppColors.primary,
                  valueColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactCard(
                  icon: Icons.star,
                  value: '480',
                  label: 'نقاط تواتي المستحقة',
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  valueColor: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.groups, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '12',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
                      ),
                      Text(
                        'مبادرة ساهمت فيها بنجاح',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: AppColors.textHint.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  const _ImpactCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.w700, color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InitiativeProgressCard extends StatelessWidget {
  final String title;
  final String type;
  final int participants;
  final int maxParticipants;

  const _InitiativeProgressCard({
    required this.title,
    required this.type,
    required this.participants,
    required this.maxParticipants,
  });

  double get _progress => maxParticipants > 0 ? (participants / maxParticipants).clamp(0, 1) : 0;

  String get _progressPercent {
    final pct = (_progress * 100).round();
    return '$pct%';
  }

  Color get _typeColor {
    switch (type) {
      case 'workshop':
        return const Color(0xFF8B5CF6);
      case 'charity':
        return const Color(0xFFE11D48);
      case 'social':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }

  String get _typeLabel {
    switch (type) {
      case 'workshop':
        return 'ورشة';
      case 'charity':
        return 'خيرية';
      case 'social':
        return 'اجتماعية';
      default:
        return 'نشاط';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.volunteer_activism_outlined, color: _typeColor, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'نشط',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'اكتملت بنسبة $_progressPercent',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: AppColors.textHint),
                    ),
                    const Spacer(),
                    Text(
                      '$participants / $maxParticipants',
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.primaryLight,
                    valueColor: AlwaysStoppedAnimation<Color>(_typeColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
