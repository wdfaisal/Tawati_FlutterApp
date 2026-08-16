import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:dio/dio.dart';

import 'package:tawati_mobile/src/core/providers.dart';
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
    NewsFilter.obituary: 'نعي',
    NewsFilter.wedding: 'عرس',
    NewsFilter.announcement: 'إعلان',
    NewsFilter.news: 'خبر',
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

      setState(() {
        _newsItems = allItems;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'حدث خطأ أثناء تحميل الأخبار';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _isLoading
              ? _buildShimmer()
              : _error != null
                  ? _buildError()
                  : _newsItems.isEmpty
                      ? _buildEmpty()
                      : _buildNewsList(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: NewsFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = NewsFilter.values[index];
          final isSelected = _selectedFilter == filter;
          return Center(
            child: FilterChip(
              label: Text(
                _filterLabels[filter]!,
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0D9488),
              backgroundColor: const Color(0xFFF8FAFC),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                  _loadNews();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 64,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أخبار حالياً',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 16,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    final filtered = _newsItems.where(_matchesFilter).toList();
    if (filtered.isEmpty) {
      return _buildEmpty();
    }
    return RefreshIndicator(
      color: const Color(0xFF0D9488),
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return _buildNewsCard(item);
        },
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
        return type == 'general' || type == 'important' || type == 'admin_alert';
      case NewsFilter.news:
        return type == 'social_occasion' && subType == 'congratulation';
      default:
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
      case 'important': return 'إعلان';
      case 'admin_alert': return 'إعلان إداري';
      case 'social_occasion': return 'مناسبة';
      default: return 'خبر';
    }
  }

  Color _typeColorFor(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    if (subType == 'death') return const Color(0xFF94A3B8);
    if (subType == 'wedding') return const Color(0xFFF59E0B);
    switch (type) {
      case 'admin_alert':
      case 'general': return const Color(0xFF0D9488);
      case 'important': return const Color(0xFFEF4444);
      default: return const Color(0xFF3B82F6);
    }
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final date = item['created_at'] as String? ?? '';

    final label = _typeLabelFor(item);
    final chipColor = _typeColorFor(item);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(newsItem: item),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
