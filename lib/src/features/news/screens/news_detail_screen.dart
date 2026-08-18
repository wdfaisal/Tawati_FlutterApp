import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/media_url.dart';
import 'package:tawati_mobile/src/core/theme/app_theme.dart';
import 'package:tawati_mobile/src/core/providers.dart';
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
    final creatorId = createdBy is Map ? (createdBy['_id'] as String? ?? '') : (createdBy as String? ?? '');
    final isOwner = currentUser != null && creatorId.isNotEmpty && currentUser.id == creatorId;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: isDeath
                      ? _buildObituaryBody(context, ref, item)
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primary),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'تفاصيل الوفاة',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'تفاصيل حالة الوفاة المعلنة',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObituaryBody(BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'عنوان الوفاة';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';
    final prayerTime = item['prayer_time'] as String? ?? '04:30 PM';
    final deathDate = item['death_date'] as String? ?? _formatDate(item['created_at'] as String?);
    final burialLocation = item['burial_location'] as String? ?? subtitle;
    final menCondolence = item['men_condolence_location'] as String? ?? '';
    final womenCondolence = item['women_condolence_location'] as String? ?? '';
    final notes = item['notes'] as String? ?? body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                'المرحوم: $title',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'إنا لله وإنا إليه راجعون',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mosque_outlined, size: 24, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildInfoColumn(
                label: 'وقت الصلاة',
                value: prayerTime,
                icon: Icons.access_time_rounded,
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: _buildInfoColumn(
                label: 'تاريخ الوفاة',
                value: deathDate,
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (burialLocation.isNotEmpty)
          _buildLocationCard(
            title: 'مكان الصلاة والدفن',
            location: burialLocation,
            icon: Icons.location_on_outlined,
          ),
        if (menCondolence.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildLocationCard(
            title: 'عزاء الرجال',
            location: menCondolence,
            icon: Icons.location_on_outlined,
          ),
        ],
        if (womenCondolence.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildLocationCard(
            title: 'عزاء النساء',
            location: womenCondolence,
            icon: Icons.location_on_outlined,
          ),
        ],
        const SizedBox(height: 32),
        _buildDonationCard(context),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text(
            'ملاحظات إضافية',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              notes,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.8,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String location,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text(
                      'الموقع',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            location,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_outlined, size: 24, color: AppColors.primary),
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'للمساهمة في تكاليف العزاء',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قريباً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'ساهم الآن',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBody(BuildContext context, WidgetRef ref, Map<String, dynamic> item, bool isOwner) {
    final title = item['title'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';
    final imageUrl = resolveMediaUrl(item['image'] as String?);
    final createdBy = item['created_by'];
    final publisherName = createdBy is Map ? (createdBy['full_name'] as String? ?? '') : '';
    final rawDate = (item['published_at'] as String?) ?? (item['created_at'] as String? ?? '');
    final publishDate = _formatDate(rawDate);
    final newsId = item['_id'] as String? ?? item['id'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFF1F5F8),
                child: const Icon(Icons.image_outlined, size: 48, color: AppColors.textHint),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (publisherName.isNotEmpty) ...[
              const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                publisherName,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (publishDate.isNotEmpty) ...[
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                publishDate,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
        if (isOwner && newsId.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _deleteNews(context, ref, newsId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 6),
                        Text(
                          'حذف',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await context.push('/add-announcement', extra: item);
                    if (context.mounted) context.pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'تعديل',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          body.isNotEmpty ? body : 'لا يوجد محتوى لهذا الإعلان بعد.',
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteNews(BuildContext context, WidgetRef ref, String newsId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'هل تريد حذف هذا الإعلان نهائياً؟',
            style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: Color(0xFFEF4444)),
              ),
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
            backgroundColor: Color(0xFF10B981),
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
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildObituaryFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F8))),
      ),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('قريباً', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_outlined, size: 20, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'نشر ومشاركة الإعلان',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return raw ?? '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
