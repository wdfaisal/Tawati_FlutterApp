import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/news/models/news.dart';
import 'package:tawati_mobile/src/features/initiatives/models/initiative.dart';
import 'package:tawati_mobile/src/features/donations/models/donation.dart';
import 'package:tawati_mobile/src/features/notifications/providers/notifications_provider.dart';

const Color _kSoftBg = Color(0xFFF1F5F8);
const Color _kMuted = Color(0xFF9CAFB8);
const Color _kSecondary = Color(0xFF62707B);
const Color _kNameColor = Color(0xFF1A242B);
const Color _kDivider = Color(0xFFF1F5F8);
const Color _kRed = Color(0xFFEF4444);

final _newsProvider = FutureProvider.autoDispose<List<News>>((ref) {
  return ref.read(newsServiceProvider).getNews();
});

final _initiativesProvider = FutureProvider.autoDispose<List<Initiative>>((ref) {
  return ref.read(initiativeServiceProvider).getInitiatives();
});

final _campaignsProvider = FutureProvider.autoDispose<List<Campaign>>((ref) {
  return ref.read(donationServiceProvider).getCampaigns();
});

class HomeTab extends ConsumerWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenDonations;
  final VoidCallback? onOpenGroups;

  const HomeTab({super.key, this.onOpenDrawer, this.onOpenDonations, this.onOpenGroups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(_newsProvider);
    final initiativesAsync = ref.watch(_initiativesProvider);
    final campaignsAsync = ref.watch(_campaignsProvider);
    final unreadCount = ref.watch(notificationsProvider).valueOrNull?.unread ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_newsProvider);
            ref.invalidate(_initiativesProvider);
            ref.invalidate(_campaignsProvider);
            ref.invalidate(notificationsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            children: [
              _HomeHeader(
                onOpenDrawer: onOpenDrawer,
                onSearch: () => _openSearchSheet(context, ref),
                onNotifications: () => context.push('/notifications'),
                unreadCount: unreadCount,
              ),
              const _Greeting(),
              _QuickActionsRow(
                onAddAnnouncement: () => context.push('/news'),
                onAddDeath: () => context.push('/news'),
                onOpenChats: onOpenGroups ?? () {},
                onDonate: onOpenDonations ?? () {},
              ),
              _CampaignsSection(
                campaignsAsync: campaignsAsync,
                onOpenAll: () => context.push('/donations'),
              ),
              _AnnouncementsSection(
                newsAsync: newsAsync,
                onOpenAll: () => context.push('/news'),
              ),
              _EventsSection(
                initiativesAsync: initiativesAsync,
                onOpenAll: () => context.push('/initiatives'),
              ),
              _DeathsSection(
                newsAsync: newsAsync,
                onOpenAll: () => context.push('/news'),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickActionsSheet(context, onOpenGroups, onOpenDonations),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 26),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _openSearchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _HomeSearchSheet(),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context, VoidCallback? onOpenGroups, VoidCallback? onOpenDonations) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Text(
                'إجراءات سريعة',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700, color: _kNameColor),
              ),
            ),
            _sheetItem(ctx, Icons.campaign_outlined, 'إضافة إعلان', () {
              Navigator.of(ctx).pop();
              context.push('/news');
            }),
            _sheetItem(ctx, Icons.description_outlined, 'إضافة وفاة', () {
              Navigator.of(ctx).pop();
              context.push('/news');
            }),
            _sheetItem(ctx, Icons.chat_bubble_outline_rounded, 'دردشة', () {
              Navigator.of(ctx).pop();
              onOpenGroups?.call();
            }),
            _sheetItem(ctx, Icons.volunteer_activism_outlined, 'تبرع', () {
              Navigator.of(ctx).pop();
              onOpenDonations?.call();
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
              ),
            ),
            const Icon(Icons.chevron_left_rounded, size: 18, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final int unreadCount;

  const _HomeHeader({this.onOpenDrawer, this.onSearch, this.onNotifications, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpenDrawer,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 100,
              height: 40,
              child: Image.asset('assets/images/splash_logo.png', fit: BoxFit.contain),
            ),
          ),
          const Spacer(),
          _NotificationsButton(onTap: onNotifications, unreadCount: unreadCount),
          const SizedBox(width: 12),
          _SearchButton(onTap: onSearch),
        ],
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  final VoidCallback? onTap;
  final int unreadCount;

  const _NotificationsButton({this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: _kSoftBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 9 ? '٩+' : _toArabicDigits('$unreadCount'),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SearchButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: _kSoftBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Icon(Icons.search_rounded, size: 19, color: AppColors.primary),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _kRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أهلاً بك في تواتي',
            textAlign: TextAlign.start,
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          SizedBox(height: 2),
          Text(
            'اكتشف آخر الأخبار والفعاليات في مجتمعك',
            textAlign: TextAlign.start,
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddAnnouncement;
  final VoidCallback onAddDeath;
  final VoidCallback onOpenChats;
  final VoidCallback onDonate;

  const _QuickActionsRow({
    required this.onAddAnnouncement,
    required this.onAddDeath,
    required this.onOpenChats,
    required this.onDonate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _QuickActionTile(icon: Icons.campaign_outlined, label: 'إضافة إعلان', onTap: onAddAnnouncement)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionTile(icon: Icons.description_outlined, label: 'إضافة وفاة', onTap: onAddDeath)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionTile(icon: Icons.chat_bubble_outline_rounded, label: 'دردشة', onTap: onOpenChats)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionTile(icon: Icons.volunteer_activism_outlined, label: 'تبرع', onTap: onDonate)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final double titleSize;

  const _SectionHeader({
    required this.title,
    this.actionLabel = '',
    this.onAction,
    this.titleSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: titleSize, fontWeight: FontWeight.w600, color: _kNameColor),
            ),
          ),
          if (actionLabel.isNotEmpty && onAction != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _sectionPadding({required Widget child}) {
  return Padding(padding: const EdgeInsets.only(top: 28), child: child);
}

class _CampaignsSection extends StatelessWidget {
  final AsyncValue<List<Campaign>> campaignsAsync;
  final VoidCallback onOpenAll;

  const _CampaignsSection({required this.campaignsAsync, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    return campaignsAsync.when(
      data: (list) {
        var campaigns = list.where((c) => c.isActive).toList();
        if (campaigns.isEmpty) campaigns = list;
        if (campaigns.isEmpty) return const SizedBox.shrink();
        return _sectionPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'صناديق التبرعات', actionLabel: 'عرض الكل', onAction: onOpenAll),
              const SizedBox(height: 12),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: campaigns.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _CampaignCard(campaign: campaigns[i]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _sectionPadding(child: _horizontalSkeleton(height: 178)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;

  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final percent = (campaign.progress * 100).round();
    final fmt = NumberFormat('#,##0');
    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Container(
        width: 288,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.volunteer_activism_outlined, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        campaign.fundName ?? campaign.description ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: _kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${_toArabicDigits('$percent')}٪',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                const Spacer(),
                Text(
                  'المستهدف: ${_toArabicDigits(fmt.format(campaign.targetAmount))} ر.س',
                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: _kSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: campaign.progress,
                backgroundColor: _kSoftBg,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => context.push('/campaign/${campaign.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w600),
                ),
                child: const Text('تبرع الآن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  final AsyncValue<List<News>> newsAsync;
  final VoidCallback onOpenAll;

  const _AnnouncementsSection({required this.newsAsync, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    return newsAsync.when(
      data: (list) {
        final items = list.where((n) => n.type == 'admin_alert' || n.type == 'announcement').toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return _sectionPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'آخر الإعلانات', actionLabel: 'عرض الكل', onAction: onOpenAll, titleSize: 16),
              const SizedBox(height: 12),
              SizedBox(
                height: 218,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _AnnouncementCard(item: items[i]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _sectionPadding(child: _announcementSkeleton()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final News item;

  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final image = item.image;
    return GestureDetector(
      onTap: () => context.push('/news/detail', extra: _newsToMap(item)),
      child: Container(
        width: 280,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kDivider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (image != null && image.isNotEmpty)
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'إعلان عام',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, fontWeight: FontWeight.w600, color: _kNameColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle ?? item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _kSoftBg,
      child: const Center(child: Icon(Icons.campaign_outlined, size: 32, color: _kMuted)),
    );
  }
}

class _EventsSection extends StatelessWidget {
  final AsyncValue<List<Initiative>> initiativesAsync;
  final VoidCallback onOpenAll;

  const _EventsSection({required this.initiativesAsync, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    return initiativesAsync.when(
      data: (list) {
        final items = list.where((i) => !i.isPast).take(3).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return _sectionPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'المناسبات القادمة', actionLabel: 'مشاهدة المزيد', onAction: onOpenAll),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) _EventRow(item: items[i], showBorder: i < items.length - 1),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _sectionPadding(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              skeletonLine(width: 140, height: 14, margin: EdgeInsets.zero),
              const SizedBox(height: 14),
              for (var i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      skeletonBox(width: 56, height: 56, borderRadius: 16),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            skeletonLine(width: 90, height: 10, margin: EdgeInsets.zero),
                            const SizedBox(height: 6),
                            skeletonLine(width: 160, height: 13, margin: EdgeInsets.zero),
                            const SizedBox(height: 6),
                            skeletonLine(width: 120, height: 11, margin: EdgeInsets.zero),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Initiative item;
  final bool showBorder;

  const _EventRow({required this.item, required this.showBorder});

  @override
  Widget build(BuildContext context) {
    final image = item.image;
    return GestureDetector(
      onTap: () => context.push('/initiative-detail/${item.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: _kDivider)) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: (image != null && image.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                      ),
                    )
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(item.startDate ?? item.createdAt),
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: _kMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
                  ),
                  if (item.location != null && item.location!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.groups_outlined, size: 24, color: AppColors.primary),
    );
  }
}

class _DeathsSection extends StatelessWidget {
  final AsyncValue<List<News>> newsAsync;
  final VoidCallback onOpenAll;

  const _DeathsSection({required this.newsAsync, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    return newsAsync.when(
      data: (list) {
        final deaths = list.where((n) => n.type == 'obituary').toList();
        if (deaths.isEmpty) return const SizedBox.shrink();
        return _sectionPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'الوفيات الأخيرة', actionLabel: 'عرض الكل', onAction: onOpenAll),
              const SizedBox(height: 12),
              _DeathCard(item: deaths.first),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DeathCard extends StatelessWidget {
  final News item;

  const _DeathCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final subtitle = (item.subtitle?.isNotEmpty ?? false) ? item.subtitle! : item.content;
    return GestureDetector(
      onTap: () => context.push('/news/detail', extra: _newsToMap(item)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.mic_none_rounded, size: 20, color: _kMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المرحوم بإذن الله: ${item.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, size: 20, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

typedef _SearchResult = ({IconData icon, String title, String subtitle, VoidCallback onTap});

class _HomeSearchSheet extends ConsumerStatefulWidget {
  const _HomeSearchSheet();

  @override
  ConsumerState<_HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends ConsumerState<_HomeSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final news = ref.watch(_newsProvider).valueOrNull ?? const <News>[];
    final initiatives = ref.watch(_initiativesProvider).valueOrNull ?? const <Initiative>[];
    final campaigns = ref.watch(_campaignsProvider).valueOrNull ?? const <Campaign>[];

    final results = <_SearchResult>[];
    if (q.isNotEmpty) {
      for (final n in news) {
        if (n.title.toLowerCase().contains(q) || (n.subtitle?.toLowerCase().contains(q) ?? false)) {
          results.add((
            icon: Icons.article_outlined,
            title: n.title,
            subtitle: n.subtitle ?? '',
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/news/detail', extra: _newsToMap(n));
            },
          ));
        }
      }
      for (final i in initiatives) {
        if (i.title.toLowerCase().contains(q) || (i.description?.toLowerCase().contains(q) ?? false)) {
          results.add((
            icon: Icons.volunteer_activism_outlined,
            title: i.title,
            subtitle: i.location ?? '',
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/initiative-detail/${i.id}');
            },
          ));
        }
      }
      for (final c in campaigns) {
        if (c.title.toLowerCase().contains(q) || (c.description?.toLowerCase().contains(q) ?? false)) {
          results.add((
            icon: Icons.volunteer_activism_outlined,
            title: c.title,
            subtitle: c.fundName ?? '',
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/campaign/${c.id}');
            },
          ));
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'بحث في تواتي',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700, color: _kNameColor),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kNameColor),
            decoration: InputDecoration(
              hintText: 'ابحث عن إعلان، مناسبة، تبرع...',
              hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kMuted),
              filled: true,
              fillColor: _kSoftBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (q.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'اكتب كلمة للبحث في المحتوى',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted),
              ),
            )
          else if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'لا توجد نتائج مطابقة لبحثك',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _kDivider),
                itemBuilder: (context, index) {
                  final r = results[index];
                  return InkWell(
                    onTap: r.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: _kSoftBg, borderRadius: BorderRadius.circular(12)),
                            child: Icon(r.icon, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600, color: _kNameColor),
                                ),
                                if (r.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    r.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded, size: 18, color: _kMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Widget _horizontalSkeleton({required double height}) {
  return SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 288,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                skeletonBox(width: 48, height: 48, borderRadius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skeletonLine(width: 120, height: 12, margin: EdgeInsets.zero),
                      const SizedBox(height: 6),
                      skeletonLine(width: 80, height: 9, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            skeletonLine(height: 8, margin: EdgeInsets.zero),
            const SizedBox(height: 6),
            skeletonLine(height: 6, borderRadius: 3, margin: EdgeInsets.zero),
            const SizedBox(height: 10),
            skeletonBox(height: 36, borderRadius: 12),
          ],
        ),
      ),
    ),
  );
}

Widget _announcementSkeleton() {
  return SizedBox(
    height: 218,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 280,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            skeletonBox(height: 128, borderRadius: 0, margin: EdgeInsets.zero),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonLine(width: 140, height: 12, margin: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  skeletonLine(width: 200, height: 10, margin: EdgeInsets.zero),
                  const SizedBox(height: 6),
                  skeletonLine(width: 150, height: 10, margin: EdgeInsets.zero),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Map<String, dynamic> _newsToMap(News n) {
  final d = n.createdAt.toLocal();
  final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  return {
    'title': n.title,
    'subtitle': n.subtitle,
    'type': n.type,
    'sub_type': switch (n.type) {
      'obituary' => 'death',
      'wedding' => 'wedding',
      'social_occasion' => 'congratulation',
      _ => '',
    },
    'created_at': dateStr,
    'content': n.content,
  };
}

String _toArabicDigits(String input) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    final code = char.codeUnitAt(0) - 0x30;
    buffer.write(code >= 0 && code <= 9 ? digits[code] : char);
  }
  return buffer.toString();
}

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  return _toArabicDigits('${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}');
}
