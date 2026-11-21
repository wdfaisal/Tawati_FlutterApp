import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:dio/dio.dart';

import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/news/screens/news_detail_screen.dart';

enum NewsFilter { all, obituary, wedding, announcement, news }

class NewsTab extends ConsumerStatefulWidget {
  const NewsTab({super.key});

  @override
  ConsumerState<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends ConsumerState<NewsTab> {
  NewsFilter _selectedFilter = NewsFilter.all;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _newsItems = [];

  static const Map<NewsFilter, String> _filterLabels = {
    NewsFilter.all: 'الكل',
    NewsFilter.obituary: 'الوفيات',
    NewsFilter.wedding: 'المناسبات',
    NewsFilter.announcement: 'الإعلانات',
    NewsFilter.news: 'الأخبار',
  };

  static const Map<NewsFilter, IconData> _filterIcons = {
    NewsFilter.all: Icons.grid_view_rounded,
    NewsFilter.obituary: Icons.mosque_outlined,
    NewsFilter.wedding: Icons.celebration_outlined,
    NewsFilter.announcement: Icons.campaign_outlined,
    NewsFilter.news: Icons.newspaper_outlined,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNews());
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/news');
      final data = response.data;
      List<Map<String, dynamic>> allItems;
      if (data is Map && data['success'] == true && data['data'] is List) {
        allItems = List<Map<String, dynamic>>.from(data['data'] as List);
      } else if (data is Map && data['items'] is List) {
        allItems = List<Map<String, dynamic>>.from(data['items'] as List);
      } else if (data is List) {
        allItems = List<Map<String, dynamic>>.from(data);
      } else {
        allItems = [];
      }

      allItems = allItems.where((item) {
        final status = item['status'] as String? ?? 'published';
        return status == 'published';
      }).toList();

      if (!mounted) return;
      setState(() {
        _newsItems = allItems;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'حدث خطأ أثناء تحميل الأخبار';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ أثناء تحميل الأخبار';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    final filtered = _newsItems.where(_matchesFilter).toList();
    if (filtered.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: _loadNews,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _NewsCard(
          item: filtered[index],
          label: _typeLabelFor(filtered[index]),
          color: _typeColorFor(filtered[index]),
          icon: _typeIconFor(filtered[index]),
          date: _formatCardDate(
            (filtered[index]['published_at'] as String?) ??
                (filtered[index]['created_at'] as String?) ??
                '',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewsDetailScreen(newsItem: filtered[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: NewsFilter.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = NewsFilter.values[index];
            final isSelected = _selectedFilter == filter;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _filterIcons[filter],
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _filterLabels[filter]!,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 72, height: 24, radius: 8),
                  const SizedBox(height: 12),
                  _shimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  _shimmerBox(width: 220, height: 14),
                  const SizedBox(height: 12),
                  _shimmerBox(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 34, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذر تحميل الأخبار',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: _loadNews,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  textStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final isFiltered = _selectedFilter != NewsFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.filter_alt_off_outlined : Icons.newspaper_outlined,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'لا توجد عناصر في هذا التصنيف' : 'لا توجد أخبار حالياً',
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'جرّب اختيار تصنيف آخر للاطلاع على المزيد.'
                  : 'ستظهر هنا الأخبار والمناسبات والإعلانات عند نشرها.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    if (_selectedFilter == NewsFilter.all) return true;
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    switch (_selectedFilter) {
      case NewsFilter.obituary:
        return subType == 'death';
      case NewsFilter.wedding:
        return subType == 'wedding';
      case NewsFilter.announcement:
        return type == 'general' || type == 'important' || type == 'admin_alert' || type == 'platform_announcement';
      case NewsFilter.news:
        return type == 'social_occasion' && subType == 'congratulation';
      case NewsFilter.all:
        return true;
    }
  }

  String _typeLabelFor(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    if (subType == 'death') return 'نعي';
    if (subType == 'wedding') return 'عرس';
    if (subType == 'congratulation') return 'تهنئة';
    switch (type) {
      case 'general':
      case 'important':
        return 'إعلان';
      case 'admin_alert':
        return 'إعلان إداري';
      case 'platform_announcement':
        return 'إعلان المنصة';
      case 'social_occasion':
        return 'مناسبة';
      default:
        return 'خبر';
    }
  }

  Color _typeColorFor(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    if (subType == 'death') return const Color(0xFF64748B);
    if (subType == 'wedding') return const Color(0xFFD97706);
    if (subType == 'congratulation') return const Color(0xFF059669);
    switch (type) {
      case 'important':
        return const Color(0xFFDC2626);
      case 'admin_alert':
      case 'general':
        return AppColors.primary;
      case 'platform_announcement':
        return const Color(0xFF2563EB);
      default:
        return AppColors.primary;
    }
  }

  IconData _typeIconFor(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    if (subType == 'death') return Icons.mosque_outlined;
    if (subType == 'wedding') return Icons.celebration_outlined;
    if (subType == 'congratulation') return Icons.favorite_border_rounded;
    switch (type) {
      case 'important':
        return Icons.priority_high_rounded;
      case 'admin_alert':
        return Icons.admin_panel_settings_outlined;
      case 'platform_announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  String _formatCardDate(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    String toArabic(int n) => n.toString().split('').map((c) {
          final i = c.codeUnitAt(0) - 48;
          return (i >= 0 && i <= 9) ? arabic[i] : c;
        }).join();
    return '${toArabic(date.day)} ${months[date.month - 1]} ${toArabic(date.year)}';
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String label;
  final Color color;
  final IconData icon;
  final String date;
  final VoidCallback onTap;

  const _NewsCard({
    required this.item,
    required this.label,
    required this.color,
    required this.icon,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final imageUrl = resolveMediaUrl(item['image'] as String?);
    final createdBy = item['created_by'];
    final publisher = createdBy is Map ? (createdBy['full_name'] as String? ?? '') : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 176,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.02),
                                Colors.black.withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(top: 12, right: 12, child: _TypeBadge(label: label, color: color, icon: icon)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isEmpty) ...[
                      _TypeBadge(label: label, color: color, icon: icon, filled: false),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (publisher.isNotEmpty) ...[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              publisher,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'IBMPlexSansArabic',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded, size: 14, color: AppColors.textHint.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 176,
      width: double.infinity,
      color: const Color(0xFFE8EEF3),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 40, color: AppColors.textHint.withValues(alpha: 0.7)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool filled;

  const _TypeBadge({required this.label, required this.color, required this.icon, this.filled = true});

  @override
  Widget build(BuildContext context) {
    final bg = filled ? Colors.white.withValues(alpha: 0.95) : color.withValues(alpha: 0.08);
    final fg = filled ? color : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
