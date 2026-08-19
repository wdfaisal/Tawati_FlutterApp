import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/media_url.dart';
import '../../../core/theme/app_theme.dart';
import '../models/news.dart';
import '../providers/news_providers.dart';
import '../services/news_service.dart';

class MyAnnouncementsTab extends ConsumerStatefulWidget {
  const MyAnnouncementsTab({super.key});

  @override
  ConsumerState<MyAnnouncementsTab> createState() => _MyAnnouncementsTabState();
}

class _MyAnnouncementsTabState extends ConsumerState<MyAnnouncementsTab> {
  List<News> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ref.read(newsServiceProvider).getMyNews(limit: 50);
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل التحميل'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F8), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primary),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F8), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'إعلاناتي',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            ' إدارة إعلاناتك المنشورة (${_items.length})',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'IBMPlexSansArabic'))),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'لا توجد إعلانات بعد',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildItem(_items[index]),
      ),
    );
  }

  Widget _buildItem(News item) {
    final imageUrl = resolveMediaUrl(item.image);
    final dateStr = _formatDate(item.createdAt);
    final statusColor = item.status == 'published' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusLabel = item.status == 'published' ? 'منشور' : item.status == 'draft' ? 'مسودة' : 'مؤرشف';

    return GestureDetector(
      onTap: () async {
        final result = await context.push('/add-announcement', extra: item.toJson());
        if (result == true && mounted) _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64, height: 64, color: const Color(0xFFF1F5F8),
                    child: const Icon(Icons.image_outlined, size: 28, color: AppColors.textHint),
                  ),
                ),
              )
            else
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: Color(0xFFF1F5F8), borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Icon(Icons.campaign_outlined, size: 28, color: AppColors.textHint),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateStr · ${item.typeLabel}',
                    style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(
                statusLabel,
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
