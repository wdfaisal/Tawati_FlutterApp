import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/news/screens/news_detail_screen.dart';

const Color _kHeaderBorder = Color(0xFFE2E8F0);
const Color _kSoftBg = Color(0xFFF1F5F8);
const Color _kMuted = Color(0xFF9CAFB8);
const Color _kSecondary = Color(0xFF62707B);
const Color _kNameColor = Color(0xFF1A242B);
const Color _kDivider = Color(0xFFF1F5F8);

class NewsTab extends ConsumerStatefulWidget {
  const NewsTab({super.key});

  @override
  ConsumerState<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends ConsumerState<NewsTab> {
  static const List<String> _tabs = ['الكل', 'المناسبات', 'الوفيات', 'الإعلانات'];

  List<Map<String, dynamic>> _newsItems = [];
  bool _loading = true;
  String? _error;
  int _tabIndex = 0;
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNews());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
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
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'حدث خطأ أثناء تحميل الأخبار';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ أثناء تحميل الأخبار';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SafeArea(bottom: false, child: _buildHeader()),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kHeaderBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 36,
                  child: SvgPicture.asset('assets/logo/tawati-primary.svg', fit: BoxFit.contain),
                ),
                _buildSearchButton(),
              ],
            ),
          ),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Material(
      color: _kSoftBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() {
          if (_searchActive) {
            _searchController.clear();
            _query = '';
          }
          _searchActive = !_searchActive;
        }),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            _searchActive ? Icons.close_rounded : Icons.search_rounded,
            size: 19,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        for (var i = 0; i < _tabs.length; i++) Expanded(child: _buildTab(i)),
      ],
    );
  }

  Widget _buildTab(int index) {
    final active = index == _tabIndex;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          _tabs[index],
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 14,
            height: 1.25,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : _kMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildShimmer();
    if (_error != null) return _buildError();

    final filtered = _filteredItems();
    return Column(
      children: [
        if (_searchActive) _buildSearchField(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadNews,
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _NewsCard(item: filtered[index]),
                  ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filteredItems() {
    var items = _newsItems.where(_matchesTab).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((item) {
        final title = (item['title'] as String? ?? '').toLowerCase();
        final subtitle = (item['subtitle'] as String? ?? item['description'] as String? ?? '').toLowerCase();
        final body = (item['body'] as String? ?? item['content'] as String? ?? '').toLowerCase();
        return title.contains(q) || subtitle.contains(q) || body.contains(q);
      }).toList();
    }
    return items;
  }

  bool _matchesTab(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    switch (_tabIndex) {
      case 1: // المناسبات
        return subType == 'wedding' || subType == 'congratulation' || (type == 'social_occasion' && subType != 'death');
      case 2: // الوفيات
        return subType == 'death';
      case 3: // الإعلانات
        return type == 'general' || type == 'important' || type == 'admin_alert' || type == 'platform_announcement';
      default:
        return true;
    }
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kNameColor),
        decoration: InputDecoration(
          hintText: 'ابحث في الأخبار والمناسبات...',
          hintStyle: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 13, color: _kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kMuted),
          suffixIcon: GestureDetector(
            onTap: () => setState(() {
              _searchActive = false;
              _searchController.clear();
              _query = '';
            }),
            child: const Icon(Icons.close_rounded, size: 18, color: _kMuted),
          ),
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
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            skeletonLine(width: 80, height: 14, margin: EdgeInsets.zero),
            const SizedBox(height: 12),
            skeletonLine(height: 14, margin: EdgeInsets.zero),
            const SizedBox(height: 8),
            skeletonLine(width: 180, height: 13, margin: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: _kMuted),
          const SizedBox(height: 14),
          const Text(
            'تعذر تحميل الأخبار',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadNews,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final (icon, title) = switch (_tabIndex) {
      1 => (Icons.event_available_outlined, 'لا توجد مناسبات حالياً'),
      2 => (Icons.local_florist_outlined, 'لا توجد وفيات حالياً'),
      3 => (Icons.campaign_outlined, 'لا توجد إعلانات حالياً'),
      _ => (Icons.newspaper_outlined, 'لا توجد أخبار حالياً'),
    };
    final hasQuery = _query.trim().isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 96, left: 24, right: 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: _kSoftBg, shape: BoxShape.circle),
                child: Icon(hasQuery ? Icons.search_off_rounded : icon, size: 30, color: _kMuted),
              ),
              const SizedBox(height: 16),
              Text(
                hasQuery ? 'لا توجد نتائج مطابقة لبحثك' : title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kNameColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasQuery ? 'جرّب كلمة بحث مختلفة.' : 'ستظهر المحتويات الجديدة هنا',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: _kMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '';
    final content = item['subtitle'] as String? ?? item['description'] as String? ?? item['content'] as String? ?? '';
    final imageUrl = resolveMediaUrl(item['image'] as String?);
    final (label, chipColor) = _labelFor(item);
    final rawDate = (item['published_at'] as String?) ?? (item['created_at'] as String?) ?? '';
    final date = _formatNewsDate(rawDate);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailScreen(newsItem: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 170,
                  color: _kSoftBg,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, size: 36, color: _kMuted),
                ),
              ),
            Padding(
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
                          fontSize: 11,
                          color: _kMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kNameColor,
                    ),
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 13,
                        color: _kSecondary,
                        height: 1.5,
                      ),
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
}

(String, Color) _labelFor(Map<String, dynamic> item) {
  final type = item['type'] as String? ?? '';
  final subType = item['sub_type'] as String? ?? '';
  if (subType == 'death') return ('نعي', const Color(0xFF94A3B8));
  if (subType == 'wedding') return ('عرس', const Color(0xFFF59E0B));
  if (subType == 'congratulation') return ('تهنئة', const Color(0xFF0D9488));
  switch (type) {
    case 'admin_alert':
      return ('إعلان إداري', const Color(0xFF0D9488));
    case 'platform_announcement':
      return ('إعلان المنصة', const Color(0xFF1E40AF));
    case 'important':
      return ('إعلان', const Color(0xFFEF4444));
    case 'social_occasion':
      return ('مناسبة', const Color(0xFFF59E0B));
    default:
      return ('إعلان', const Color(0xFF3B82F6));
  }
}

String _formatNewsDate(String raw) {
  final d = DateTime.tryParse(raw)?.toLocal();
  if (d == null) return raw;
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final buffer = StringBuffer();
  for (final char in dateStr.split('')) {
    final code = char.codeUnitAt(0) - 0x30;
    buffer.write(code >= 0 && code <= 9 ? digits[code] : char);
  }
  return buffer.toString();
}
