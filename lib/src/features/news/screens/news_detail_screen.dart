import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';

class NewsDetailScreen extends ConsumerWidget {
  final Map<String, dynamic>? newsItem;

  const NewsDetailScreen({super.key, this.newsItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = newsItem ?? _getDummyItem();

    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final type = item['type'] as String? ?? '';
    final subType = item['sub_type'] as String? ?? '';
    final date = item['created_at'] as String? ?? '';
    final body = item['body'] as String? ?? item['content'] as String? ?? '';

    String label;
    Color chipColor;
    if (subType == 'death') {
      label = 'نعي';
      chipColor = const Color(0xFF94A3B8);
    } else if (subType == 'wedding') {
      label = 'عرس';
      chipColor = const Color(0xFFF59E0B);
    } else if (subType == 'congratulation') {
      label = 'تهنئة';
      chipColor = const Color(0xFF0D9488);
    } else {
      switch (type) {
        case 'admin_alert':
          label = 'إعلان';
          chipColor = const Color(0xFF0D9488);
          break;
        case 'important':
          label = 'مهم';
          chipColor = const Color(0xFFEF4444);
          break;
        case 'social_occasion':
          label = 'مناسبة';
          chipColor = const Color(0xFFF59E0B);
          break;
        default:
          label = 'خبر';
          chipColor = const Color(0xFF3B82F6);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        title: const Text(
          'تفاصيل الخبر',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'قريباً',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                  ),
                  backgroundColor: Color(0xFF64748B),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 13,
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
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: body.isNotEmpty
                  ? Text(
                      body,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                        height: 1.8,
                      ),
                    )
                  : Text(
                      'هذا النص هو مثال للنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العرب، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف التى يولدها التطبيق.\n\nإذا كنت تحتاج إلى عدد أكبر من الفقرات يتيح لك مولد النص العربى زيادة الأعداد كما شاءت لك النصوص عربي additionally.\n\nهذا النص هو مثال على نص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف التى يولدها التطبيق.',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                        height: 1.8,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getDummyItem() {
    return {
      'title': 'عنوان الخبر',
      'subtitle': 'عنوان فرعي للخبر',
      'type': 'news',
      'created_at': '2025-01-01',
      'body': '',
    };
  }
}
