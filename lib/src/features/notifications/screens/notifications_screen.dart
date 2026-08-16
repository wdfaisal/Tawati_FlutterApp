import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../models/notification.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _navigatedIds = {};

  Future<void> _markSingleRead(AppNotification notification) async {
    if (notification.isRead) return;
    ref.read(notificationServiceProvider).markAsRead(ids: [notification.id]);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationServiceProvider).markAsRead();
    ref.invalidate(notificationsProvider);
  }

  Future<void> _openNotification(AppNotification notification) async {
    final type = notification.relatedResourceType;
    final id = notification.relatedResourceId;
    if (type == 'campaign' && id != null && id.isNotEmpty) {
      context.push('/campaign/$id');
    } else if (type == 'initiative' && id != null && id.isNotEmpty) {
      context.push('/initiative-detail/$id');
    } else if (type == 'news' && id != null && id.isNotEmpty) {
      try {
        final item = await ref.read(newsServiceProvider).getNewsById(id);
        if (mounted) context.push('/news/detail', extra: item);
      } catch (_) {}
    } else if (type == 'donation') {
      context.push('/my-donations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = notificationsAsync.valueOrNull?.unread ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'الإشعارات',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: unread > 0 ? _markAllRead : null,
              child: Text(
                'قراءة الكل',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12,
                  color: unread > 0 ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
        body: notificationsAsync.when(
          data: (result) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            color: AppColors.primary,
            child: result.notifications.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: result.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 72, endIndent: 16),
                    itemBuilder: (_, index) => _buildTile(result.notifications[index]),
                  ),
          ),
          loading: () => ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  skeletonBox(width: 44, height: 44, borderRadius: 14),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        skeletonLine(width: 140, height: 12, margin: EdgeInsets.zero),
                        const SizedBox(height: 8),
                        skeletonLine(width: double.infinity, height: 10, margin: EdgeInsets.zero),
                        const SizedBox(height: 6),
                        skeletonLine(width: 80, height: 10, margin: EdgeInsets.zero),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (_, __) => _buildError(),
        ),
      ),
    );
  }

  Widget _buildTile(AppNotification notification) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: () {
        if (!notification.isRead) _markSingleRead(notification);
        if (_navigatedIds.add(notification.id)) _openNotification(notification);
      },
      child: Container(
        color: isUnread ? AppColors.primaryLight.withValues(alpha: 0.45) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread ? AppColors.primary : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconForType(notification.type), size: 22, color: isUnread ? Colors.white : AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeLabel(notification.createdAt),
                        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 10, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textHint),
        const SizedBox(height: 14),
        const Text(
          'لا توجد إشعارات',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text(
            'حدث خطأ، يرجى المحاولة مرة أخرى',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.invalidate(notificationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'campaign':
      case 'donation':
      case 'donation_confirmed':
      case 'donation_rejected':
        return Icons.volunteer_activism_outlined;
      case 'initiative':
      case 'event':
      case 'initiative_reminder':
        return Icons.event_available_outlined;
      case 'group':
      case 'message':
      case 'chat':
        return Icons.forum_outlined;
      case 'news':
      case 'announcement':
      case 'admin_alert':
      case 'obituary':
      case 'platform_announcement':
        return Icons.campaign_outlined;
      case 'family':
      case 'family_member':
        return Icons.account_tree_outlined;
      case 'withdrawal':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${_digits('${diff.inMinutes}')} د';
    if (diff.inHours < 24 && DateTime(now.year, now.month, now.day) == DateTime(date.year, date.month, date.day)) {
      return 'منذ ${_digits('${diff.inHours}')} س';
    }
    if (DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays == 1) {
      return 'أمس';
    }
    return _digits('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}');
  }

  String _digits(String input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final code = char.codeUnitAt(0) - 0x30;
      buffer.write(code >= 0 && code <= 9 ? digits[code] : char);
    }
    return buffer.toString();
  }
}
