import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/features/auth/providers/auth_provider.dart';

class NewsDetailScreen extends ConsumerWidget {
  final Map<String, dynamic>? newsItem;

  const NewsDetailScreen({super.key, this.newsItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = newsItem ?? _getDummyItem();
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    final isDeath = subType == 'death' || type == 'obituary';
    final currentUser = ref.watch(authProvider).user;
    final createdBy = item['created_by'];
    final creatorId = createdBy is Map
        ? (createdBy['_id'] as String? ?? '')
        : (createdBy as String? ?? '');
    final isOwner = currentUser != null && creatorId.isNotEmpty && currentUser.id == creatorId;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDeath: isDeath),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: isDeath
                      ? _buildObituaryBody(context, item)
                      : _buildAnnouncementBody(context, ref, item, isOwner),
                ),
              ),
              if (isDeath) _buildObituaryFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isDeath}) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeath ? 'تفاصيل النعي' : 'تفاصيل الخبر',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDeath ? 'معلومات الوفاة والعزاء' : 'الأخبار والمناسبات والإعلانات',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBody(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    bool isOwner,
  ) {
    final title = item['title'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';
    final imageUrl = resolveMediaUrl(item['image'] as String?);
    final createdBy = item['created_by'];
    final publisherName = createdBy is Map ? (createdBy['full_name'] as String? ?? '') : '';
    final rawDate = (item['published_at'] as String?) ?? (item['created_at'] as String? ?? '');
    final publishDate = _formatDate(rawDate);
    final newsId = item['_id'] as String? ?? item['id'] as String? ?? '';
    final label = _typeLabelFor(item);
    final color = _typeColorFor(item);
    final icon = _typeIconFor(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: double.infinity,
                          height: 220,
                          color: const Color(0xFFE8EEF3),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined, size: 42, color: AppColors.textHint),
                        ),
                      ),
                      Positioned(top: 14, right: 14, child: _TypeBadge(label: label, color: color, icon: icon)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isEmpty) ...[
                      _TypeBadge(label: label, color: color, icon: icon, filled: false),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (publisherName.isNotEmpty)
                          _MetaChip(icon: Icons.person_outline_rounded, label: publisherName),
                        if (publishDate.isNotEmpty)
                          _MetaChip(icon: Icons.schedule_rounded, label: publishDate),
                      ],
                    ),
                    if (isOwner && newsId.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'تعديل',
                              icon: Icons.edit_outlined,
                              background: AppColors.primary,
                              foreground: Colors.white,
                              onTap: () async {
                                await context.push('/add-announcement', extra: item);
                                if (context.mounted) context.pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'حذف',
                              icon: Icons.delete_outline_rounded,
                              background: const Color(0xFFFEF2F2),
                              foreground: const Color(0xFFDC2626),
                              onTap: () => _deleteNews(context, ref, newsId),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    _buildContentBody(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObituaryBody(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'عنوان الوفاة';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';
    final prayerTime = item['prayer_time'] as String? ?? '';
    final deathDate = item['death_date'] as String? ?? _formatDate(item['created_at'] as String?);
    final burialLocation = item['burial_location'] as String? ?? subtitle;
    final menCondolence = item['men_condolence_location'] as String? ?? '';
    final womenCondolence = item['women_condolence_location'] as String? ?? '';
    final notes = item['notes'] as String? ?? body;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mosque_outlined, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'إنا لله وإنا إليه راجعون',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'المرحوم: $title',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (prayerTime.isNotEmpty)
              Expanded(
                child: _InfoTile(label: 'وقت الصلاة', value: prayerTime, icon: Icons.access_time_rounded),
              ),
            if (prayerTime.isNotEmpty && deathDate.isNotEmpty) const SizedBox(width: 12),
            if (deathDate.isNotEmpty)
              Expanded(
                child: _InfoTile(label: 'تاريخ الوفاة', value: deathDate, icon: Icons.calendar_today_rounded),
              ),
          ],
        ),
        if (burialLocation.isNotEmpty) ...[
          const SizedBox(height: 14),
          _LocationCard(title: 'مكان الصلاة والدفن', location: burialLocation),
        ],
        if (menCondolence.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LocationCard(title: 'عزاء الرجال', location: menCondolence),
        ],
        if (womenCondolence.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LocationCard(title: 'عزاء النساء', location: womenCondolence),
        ],
        const SizedBox(height: 14),
        _buildDonationCard(context),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'ملاحظات إضافية',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notes,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDonationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.volunteer_activism_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صندوق الكشف',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'للمساهمة في تكاليف العزاء',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showComingSoon(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('ساهم الآن'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObituaryFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.7))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('نشر ومشاركة الإعلان'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody(String raw) {
    if (raw.isEmpty) {
      return const Text(
        'لا يوجد محتوى لهذا الإعلان بعد.',
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.9,
        ),
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return _QuillContentView(document: quill.Document.fromJson(decoded));
      }
    } catch (_) {}

    return Text(
      _extractPlainContent(raw),
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 15,
        color: AppColors.textSecondary,
        height: 1.9,
      ),
    );
  }

  String _extractPlainContent(String raw) {
    if (raw.contains('insert⟨')) {
      final re = RegExp(r'insert⟨(.*?)⟩', dotAll: true);
      final matches = re.allMatches(raw);
      if (matches.isNotEmpty) {
        return matches.map((m) => m.group(1) ?? '').join().replaceAll('⏎', '\n').trim();
      }
    }
    return raw.trim();
  }

  Future<void> _deleteNews(BuildContext context, WidgetRef ref, String newsId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'هل تريد حذف هذا الإعلان نهائياً؟',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textSecondary, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Color(0xFFDC2626))),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/news/$newsId');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الإعلان بنجاح', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قريباً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  String _formatDate(String? raw) {
    final date = DateTime.tryParse(raw ?? '')?.toLocal();
    if (date == null) return raw ?? '';
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

  Map<String, dynamic> _getDummyItem() {
    return {
      'title': 'محمد أحمد العبدالله',
      'subtitle': 'مسجد الفاروق - مقبرة الصليبيخات',
      'type': 'obituary',
      'sub_type': 'death',
      'created_at': '2024-05-24',
      'body': 'يُقبل العزاء عبر الاتصال الهاتفي أو الرسائل النصية نظراً للظروف الحالية. نسأل الله للفقيد الرحمة والمغفرة ولأهله الصبر والسلوان.',
      'prayer_time': '04:30 PM',
      'death_date': '24/05/2024',
      'burial_location': 'مسجد الفاروق - مقبرة الصليبيخات',
      'men_condolence_location': 'ديوان العبدالله - الرميثية قطعة 4',
      'women_condolence_location': 'منزل الفقيد - سلوى قطعة 10',
    };
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.white.withValues(alpha: 0.95) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String title;
  final String location;
  const _LocationCard({required this.title, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
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
        ],
      ),
    );
  }
}

class _QuillContentView extends StatefulWidget {
  final quill.Document document;
  const _QuillContentView({required this.document});

  @override
  State<_QuillContentView> createState() => _QuillContentViewState();
}

class _QuillContentViewState extends State<_QuillContentView> {
  late final quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: widget.document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return quill.QuillEditor.basic(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: const quill.QuillEditorConfig(
        padding: EdgeInsets.zero,
        expands: false,
        scrollable: false,
        showCursor: false,
        enableInteractiveSelection: true,
      ),
    );
  }
}
